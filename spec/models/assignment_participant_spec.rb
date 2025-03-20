require 'rails_helper'

RSpec.describe AssignmentParticipant, type: :model do
  it { should belong_to(:assignment) }
  it { should belong_to(:user) }
  it { should validate_presence_of(:handle) }

  describe '#set_handle' do
    it 'sets handle based on user data' do
      participant = create(:assignment_participant, handle: '')
      participant.set_handle
      expect(participant.handle).not_to be_empty
    end
  end
end
