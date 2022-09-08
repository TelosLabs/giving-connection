load './lib/tasks/populate.rake'

namespace :initialize do
  desc 'Reset DB and seed causes and services to DB'
  task all: :environment do
    puts 'Resetting database... this will run (db:drop, db:create, db:migrate, db:seed)'
    Rake::Task['db:reset'].invoke
    puts 'Seeding causes and services to DB'
    Rake::Task['populate:seed_causes_and_services'].invoke
    Rake::Task['populate:seed_beneficiaries_and_beneficiaries_subcategories'].invoke
  end
end

puts 'Please go to http://localhost:3000/admin'
