FactoryBot.define do
  factory :admin_user do
    email { 'admin@example.com' }
    password { 'testing' }
  end
end
