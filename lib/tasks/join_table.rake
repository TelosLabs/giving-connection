namespace :join_tables do
  desc 'Creating join table between organizations and causes'
  task organization_causes: :environment do
    Organization.all.each do |org|
      OrganizationCause.create!(organization: org, cause: Cause.find(rand(1..16)))
      org.update!(active: true)
    end
  end
end
