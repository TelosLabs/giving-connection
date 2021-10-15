# frozen_string_literal: true

# Admin Users
AdminUser.create!(email: 'admin@example.com', password: 'testing', password_confirmation: 'testing')

# Users
User.create!(email: 'user@example.com', password: 'testing', password_confirmation: 'testing')

# Orgs
3.times do
  org = Organization.new(
    name: Faker::Company.name,
    ein_number: rand(0..1000),
    irs_ntee_code: %w[A00 A90 A26 A91 A02 Q21].sample,
    website: 'org@email.com',
    scope_of_work: %w[International National Regional].sample,
    mission_statement_en: Faker::Company.catch_phrase,
    vision_statement_en: Faker::Company.catch_phrase,
    tagline_en: Faker::Company.catch_phrase,
    description_en: Faker::Company.catch_phrase
  )
  org.creator = AdminUser.last

  if org.save!
    puts "#{org.id} sucessfully created"
    SocialMedia.create!(organization: org)
  end

  puts "#{org.id} sucessfully created" if org.save!
end

# Add all categories and subcategories
# Organization::CATEGORIES_AND_SUBCATEGORIES.keys.each do |category|
#   new_category = Category.new(name: category)

#   if new_category.save!
#     puts "#{new_category.name} created!"
#   end

#   Organization::CATEGORIES_AND_SUBCATEGORIES[category].each do |subcategory|
#     new_subcategory = Subcategory.new(name: subcategory, category: new_category)

#     if new_subcategory.save!
#       puts "#{new_subcategory.name} created!"
#     end
#   end
# end
