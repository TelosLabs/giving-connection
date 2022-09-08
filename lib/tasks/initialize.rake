load './lib/tasks/populate.rake'

namespace :init do
  desc 'Reset DB and seed causes and services to DB'
  task reset_and_populate: :environment do
    puts 'Reseting database... this will run (db:drop, db:create, db:migrate, db:seed)'
    Rake::Task['db:reset'].invoke
    Rake::Task['populate:seed_causes_and_services'].invoke
    Rake::Task['populate:seed_beneficiaries_and_beneficiaries_subcategories'].invoke
    puts '____________________________________________________________'
    puts 'Next steps...'
    puts '1.- Please go to http://localhost:5000/admin/organizations and log in with the following credentials:'
    puts '2.- email: admin@example.com | password: testing'
    puts '3.- Then, upload the xlsx file with the organizations data.'
    puts '4.- Finally run rake join_tables:organization_causes'
  end
end
