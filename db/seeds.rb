# frozen_string_literal: true

# Admin Users
AdminUser.create!(email: 'admin@example.com', password: 'testing', password_confirmation: 'testing')

# Users
User.create!(name: "test user", email: 'user@example.com', password: 'testing', password_confirmation: 'testing')
