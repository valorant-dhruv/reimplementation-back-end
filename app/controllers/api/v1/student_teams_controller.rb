class Api::V1::StudentTeamsController < ApplicationController
  include StudentTeamsHelper
    
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ActionController::ParameterMissing, with: :parameter_missing
    before_action :set_student, only: %i[create index show]
    before_action :set_team, only: %i[show]

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
  
    def update
      
    end
  
   
    def destroy
      
    end
  
    def remove_participant
  
    end
  
    def add_participant
      
    end
  
  end