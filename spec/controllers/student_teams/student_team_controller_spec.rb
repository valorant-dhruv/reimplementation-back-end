require 'rails_helper'

RSpec.describe Api::V1::StudentTeamsController, type: :request do
  let(:assignment) { create(:assignment) }
  let(:student) { create(:assignment_participant, assignment: assignment) }
  let(:team) { create(:assignment_team, parent_id: assignment.id) }

  describe 'GET /api/v1/student_teams' do
    before { get api_v1_student_teams_path, params: { student_id: student.id } }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns the teams' do
      expect(json_response['status']).to eq('success')
      expect(json_response).to have_key('teams')
    end
  end

  describe 'POST /api/v1/student_teams' do
    let(:valid_attributes) { { team: { name: 'New Team' }, student_id: student.id } }

    context 'when request is valid' do
      before { post api_v1_student_teams_path, params: valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'creates a team' do
        expect(json_response['message']).to eq('Team created successfully')
      end
    end

    context 'when request is invalid' do
      before { post api_v1_student_teams_path, params: { team: { name: '' }, student_id: student.id } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns validation failure message' do
        expect(json_response['error']).to include('Failed to create team')
      end
    end
  end

  describe 'POST /api/v1/student_teams/:id/add_participant' do
    let(:new_participant) { create(:assignment_participant, assignment: assignment) }

    it 'adds a participant successfully' do
      post add_participant_api_v1_student_team_path(team), 
           params: { participant_id: new_participant.id }
      
      expect(response).to have_http_status(200)
      expect(json_response['message']).to eq('Member added successfully')
    end
  end
end