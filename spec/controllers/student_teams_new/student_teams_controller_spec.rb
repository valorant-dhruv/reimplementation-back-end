require 'rails_helper'

RSpec.describe Api::V1::StudentTeamsController, type: :controller do
  describe 'GET #index' do
    # Create a mock student and teams
    let(:mock_student) { instance_double(AssignmentParticipant) }
    let(:mock_teams) { [
      double('Team', id: 1, name: 'Team 1'),
      double('Team', id: 2, name: 'Team 2')
    ] }

    context 'when student exists' do
      before do
        # Allow find with any argument and return mock_student
        allow(AssignmentParticipant).to receive(:find).with(any_args).and_return(mock_student)
        allow(mock_student).to receive(:teams).and_return(mock_teams)
      end

      it 'returns success with teams' do
        get :index, params: { id: "1" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['teams'].length).to eq(2)
      end
    end
  end

  describe 'GET #show' do
    let(:mock_student) { instance_double(AssignmentParticipant) }
    let(:mock_team) { instance_double(AssignmentTeam) }
    let(:mock_members) { [
      double('Member', id: 1, handle: 'student1'),
      double('Member', id: 2, handle: 'student2')
    ] }

    context 'when team exists' do
      before do
        # Mock both student and team lookups
        allow(AssignmentParticipant).to receive(:find).with("7").and_return(mock_student)
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:members).and_return(mock_members)
      end

      it 'returns success with team details' do
        get :show, params: { id: "7" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['team']).to be_present
        expect(json_response['members']).to be_present
      end
    end

    context 'when team does not exist' do
      before do
        # Mock student lookup but make team lookup fail
        allow(AssignmentParticipant).to receive(:find).with("999").and_return(mock_student)
        allow(AssignmentTeam).to receive(:find).with("999")
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it 'returns not found error' do
        get :show, params: { id: "999" }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['error']).to eq('Team not found')
      end
    end

    context 'when there is an error fetching team details' do
      before do
        # Mock both lookups but make members call fail
        allow(AssignmentParticipant).to receive(:find).with("7").and_return(mock_student)
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:members).and_raise(StandardError.new("Database error"))
      end

      it 'returns error details' do
        get :show, params: { id: "7" }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['error']).to eq('Error fetching team details')
        expect(json_response['details']).to eq('Database error')
      end
    end
  end

  describe 'POST #create' do
    let(:mock_student) { instance_double(AssignmentParticipant) }
    let(:mock_team) { instance_double(AssignmentTeam) }
    let(:team_params) { { name: "New Team", assignment_id: "1" } }

    context 'when team creation is successful' do
      before do
        allow(AssignmentParticipant).to receive(:find).with("7").and_return(mock_student)
        allow(mock_student).to receive(:assignment_id).and_return(1)
        allow_any_instance_of(StudentTeamsHelper).to receive(:team_name_taken?).and_return(false)
        allow(AssignmentTeam).to receive(:new).with(
          hash_including(name: "New Team", assignment_id: 1)
        ).and_return(mock_team)
        allow(mock_team).to receive(:save).and_return(true)
        allow(mock_team).to receive(:assignment_id).and_return(1)
        allow(mock_team).to receive(:add_member).with(mock_student, 1).and_return([true, "Member added"])
      end

      it 'creates a new team successfully' do
        post :create, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Team created successfully')
        expect(json_response['team']).to be_present
      end
    end

    context 'when team name is already taken' do
      before do
        allow(AssignmentParticipant).to receive(:find).with("7").and_return(mock_student)
        allow(mock_student).to receive(:assignment_id).and_return(1)
        allow_any_instance_of(StudentTeamsHelper).to receive(:team_name_taken?).and_return(true)
      end

      it 'returns an error' do
        post :create, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Team name is already in use')
      end
    end

    context 'when member addition fails' do
      before do
        allow(AssignmentParticipant).to receive(:find).with("7").and_return(mock_student)
        allow(mock_student).to receive(:assignment_id).and_return(1)
        allow_any_instance_of(StudentTeamsHelper).to receive(:team_name_taken?).and_return(false)
        allow(AssignmentTeam).to receive(:new).with(
          hash_including(name: "New Team", assignment_id: 1)
        ).and_return(mock_team)
        allow(mock_team).to receive(:save).and_return(true)
        allow(mock_team).to receive(:assignment_id).and_return(1)
        allow(mock_team).to receive(:add_member).with(mock_student, 1).and_return([false, "Team is full"])
        allow(mock_team).to receive(:destroy).and_return(true)
      end

      it 'returns an error and rolls back team creation' do
        post :create, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['error']).to eq('Team is full')
      end
    end

    context 'when team save fails' do
      before do
        allow(AssignmentParticipant).to receive(:find).with("7").and_return(mock_student)
        allow(mock_student).to receive(:assignment_id).and_return(1)
        allow_any_instance_of(StudentTeamsHelper).to receive(:team_name_taken?).and_return(false)
        allow(AssignmentTeam).to receive(:new).with(
          hash_including(name: "New Team", assignment_id: 1)
        ).and_return(mock_team)
        allow(mock_team).to receive(:save).and_return(false)
        allow(mock_team).to receive(:errors).and_return(
          double(full_messages: ['Name cannot be blank'])
        )
      end

      it 'returns validation errors' do
        post :create, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['error']).to eq('Failed to create team')
        expect(json_response['details']).to include('Name cannot be blank')
      end
    end
  end

  describe 'PUT #update' do
    let(:mock_team) { double('AssignmentTeam') }
    let(:team_params) { { name: "Updated Team Name" } }

    context 'when team exists and update is successful' do
      before do
        # Mock team lookup
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        # Mock current team name
        allow(mock_team).to receive(:name).and_return("Old Team Name")
        # Mock exists? check for name uniqueness
        allow(AssignmentTeam).to receive(:exists?).with(name: "Updated Team Name").and_return(false)
        # Mock update
        allow(mock_team).to receive(:update).with(name: "Updated Team Name").and_return(true)
        # Mock inspect for debugging
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'updates the team name successfully' do
        put :update, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Team name updated successfully')
        expect(json_response['team']).to be_present
      end
    end

    context 'when team name is already taken' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:name).and_return("Old Team Name")
        allow(AssignmentTeam).to receive(:exists?).with(name: "Updated Team Name").and_return(true)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'returns an error' do
        put :update, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Team name is already in use')
      end
    end

    context 'when updating to the same name' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:name).and_return("Updated Team Name")
        allow(AssignmentTeam).to receive(:exists?).with(name: "Updated Team Name").and_return(true)
        allow(mock_team).to receive(:update).with(name: "Updated Team Name").and_return(true)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'allows the update' do
        put :update, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Team name updated successfully')
      end
    end

    context 'when team is not found' do
      before do
        allow(AssignmentTeam).to receive(:find).with("999")
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it 'returns not found error' do
        put :update, params: { id: "999", team: team_params }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Team not found')
      end
    end

    context 'when update fails' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:name).and_return("Old Team Name")
        allow(AssignmentTeam).to receive(:exists?).with(name: "Updated Team Name").and_return(false)
        allow(mock_team).to receive(:update).with(name: "Updated Team Name").and_return(false)
        allow(mock_team).to receive(:errors).and_return(
          double(full_messages: ['Name is invalid'])
        )
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'returns validation errors' do
        put :update, params: { id: "7", team: team_params }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['error']).to eq('Failed to update team name')
        expect(json_response['details']).to include('Name is invalid')
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:mock_team) { double('AssignmentTeam') }

    context 'when team exists and is successfully deleted' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:destroy).and_return(true)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'deletes the team successfully' do
        delete :destroy, params: { id: "7" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Team successfully deleted')
      end
    end

    context 'when team deletion fails' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:destroy).and_return(false)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'returns an error message' do
        delete :destroy, params: { id: "7" }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Failed to remove delete team')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:destroy).and_raise(StandardError.new("Database connection error"))
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'handles the error gracefully' do
        delete :destroy, params: { id: "7" }

        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('An unexpected error occurred: Database connection error')
      end
    end
  end

  describe 'DELETE #remove_participant' do
    let(:mock_team) { double('AssignmentTeam') }

    context 'when participant is successfully removed' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
        allow_any_instance_of(StudentTeamsHelper).to receive(:remove_team_participant)
          .with("1")
          .and_return({
            status: 'success',
            message: 'Participant successfully removed from team'
          })
      end

      it 'removes the participant successfully' do
        delete :remove_participant, params: { id: "7", participant_id: "1" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Participant successfully removed from team')
      end
    end

    context 'when participant removal fails' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
        allow_any_instance_of(StudentTeamsHelper).to receive(:remove_team_participant)
          .with("1")
          .and_return({
            status: 'error',
            error: 'Cannot remove the last team member'
          })
      end

      it 'returns an error message' do
        delete :remove_participant, params: { id: "7", participant_id: "1" }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['error']).to eq('Cannot remove the last team member')
      end
    end

    context 'when team is not found' do
      before do
        allow(AssignmentTeam).to receive(:find).with("999")
          .and_raise(ActiveRecord::RecordNotFound)
      end

      it 'returns not found error' do
        delete :remove_participant, params: { id: "999", participant_id: "1" }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Team not found')
      end
    end
  end

  describe 'POST #add_participant' do
    let(:mock_team) { double('AssignmentTeam') }

    context 'when participant is successfully added' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(AssignmentTeam).to receive(:find_by).with(id: "7").and_return(mock_team)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
        allow_any_instance_of(StudentTeamsHelper).to receive(:add_team_participant)
          .with("1")
          .and_return({
            status: 'success',
            message: 'Participant successfully added to team'
          })
      end

      it 'adds the participant successfully' do
        post :add_participant, params: { id: "7", participant_id: "1" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Participant successfully added to team')
      end
    end

    context 'when participant_id is missing' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
      end

      it 'returns an error for missing participant_id' do
        post :add_participant, params: { id: "7" }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Participant ID is required')
      end
    end

    context 'when team is not found' do
      before do
        allow(AssignmentTeam).to receive(:find).with("999").and_return(nil)
        allow(AssignmentTeam).to receive(:find_by).with(id: "999").and_return(nil)
      end

      it 'returns not found error' do
        post :add_participant, params: { id: "999", participant_id: "1" }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Team not found')
      end
    end

    context 'when participant addition fails' do
      before do
        allow(AssignmentTeam).to receive(:find).with("7").and_return(mock_team)
        allow(AssignmentTeam).to receive(:find_by).with(id: "7").and_return(mock_team)
        allow(mock_team).to receive(:inspect).and_return("Mock Team")
        allow_any_instance_of(StudentTeamsHelper).to receive(:add_team_participant)
          .with("1")
          .and_return({
            status: 'error',
            error: 'Team is full'
          })
      end

      it 'returns an error message' do
        post :add_participant, params: { id: "7", participant_id: "1" }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('error')
        expect(json_response['error']).to eq('Team is full')
      end
    end
  end

end