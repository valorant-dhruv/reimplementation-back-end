class Api::V1::StudentTeamsController < ApplicationController
    before_action :set_student, only: %i[create index show]
    before_action :set_team, only: %i[show]

    # GET /student_teams
    def index
        @teams = @student.teams
        render json: { teams: @teams }, status: :ok
    end
  
    # GET /student_teams/:id
    def show
        render json: { team: @team, members: @team.members }, status: :ok
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Team not found' }, status: :not_found
    end
  
    # POST /student_teams
    def create
        if team_name_taken?
            render json: { error: 'Team name is already in use' }, status: :unprocessable_entity
            return
        end
        
        @team = AssignmentTeam.new(team_params.merge(parent_id: @student.parent_id))
        if @team.save
            @team.add_member(@student.user, @team.parent_id)
            render json: { message: 'Team created successfully', team: @team }, status: :created
        else
            render json: { error: 'Failed to create team', details: @team.errors.full_messages }, status: :unprocessable_entity
        end
    end
  
    def update
      
    end
  
   
    def destroy
      
    end
  
    def remove_participant
  
    end
  
    def add_participant
      
    end



    private

    def set_student
        @student = AssignmentParticipant.find(params[:student_id])
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Student not found' }, status: :not_found
    end

    def set_team
        @team = AssignmentTeam.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        render json: { error: 'Team not found' }, status: :not_found
    end

    def team_params
        params.require(:team).permit(:name)
    end

    def team_name_taken?
        AssignmentTeam.exists?(name: params[:team][:name], parent_id: @student.parent_id)
    end
    
  
  end