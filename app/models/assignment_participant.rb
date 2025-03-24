# frozen_string_literal: true

class AssignmentParticipant < Participant
  belongs_to  :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'
  belongs_to :user
  validates :handle, presence: true


  def set_handle
    self.handle = if user.handle.nil? || (user.handle == '')
                    user.name
                  elsif Participant.exists?(assignment_id: assignment.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    self.save
  end

  def teams
    AssignmentTeam.joins(:participants).where(participants: { user_id: id })
  end

end