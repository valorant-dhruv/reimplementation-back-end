require 'swagger_helper'

RSpec.describe 'api/v1/student_teams', type: :request do
  path '/api/v1/student_teams' do
    get 'Lists all teams for a student' do
      tags 'Student Teams'
      produces 'application/json'
      parameter name: :id, in: :query, type: :integer, required: true, description: 'Student ID'

      response '200', 'teams found' do
        schema type: :object,
          properties: {
            status: { type: :string },
            teams: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  created_at: { type: :string, format: 'date-time' },
                  updated_at: { type: :string, format: 'date-time' },
                  assignment_id: { type: :integer }
                }
              }
            }
          }
        let(:id) { create(:assignment_participant).id }
        run_test!
      end

      response '404', 'student not found' do
        schema type: :object,
          properties: {
            status: { type: :string },
            error: { type: :string }
          }
        let(:id) { 'invalid' }
        run_test!
      end
    end

    post 'Creates a team' do
      tags 'Student Teams'
      produces 'application/json'
      parameter name: :id, in: :query, type: :integer, required: true, description: 'Student ID'

      response '201', 'team created' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string },
            team: {
              type: :object,
              properties: {
                id: { type: :integer },
                created_at: { type: :string, format: 'date-time' },
                updated_at: { type: :string, format: 'date-time' },
                assignment_id: { type: :integer }
              }
            }
          }
        let(:id) { create(:assignment_participant).id }
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            status: { type: :string },
            error: { type: :string }
          }
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/student_teams/{id}' do
    parameter name: 'id', in: :path, type: :integer, required: true

    get 'Retrieves a team' do
      tags 'Student Teams'
      produces 'application/json'

      response '200', 'team found' do
        schema type: :object,
          properties: {
            status: { type: :string },
            team: {
              type: :object,
              properties: {
                id: { type: :integer },
                created_at: { type: :string, format: 'date-time' },
                updated_at: { type: :string, format: 'date-time' },
                assignment_id: { type: :integer }
              }
            },
            members: {
              type: :array,
              items: { type: :object }
            }
          }
        let(:id) { create(:assignment_team).id }
        run_test!
      end

      response '404', 'team not found' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        let(:id) { 'invalid' }
        run_test!
      end
    end

    delete 'Deletes a team' do
      tags 'Student Teams'
      produces 'application/json'

      response '200', 'team deleted' do
        schema type: :object,
          properties: {
            message: { type: :string }
          }
        let(:id) { create(:assignment_team).id }
        run_test!
      end

      response '404', 'team not found' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end

  path '/api/v1/student_teams/{id}/add_participant' do
    post 'Adds a participant to the team' do
      tags 'Student Teams'
      produces 'application/json'
      parameter name: 'id', in: :path, type: :integer, required: true
      parameter name: :participant_id, in: :query, type: :integer, required: true

      response '200', 'participant added' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          }
        let(:id) { create(:assignment_team).id }
        let(:participant_id) { create(:assignment_participant).id }
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            status: { type: :string },
            error: { type: :string }
          }
        let(:id) { 'invalid' }
        let(:participant_id) { 'invalid' }
        run_test!
      end
    end
  end
end