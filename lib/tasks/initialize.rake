load './lib/tasks/populate.rake'

namespace :installation do
  desc 'Reset DB and seed causes and services to DB'
  task start: :environment do
    puts 'Reseting database...'
    Rake::Task['db:reset'].invoke
    Rake::Task['populate:seed_causes_and_services'].invoke
    Rake::Task['populate:seed_beneficiaries_and_beneficiaries_subcategories'].invoke
    puts '____________________________________________________________'
    puts 'Next steps...'
    puts '1.- redis-server and (overmind s or hivemind s)'
    puts '2.- Please, go to http://localhost:5000/admin and then to organizations'
    puts "3.- Log in with the following credentials Email: 'admin@example.com' | Password: 'testing'"
    puts "4.- Then, upload the 'xlsx' file with the organizations data and wait for all the organizations to be created."
    puts '5.- Finally run rake installation:finish'
  end

  desc 'Creating new organization admin'
  task create_admin: :environment do
    user = User.find(1)
    organization_with_one_location = Organization.find_by(name: 'Room In the Inn')
    organization_with_many_locations = Organization.find_by(name: 'NAMI Tennessee')
    OrganizationAdmin.create!(organization: organization_with_one_location, user: user, role: 'admin')
    OrganizationAdmin.create!(organization: organization_with_many_locations, user: user, role: 'admin')
    puts 'User assigned as admin to organizations successfully!'
  end

  desc 'Creating join table between organizations and causes'
  task finish: :environment do
    Rake::Task['installation:create_admin'].invoke
    Organization.all.each do |org|
      OrganizationCause.create!(organization: org, cause: Cause.find(rand(1..16)))
      org.update!(active: true)
    end
    puts 'Organization Causes created successfully!'

    puts '____________________________________________________________'
    puts 'PROCESS FINISHED!'
    puts 'You can now login into http://localhost:5000/my_account with the following credentials:'
    puts 'Email: user@example.com | Password: testing'
    puts 'You should be admin of 2 organizations, check them in My Nonprofit Pages section.'
    puts '____________________________________________________________'
  end
end
