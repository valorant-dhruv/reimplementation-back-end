class Api::V1::StudentTeamsController < ApplicationController
  include StudentTeamsHelper
    
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActionController::ParameterMissing, with: :parameter_missing
    before_action :set_student, only: %i[create index show]
    before_action :set_team, only: %i[show update add_participant remove_participant destroy]

    # GET /api/v1/student_teams
    # Returns all teams associated with a student
    # @return [JSON] List of teams
    # @response_status 200 Success
    def index
        result = fetch_student_teams
        render json: result, status: :ok 
    end
  
    # GET /api/v1/student_teams/:id
    # Returns specific team and its members
    # @return [JSON] Team details and member list
    # @response_status 200 Success
    # @response_status 404 Not Found
    def show
        result = fetch_team_details
        if result[:error]
          render json: result, status: :not_found  # 404
        else
          render json: result, status: :ok  # 200
        end
    end
  
    # POST /api/v1/student_teams
    # Creates a new team with the current student as first member
    # @return [JSON] Created team details or error message
    # @response_status 201 Created
    # @response_status 422 Unprocessable Entity
    def create
        result = create_student_team
        if result[:error]
          render json: result, status: :unprocessable_entity  # 422
        else
          render json: result, status: :created  # 201
        end
    end

    # PUT /api/v1/student_teams/:id
    # Updates the team names
    
  
    def update
      # Check if the team exists
      return render json: { error: 'Team not found' }, status: :not_found unless @team
    
      # Check if the new team name is already taken by another team
      if AssignmentTeam.exists?(name: params[:team][:name]) &&  #, parent_id: @team.parent_id
         params[:team][:name] != @team.name
        return render json: { error: 'Team name is already in use' }, status: :unprocessable_entity
      end
    
      # Update the team name
      if @team.update(name: params[:team][:name])
        render json: { 
          status: 'success', 
          message: 'Team name updated successfully', 
          team: @team 
        }, status: :ok
      else
        render json: { 
          status: 'error', 
          error: 'Failed to update team name', 
          details: @team.errors.full_messages 
        }, status: :unprocessable_entity
      end

    end
  
    #DELETE /api/v1/student_teams/:id
    def destroy
      begin
        @team.participants.destroy_all
        # Remove all team-user associations
        @team.teams_users.destroy_all
    
        if @team.destroy
          render json: { message: 'Team successfully deleted' }, status: :ok #200
        else
          render json: { error: 'Failed to remove delete team' }, status: :unprocessable_entity #422
        end
      rescue StandardError => e
        render json: { error: "An unexpected error occurred: #{e.message}" }, status: :internal_server_error #500
      end
      
    end
  
    def remove_participant
      # Ensure the team is set (from the `before_action` callback)
      return render json: { error: 'Team not found' }, status: :not_found unless @team
    
      # Call the helper method to remove the participant
      result = remove_team_participant(params[:participant_id])
    
      # Render the result returned by the helper method
      if result[:status] == 'success'
        render json: result, status: :ok
      else
        render json: result, status: :unprocessable_entity
      end

    end
    
  
    def add_participant

      # Ensure the team exists
      return render json: { error: 'Team not found' }, status: :not_found unless @team

      # Ensure participant_id is provided
      unless params[:participant_id]
        return render json: { error: 'Participant ID is required' }, status: :unprocessable_entity
      end
      team_id = params[:id]
      participant_id = params[:participant_id] || params[:student_team][:participant_id]

      # Debugging: Print the values

      @team = AssignmentTeam.find_by(id: team_id)
      return render json: { error: 'Team not found' }, status: :not_found unless @team

      # Ensure participant_id is provided
      unless participant_id
        return render json: { error: 'Participant ID is required' }, status: :unprocessable_entity
      end


      # Call the helper method to add the participant
      result = add_team_participant(params[:participant_id])

      # Render the result returned by the helper method
      if result[:status] == 'success'
        render json: result, status: :ok
      else
        render json: result, status: :unprocessable_entity
      end
      
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
