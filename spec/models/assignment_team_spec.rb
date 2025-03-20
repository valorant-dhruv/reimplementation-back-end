require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  it { should belong_to(:assignment) }
  it { should have_many(:teams_users).dependent(:destroy) }
  it { should validate_presence_of(:name) }

  describe '#add_member' do
    let(:participant) { create(:assignment_participant) }
    it 'adds a member successfully' do
      team = create(:assignment_team)
      success, message = team.add_member(participant, team.assignment.id)
      expect(success).to be_truthy
    end
  end
end
