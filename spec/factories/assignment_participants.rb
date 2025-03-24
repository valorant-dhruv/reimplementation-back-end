FactoryBot.define do
  factory :assignment_participant do
    association :user
    association :assignment
    sequence(:handle) { |n| "participant#{n}" }
  end
end