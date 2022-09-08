load './lib/tasks/populate.rake'
require 'colorize'

namespace :init do
  desc 'Reset DB and seed causes and services to DB'
  task reset_and_populate: :environment do
    puts 'Resetting database... this will run (db:drop, db:create, db:migrate, db:seed)'
    Rake::Task['db:reset'].invoke
    puts 'Seeding causes and services to DB'
    Rake::Task['populate:seed_causes_and_services'].invoke
    Rake::Task['populate:seed_beneficiaries_and_beneficiaries_subcategories'].invoke
    Rake::Task['init:next_steps'].invoke
    puts 'Done.'.green

    puts 'Next steps...'.green
    puts 'Please go to http://localhost:5000/admin/organizations and log in with the following credentials:'.blue
    puts 'email: admin@example.com'.blue
    puts 'password: testing'.blue
    puts 'You can change the credentials in the seeds.rb file.'.blue
    puts 'Then, upload the xlsx file with the organizations data.'.blue
    puts 'Finally run rake join_tables:organization_causes'.blue
  end
end
