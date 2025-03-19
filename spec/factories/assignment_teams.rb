FactoryBot.define do
  factory :assignment_team do
    sequence(:name) { |n| "Team #{n}" }
    association :assignment, factory: :assignment, strategy: :build
  end
end