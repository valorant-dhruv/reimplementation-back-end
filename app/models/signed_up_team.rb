class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team

  def self.create_signed_up_team(sign_up_topic_id, team_id)
    create(sign_up_topic_id: sign_up_topic_id, team_id: team_id)
  end
end