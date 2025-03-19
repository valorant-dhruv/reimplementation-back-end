require 'rails_helper'

RSpec.describe StudentTeamsHelper, type: :helper do
  let(:assignment) { create(:assignment) }
  let(:student) { create(:assignment_participant, assignment: assignment) }
  let(:team) { create(:assignment_team, parent_id: assignment.id) }

  before do
    assign(:student, student)
    assign(:team, team)
  end

  describe '#fetch_student_teams' do
    it 'returns success status with teams' do
      result = helper.fetch_student_teams
      expect(result[:status]).to eq('success')
      expect(result).to have_key(:teams)
    end

    it 'handles errors gracefully' do
      allow(student).to receive(:teams).and_raise(StandardError.new('Test error'))
      result = helper.fetch_student_teams
      expect(result[:status]).to eq('error')
      expect(result[:error]).to eq('Error fetching teams')
    end
  end

  describe '#create_student_team' do
    let(:valid_params) { { team: { name: 'New Team' } } }
    
    before do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(valid_params))
    end

    it 'creates a team successfully' do
      result = helper.create_student_team
      expect(result[:status]).to eq('success')
      expect(result[:message]).to eq('Team created successfully')
    end

    it 'prevents duplicate team names' do
      create(:assignment_team, name: 'New Team', parent_id: assignment.id)
      result = helper.create_student_team
      expect(result[:status]).to eq('error')
      expect(result[:error]).to eq('Team name is already in use')
    end
  end
end