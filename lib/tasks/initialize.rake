load './lib/tasks/populate.rake'

namespace :installation do
  desc 'Reset DB and seed causes and services to DB'
  task start: :environment do
    puts 'Reseting database... this will run (db:drop, db:create, db:migrate)'
    Rake::Task['db:reset'].invoke
    Rake::Task['populate:seed_causes_and_services'].invoke
    Rake::Task['populate:seed_beneficiaries_and_beneficiaries_subcategories'].invoke
    puts '____________________________________________________________'
    puts 'Next steps...'
    puts '1.- redis-server and overmind start or hivemind start'
    puts '2.- Please go to http://localhost:5000/admin/organizations and log in with the following credentials:'
    puts '3.- Email: admin@example.com | Password: testing'
    puts '4.- Then, upload the xlsx file with the organizations data and wait for all the organizations to be created.'
    puts '5.- Finally run rake installation:finish'
  end

  desc 'Creating join table between organizations and causes'
  task finish: :environment do
    Organization.all.each do |org|
      OrganizationCause.create!(organization: org, cause: Cause.find(rand(1..16)))
      org.update!(active: true)
    end
    puts 'Organization Causes created successfully!'
    Rake::Task['installation:create_admin'].invoke
  end

  desc 'Creating new organization admin'
  task create_admin: :environment do
    user = User.find(1)
    organization_with_one_location = Organization.all.each do |org|
      if org.locations.count == 1
        org
        break
      end
    end
    organization_with_one_location.admin = user
    organization_with_one_location.save!

    organization_with_many_locations = Organization.all.each do |org|
      if org.locations.count > 1
        org
        break
      end
    end
    organization_with_many_locations.admin = user
    organization_with_many_locations.save!
    puts 'User assigned as admin to organizations successfully!'

    puts '.'
    puts '____________________________________________________________'
    puts 'PROCESS FINISHED!'
    puts 'You can now login into http://localhost:5000/my_account with the following credentials:'
    puts 'Email: user@example.com | Password: testing'
    puts 'You should be admin of 2 organizations, check the in My Nonprofit Pages section.'
    puts '____________________________________________________________'
  end
end
