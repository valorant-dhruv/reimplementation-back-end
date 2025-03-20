class Api::V1::StudentTeamsController < ApplicationController

  def index

  end


  def show
    
  end

  def create

  end

  def edit
  end

  def update

    existing_teams = AssignmentTeam.find_by(name: params[:team][:name], parent_id: team.parent_id)

    if existing_teams.blank? #if team with the new name doesnt already exist, update the name
      if @team.update_attribute(name: params[:team][:name])
        handle_successful_update
        redirect_to view_student_teams_path(student_id: params[:student_id])
      end    
    #checking if the new team name already exists and is same as old team name
    elsif existing_teams.one? && existing_teams.first.name == @team.name  
      flash[:warning] = 'The team name to be updated is same as old one.'
      redirect_to view_student_teams_path(student_id: params[:student_id])
    else #Cannot take another existing team's name
      flash[:warning] = 'This team name is already being used.'
      redirect_to view_student_teams_path(student_id: params[:student_id])
    end
    
  end

 
  def destroy
    begin
      if @team.destroy
        render json: { message: 'Team successfully deleted' }, status: :ok
      else
        render json: { error: 'Failed to remove delete team' }, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error
    end
    
  end

  def remove_participant
    # Find and remove the participant's team membership
    if (team_user = TeamsUser.find_by(team_id: params[:team_id], user_id: @student.user_id))
      remove_team_user(team_user)
    end
  
    # remove the team if it is empty and has no peer reviews
    team = AssignmentTeam.find_by(id: params[:team_id])
    if team && team.teams_users.empty?
      team.destroy!
    end
  
    # Remove any pending invitations from the student for this assignment
    Invitation.where(from_id: @student.user_id, assignment_id: @student.parent_id).delete_all
  
    @student.save
    redirect_to view_student_teams_path(student_id: @student.id)
  end
  

  def add_participant
    
  end

  def remove_team_user(team_user)

    return false unless team_user&.destroy
    flash[:success] = "User was successfully removed from the team!"

  end
  

  def handle_successful_update
    
    flash[:success] = 'Team name updated successfully!'
    redirect_to view_student_teams_path(student_id: params[:student_id])
    
  end



end