class AssignmentTeam < Team
  belongs_to :assignment, foreign_key: 'parent_id'
  has_many :teams_users, foreign_key: 'team_id', dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants, class_name: 'AssignmentParticipant', foreign_key: 'team_id'

  validates :name, presence: true, uniqueness: { scope: :parent_id, message: 'should be unique within an assignment' }

  # Add member to the team using participant
  # @param participant [AssignmentParticipant] the participant to be added
  # @param assignment_id [Integer] the assignment's id
  # @return [Boolean, String] success status and message
  def add_member(participant, assignment_id)
    return [false, 'Team is already full'] if full?
    return [false, 'User is already in team'] if teams_users.exists?(user_id: participant.user_id)

    ActiveRecord::Base.transaction do
      teams_users.create!(user_id: participant.user_id)
      participants << participant
    end
    [true, 'Member added successfully']
  rescue StandardError => e
    [false, "Failed to add member: #{e.message}"]
  end

  # Remove member from the team
  # @param participant [AssignmentParticipant] the participant to be removed
  # @return [Boolean, String] success status and message
  def remove_member(participant)
    team_user = teams_users.find_by(user_id: participant.user_id)
    return [false, 'User is not in team'] unless team_user

    ActiveRecord::Base.transaction do
      team_user.destroy
      participants.delete(participant)
    end
    [true, 'Member removed successfully']
  rescue StandardError => e
    [false, "Failed to remove member: #{e.message}"]
  end

  # Get all team members
  # @return [Array<Hash>] array of member details
  def members
    participants.includes(:user).map do |participant|
      {
        id: participant.user_id,
        name: participant.user.name,
        handle: participant.handle
      }
    end
  end

  # Check if team is at maximum capacity
  # @return [Boolean] true if team is full
  def full?
    max_team_size = assignment.try(:max_team_size) || 3
    participants.count >= max_team_size
  end

  # Check if participant is a member of the team
  # @param participant_id [Integer] the participant's id
  # @return [Boolean] true if participant is a member
  def member?(participant_id)
    participants.exists?(participant_id)
  end

  # Get team size
  # @return [Integer] number of team members
  def size
    participants.count
  end

  private

  # Validate team size before saving
  def validate_team_size
    max_team_size = assignment.try(:max_team_size) || 3
    if participants.count > max_team_size
      errors.add(:base, "Team size cannot exceed #{max_team_size} members")
    end
  end
end