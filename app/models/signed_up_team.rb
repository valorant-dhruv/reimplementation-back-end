class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team

  def self.create_signed_up_team(sign_up_topic_id, team_id)
    create(sign_up_topic_id: sign_up_topic_id, team_id: team_id)
  end


  def self.get_team_participants(user_id)
    teams_user = TeamsUser.find_by(user_id: user_id) # Adjust if your DB structure is different
    return teams_user.team_id if teams_user

    nil # Return nil if no team found for the user
  end
  
end