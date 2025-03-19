FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:full_name) { |n| "Full Name #{n}" } 
    password { 'password123' }
    
    # Add instructor trait
    trait :instructor do
      association :role, factory: [:role, :instructor]
    end
  end
end