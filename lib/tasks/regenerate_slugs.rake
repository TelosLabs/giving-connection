namespace :locations do
  desc "Regenerate slugs for all locations"
  task regenerate_slugs: :environment do
    Location.find_each do |location|
      location.slug = nil
      location.save!
      puts "Regenerated slug for Location ID: #{location.id}, new slug: #{location.slug}"
    end
  end
end
