require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  let(:assignment) { create(:assignment) }
  let(:user) { create(:user) }
  let(:participant) { create(:assignment_participant, user: user, assignment: assignment) }
  let(:team) { create(:assignment_team, parent_id: assignment.id) }

  describe 'associations' do
    it { should belong_to(:assignment).with_foreign_key('parent_id') }
    it { should have_many(:teams_users).dependent(:destroy) }
    it { should have_many(:users).through(:teams_users) }
    it { should have_many(:participants) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:parent_id) }
  end

  describe '#add_member' do
    context 'when team is not full' do
      it 'adds a new member successfully' do
        success, message = team.add_member(participant, assignment.id)
        expect(success).to be true
        expect(message).to eq('Member added successfully')
        expect(team.participants).to include(participant)
      end

      it 'prevents adding the same member twice' do
        team.add_member(participant, assignment.id)
        success, message = team.add_member(participant, assignment.id)
        expect(success).to be false
        expect(message).to include('User is already in team')
      end
    end

    context 'when team is full' do
      before do
        allow(team).to receive(:full?).and_return(true)
      end

      it 'prevents adding new members' do
        success, message = team.add_member(participant, assignment.id)
        expect(success).to be false
        expect(message).to eq('Team is already full')
      end
    end
  end

  describe '#remove_member' do
    before { team.add_member(participant, assignment.id) }

    it 'removes a member successfully' do
      success, message = team.remove_member(participant)
      expect(success).to be true
      expect(message).to eq('Member removed successfully')
      expect(team.participants).not_to include(participant)
    end

    it 'handles removing non-existent member' do
      other_participant = create(:assignment_participant)
      success, message = team.remove_member(other_participant)
      expect(success).to be false
      expect(message).to include('User is not in team')
    end
  end

  describe '#full?' do
    it 'returns true when team has reached max size' do
      allow(team).to receive(:size).and_return(3)
      expect(team.full?).to be true
    end

    it 'returns false when team has not reached max size' do
      allow(team).to receive(:size).and_return(2)
      expect(team.full?).to be false
    end
  end
end