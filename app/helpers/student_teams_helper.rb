module StudentTeamsHelper
  extend ActiveSupport::Concern

  # Fetch all teams for a student
  # @return [Hash] teams list or error details
  def fetch_student_teams
    {
      status: 'success',
      teams: @student.teams
    }
  rescue StandardError => e
    {
      status: 'error',
      error: 'Error fetching teams',
      details: e.message
    }
  end

  # Fetch specific team with its members
  # @return [Hash] team details or error message
  def fetch_team_details
    return { error: 'Team not found' } unless @team

    {
      status: 'success',
      team: @team,
      members: @team.members  # This now returns participant details including handles
    }
  rescue StandardError => e
    {
      status: 'error',
      error: 'Error fetching team details',
      details: e.message
    }
  end

  # Create new team and add student as first member
  # @return [Hash] created team details or error message
  def create_student_team
    return { error: 'Team name is already in use' } if team_name_taken?

    team = AssignmentTeam.new(team_params.merge(parent_id: @student.parent_id))
    
    if team.save
      success, message = team.add_member(@student, team.parent_id)  # Updated to pass participant
      if success
        {
          status: 'success',
          message: 'Team created successfully',
          team: team
        }
      else
        team.destroy  # Rollback if member addition fails
        {
          status: 'error',
          error: message
        }
      end
    else
      {
        status: 'error',
        error: 'Failed to create team',
        details: team.errors.full_messages
      }
    end
  rescue StandardError => e
    {
      status: 'error',
      error: 'Error creating team',
      details: e.message
    }
  end

  # Add participant to team
  # @return [Hash] success or error message
  def add_team_participant(participant_id)
    participant = AssignmentParticipant.find(participant_id)

    # Check if the participant is already in a team for this assignment
    if participant.team.present?
      return { 
        status: 'error', 
        error: 'Participant is already in a team for this assignment' 
      }
    end

    success, message = @team.add_member(participant, @team.parent_id)
    
    if  @team.add_member(participant)
      {
        status: 'success',
        message: 'Participant added to the team successfully'
      }
    else
      {
        status: 'error',
        error: 'Failed to add participant to the team'
      }
    end
  rescue ActiveRecord::RecordNotFound
    {
      status: 'error',
      error: 'Participant not found'
    }
  rescue StandardError => e
    {
      status: 'error',
      error: "Failed to add participant: #{e.message}"
    }
  end

  # Remove participant from team
  # @return [Hash] success or error message
  def remove_team_participant(participant_id)
    participant = AssignmentParticipant.find(participant_id)
    success, message = @team.remove_member(participant)
    
    if success
      {
        status: 'success',
        message: message
      }
    else
      {
        status: 'error',
        error: message
      }
    end
  rescue ActiveRecord::RecordNotFound
    {
      status: 'error',
      error: 'Participant not found'
    }
  rescue StandardError => e
    {
      status: 'error',
      error: "Failed to remove participant: #{e.message}"
    }
  end

  private

  def set_student
    @student = AssignmentParticipant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      status: 'error',
      error: 'Student not found' 
    }, status: :not_found
  end

  def set_team
    puts "Team ID: #{params[:id]}"
    @team = AssignmentTeam.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { 
      status: 'error',
      error: 'Team not found' 
    }, status: :not_found
  end

  def team_params
    params.require(:team).permit(:name)
  end

  def team_name_taken?
    AssignmentTeam.exists?(name: params[:team][:name], parent_id: @student.parent_id)
  end
end