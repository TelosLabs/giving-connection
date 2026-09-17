# Tools for reproducing the production search-performance issue locally:
#
#   rails perf:seed_organizations                 # ~4,000 orgs, production-like scale
#   rails perf:seed_organizations COUNT=1000       # override the count
#   rails perf:benchmark_search                    # log page-load timings once seeded
#   rails perf:clear_organizations CONFIRM=true    # wipe seeded data to reseed cleanly
#
# Seeding bypasses geocoding entirely (uses lib/assets/us_cities_coords.xlsx, already
# in the repo) and bulk-inserts via activerecord-import -- the same mechanism
# SpreadsheetImport::SpreadsheetParser already uses for the real admin upload, which
# skips callbacks (no default-logo attachment, no Smart Match embedding jobs fired
# 4,000 times). That keeps a multi-thousand-row seed fast and side-effect-free.
module PerfSeed
  DEFAULT_COUNT = 4000
  DEFAULT_BATCH_SIZE = 250

  # Approximate coordinates, just for realistic geographic clustering -- not tied to
  # the geocoded us_cities_coords.xlsx list.
  HUB_CITIES = [
    {name: "Nashville", state: "TN", lat: 36.1627, lon: -86.7816},
    {name: "Los Angeles", state: "CA", lat: 34.0522, lon: -118.2437},
    {name: "Chicago", state: "IL", lat: 41.8781, lon: -87.6298},
    {name: "Houston", state: "TX", lat: 29.7604, lon: -95.3698},
    {name: "Miami", state: "FL", lat: 25.7617, lon: -80.1918},
    {name: "Atlanta", state: "GA", lat: 33.7490, lon: -84.3880},
    {name: "Seattle", state: "WA", lat: 47.6062, lon: -122.3321},
    {name: "Denver", state: "CO", lat: 39.7392, lon: -104.9903},
    {name: "Boston", state: "MA", lat: 42.3601, lon: -71.0589},
    {name: "Phoenix", state: "AZ", lat: 33.4484, lon: -112.0740}
  ].freeze

  # Rotated across locations so open_now/open_weekends filters have real signal
  # instead of every row behaving identically.
  HOURS_PATTERNS = %i[weekdays_only all_week weekdays_plus_weekend].freeze

  TAG_POOL = [
    "Food banks", "Family services", "Arts education", "Youth mentoring",
    "Senior care", "Crisis support", "Job readiness", "ESL classes",
    "Emergency shelter", "Community garden", "After-school program", "Legal aid",
    "Disaster relief", "Pet adoption", "Literacy program", "Health screenings",
    "Veteran support", "Domestic violence support", "Recovery support",
    "Immigration services", "Financial literacy", "Housing assistance",
    "Mental health counseling", "Tutoring", "Disability services",
    "Environmental cleanup", "Faith-based outreach", "LGBTQ+ support",
    "Meal delivery", "Clothing closet"
  ].freeze

  module_function

  def run(count:, batch_size:)
    ensure_reference_data!

    cities = load_cities
    causes_by_name = Cause.all.index_by(&:name)
    services_by_cause = Service.includes(:cause).group_by { |s| s.cause.name }
    beneficiary_subcategories = BeneficiarySubcategory.all.to_a
    admin = AdminUser.first_or_create!(email: "perf-seed@example.com", password: SecureRandom.hex(12))

    puts "Seeding #{count} organizations (batches of #{batch_size})..."
    started_at = Time.current
    created = 0
    failed = 0

    (0...count).each_slice(batch_size) do |slice|
      orgs = slice.map do |i|
        build_organization(i, cities, admin, causes_by_name, services_by_cause, beneficiary_subcategories)
      end

      result = Organization.import(orgs, recursive: true, validate: true, track_validation_failures: true)
      created += result.ids.size
      failed += result.failed_instances.size

      print "\r#{created}/#{count} organizations created (#{failed} failed)"
      $stdout.flush
    end
    puts

    unless ENV["SKIP_MULTISEARCH_REBUILD"] == "true"
      puts "Rebuilding pg_search multisearch index..."
      PgSearch::Multisearch.rebuild(Organization)
      PgSearch::Multisearch.rebuild(Location)
      PgSearch::Multisearch.rebuild(Tag)
    end

    elapsed = (Time.current - started_at).round(1)
    puts "Done in #{elapsed}s"
    puts "Organizations: #{Organization.count}"
    puts "Locations: #{Location.count}"
    puts "Office hours: #{OfficeHour.count}"
  end

  def ensure_reference_data!
    if Cause.count.zero?
      puts "No causes found -- seeding causes/services first..."
      Rake::Task["populate:seed_causes_and_services"].invoke
    end
    if BeneficiaryGroup.count.zero?
      puts "No beneficiary groups found -- seeding beneficiaries first..."
      Rake::Task["populate:seed_beneficiaries_and_beneficiaries_subcategories"].invoke
    end
  end

  def load_cities
    workbook = Roo::Spreadsheet.open(Rails.root.join("lib/assets/us_cities_coords.xlsx").to_s)
    workbook.sheet(0).parse(place_name: "place_name", latitude: "latitude", longitude: "longitude", clean: true)
  end

  def build_organization(index, cities, admin, causes_by_name, services_by_cause, beneficiary_subcategories)
    cause_names = causes_by_name.keys.sample(rand(1..3))

    org = Organization.new(
      name: "#{Faker::Company.name} ##{index}",
      ein_number: format("%02d-%07d", 10 + (index % 89), 1_000_000 + index),
      irs_ntee_code: Organizations::Constants::NTEE_CODE.sample,
      mission_statement_en: Faker::Company.catch_phrase,
      vision_statement_en: Faker::Lorem.sentence(word_count: 12),
      tagline_en: Faker::Company.bs.capitalize,
      website: "https://#{Faker::Internet.domain_name}",
      scope_of_work: Organizations::Constants::SCOPE.sample,
      languages: rand < 0.3 ? [Organizations::Constants::LANGUAGES.sample] : nil,
      active: true,
      creator: admin
    )
    assign_give_fields(org, index)

    cause_names.each { |name| org.organization_causes.build(cause: causes_by_name[name]) }
    beneficiary_subcategories.sample(rand(1..3)).each do |subcategory|
      org.organization_beneficiaries.build(beneficiary_subcategory: subcategory)
    end
    TAG_POOL.sample(rand(1..4)).each { |name| org.tags.build(name: name) }

    if index.even?
      org.build_social_media(
        facebook: "https://facebook.com/#{Faker::Internet.username}",
        instagram: "https://instagram.com/#{Faker::Internet.username}"
      )
    end

    location_count = [1, 1, 1, 2, 2, 3].sample
    location_count.times { |i| build_location(org, i.zero?, cities, cause_names, services_by_cause) }

    org
  end

  def assign_give_fields(org, index)
    org.donation_link = "https://#{Faker::Internet.domain_name}/donate" if index % 5 < 2 # 40%

    if index % 10 < 3 # 30%
      org.volunteer_availability = true
      org.volunteer_link = "https://#{Faker::Internet.domain_name}/volunteer"
    end

    case index % 20
    when 0..2 # 15%
      org.in_kind_donation_link = "https://#{Faker::Internet.domain_name}/wishlist"
    when 3..5 # 15%
      org.in_kind_donation_items = Organizations::Constants::IN_KIND_DONATION_ITEM_KEYS.sample(rand(1..5))
    end
  end

  def build_location(org, main, cities, cause_names, services_by_cause)
    lat, lon, place_name, state_code = pick_coordinates(cities)
    offer_services = rand < 0.85

    location = org.locations.build(
      name: "#{org.name} - #{place_name.split(",").first}",
      address: "#{Faker::Address.street_address}, #{place_name}",
      latitude: lat,
      longitude: lon,
      lonlat: Geo.point(lon, lat),
      main: main,
      offer_services: offer_services,
      state_code: state_code,
      public_address: true,
      po_box: false
    )

    location.build_phone_number(number: Faker::PhoneNumber.cell_phone, main: true) if main

    if offer_services
      services_pool = cause_names.flat_map { |name| services_by_cause[name] || [] }
      services_pool = services_by_cause.values.flatten if services_pool.empty?
      services_pool.sample([services_pool.size, rand(1..3)].min).each do |service|
        location.location_services.build(service: service)
      end

      if rand < 0.6
        location.time_zone = time_zone_for_longitude(lon)
        build_office_hours(location, HOURS_PATTERNS.sample)
      else
        location.non_standard_office_hours = %w[appointment_only always_open no_set_business_hours].sample
      end
    end

    location
  end

  # 50% clustered around Nashville (matches Locations::GeolocationQuery's default
  # search origin, and the product's actual home market), 20% around other major
  # metros, 30% scattered across ~1,100 US cities -- so distance-based filters
  # return a realistic, non-uniform result density instead of a flat random spread.
  def pick_coordinates(cities)
    roll = rand(100)
    if roll < 50
      hub = HUB_CITIES.first # Nashville
      coords = RandomCoordinatesGenerator.call(central_lat: hub[:lat], central_lng: hub[:lon], max_radius: 80_000)
      [coords[:lat], coords[:lng], "#{hub[:name]} area, #{hub[:state]}, USA", hub[:state]]
    elsif roll < 70
      hub = HUB_CITIES.sample
      coords = RandomCoordinatesGenerator.call(central_lat: hub[:lat], central_lng: hub[:lon], max_radius: 60_000)
      [coords[:lat], coords[:lng], "#{hub[:name]} area, #{hub[:state]}, USA", hub[:state]]
    else
      city = cities.sample
      # us_cities_coords.xlsx isn't uniformly formatted ("Joliet, Illinois, USA" vs
      # "Peabody, MA, USA") -- state_code is a 2-char column, so only keep the
      # segment when it actually looks like an abbreviation.
      state = city[:place_name].to_s.split(",")[1]&.strip
      state = nil unless state&.match?(/\A[A-Za-z]{2}\z/)
      [city[:latitude].to_f, city[:longitude].to_f, city[:place_name], state]
    end
  end

  def time_zone_for_longitude(longitude)
    case longitude
    when ..-115 then "Pacific Time (US & Canada)"
    when -115..-101 then "Mountain Time (US & Canada)"
    when -101..-87 then "Central Time (US & Canada)"
    else "Eastern Time (US & Canada)"
    end
  end

  def build_office_hours(location, pattern)
    (0..6).each do |day|
      weekend = [0, 6].include?(day)

      open_time, close_time, closed =
        case pattern
        when :weekdays_only
          weekend ? [nil, nil, true] : ["09:00", "17:00", false]
        when :all_week
          ["08:00", "20:00", false]
        when :weekdays_plus_weekend
          weekend ? ["10:00", "14:00", false] : ["09:00", "17:00", false]
        end

      location.office_hours.build(day: day, open_time: open_time, close_time: close_time, closed: closed)
    end
  end
end

# Logs wall-clock time (and SQL query count) for a battery of representative search
# page loads: cold landing, first results load, each filter alone, a location
# change, and everything combined. Runs entirely in-process (no server needed) via
# an ActionDispatch integration session, and rolls back every DB write it causes
# (search-term analytics, mainly) so repeated runs don't pollute real tables.
module PerfBenchmark
  module_function

  def run(repeats:)
    org = Organization.first
    abort "No organizations found -- run `rails perf:seed_organizations` first." unless org

    results = []

    ActiveRecord::Base.transaction do
      session = ActionDispatch::Integration::Session.new(Rails.application)
      session.host = "localhost" # the default "www.example.com" gets 403'd by ActionDispatch::HostAuthorization
      search_url = Rails.application.routes.url_helpers.search_url(host: "localhost")

      scenarios(search_url).each do |name, opts|
        perform_request(session, opts) # warmup, discarded

        durations = []
        query_counts = []
        status = nil

        repeats.times do
          count = 0
          subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
            count += 1 unless payload[:name] == "SCHEMA" || payload[:cached]
          end

          elapsed = Benchmark.realtime { perform_request(session, opts) }

          ActiveSupport::Notifications.unsubscribe(subscriber)
          durations << (elapsed * 1000).round(1)
          query_counts << count
          status = session.response.status
        end

        results << {
          name: name,
          min_ms: durations.min,
          median_ms: durations.sort[durations.size / 2],
          max_ms: durations.max,
          queries: query_counts.sort[query_counts.size / 2],
          status: status
        }
      end

      raise ActiveRecord::Rollback
    end

    report(results)
  end

  def perform_request(session, opts)
    headers = opts[:cold] ? {} : {"HTTP_REFERER" => opts[:search_url]}
    session.get("/search", params: opts[:params], headers: headers)
  end

  # Built from whatever reference data actually exists in the DB (works whether
  # you seeded 300 or 4,000 orgs), so a filter scenario is skipped rather than
  # silently no-op'd if e.g. no causes were seeded.
  def scenarios(search_url)
    cause = Cause.first
    service = cause && Service.find_by(cause: cause)
    beneficiary_group = BeneficiaryGroup.first
    subcategory = beneficiary_group && BeneficiarySubcategory.find_by(beneficiary_group: beneficiary_group)

    nashville = Locations::GeolocationQuery::DEFAULT_LOCATION
    base = {city: "Nashville", state: "TN", lat: nashville[:latitude], lon: nashville[:longitude]}
    los_angeles = {city: "Los Angeles", state: "CA", lat: 34.0522, lon: -118.2437}

    list = []
    list << ["Cold landing (no referrer/no params -- preview branch)", {params: {}, cold: true, search_url: search_url}]
    list << ["Initial results load (default location, no filters)", {params: {search: base}, search_url: search_url}]
    list << ["Keyword search", {params: {search: base.merge(keyword: "food")}, search_url: search_url}]
    list << ["Single cause filter", {params: {search: base.merge(causes: [cause.name])}, search_url: search_url}] if cause
    if service
      list << ["Single service filter", {params: {search: base.merge(services: {service.cause.name => [service.name]})}, search_url: search_url}]
    end
    if subcategory
      list << ["Single beneficiary filter", {params: {search: base.merge(beneficiary_groups: {beneficiary_group.name => [subcategory.name]})}, search_url: search_url}]
    end
    list << ["Scope of work filter", {params: {search: base.merge(scope_of_work: "National")}, search_url: search_url}]
    list << ["Give filter (donation)", {params: {search: base.merge(give: ["donation"])}, search_url: search_url}]
    list << ["Open now filter", {params: {search: base.merge(open_now: "true")}, search_url: search_url}]
    list << ["Open on weekends filter", {params: {search: base.merge(open_weekends: "true")}, search_url: search_url}]
    list << ["Change location (Los Angeles)", {params: {search: los_angeles}, search_url: search_url}]
    list << ["Distance filter (50km, Los Angeles)", {params: {search: los_angeles.merge(distance: 50)}, search_url: search_url}]
    list << ["Search all (broadest, unfiltered)", {params: {search: base.merge(city: "Search all")}, search_url: search_url}]

    combined = base.merge(keyword: "help", scope_of_work: "National", open_now: "true", give: ["donation", "volunteer"])
    combined[:causes] = [cause.name] if cause
    combined[:services] = {service.cause.name => [service.name]} if service
    combined[:beneficiary_groups] = {beneficiary_group.name => [subcategory.name]} if subcategory
    list << ["Multiple filters combined (worst case)", {params: {search: combined}, search_url: search_url}]

    list << ["Pagination - page 2 (default location)", {params: {search: base, page: 2}, search_url: search_url}]
    list
  end

  def report(results)
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    log_dir = Rails.root.join("tmp", "performance_benchmarks")
    FileUtils.mkdir_p(log_dir)
    log_path = log_dir.join("#{timestamp}.log")

    header = format("%-52s %8s %10s %8s %8s %6s", "Scenario", "min ms", "median ms", "max ms", "queries", "http")
    lines = [
      "Organizations: #{Organization.count}  Locations: #{Location.count}  (#{Time.current})",
      header,
      "-" * header.length
    ]
    results.each do |r|
      lines << format("%-52s %8s %10s %8s %8s %6s", r[:name], r[:min_ms], r[:median_ms], r[:max_ms], r[:queries], r[:status])
    end

    output = lines.join("\n")
    puts output
    File.write(log_path, output)
    puts "\nLogged to #{log_path}"
  end
end

namespace :perf do
  desc "Seed ~4,000 organizations (production scale) with realistic locations/causes/services/beneficiaries/office hours for reproducing the search performance issue locally. Usage: rails perf:seed_organizations [COUNT=4000] [BATCH_SIZE=250]"
  task seed_organizations: :environment do
    count = (ENV["COUNT"] || PerfSeed::DEFAULT_COUNT).to_i
    batch_size = (ENV["BATCH_SIZE"] || PerfSeed::DEFAULT_BATCH_SIZE).to_i
    PerfSeed.run(count: count, batch_size: batch_size)
  end

  desc "Delete all organizations seeded for performance testing (and everything dependent: :destroy cascades to). Requires CONFIRM=true. Refuses to run in production."
  task clear_organizations: :environment do
    abort "Refusing to run against production." if Rails.env.production?
    abort "Pass CONFIRM=true to actually delete all organizations." unless ENV["CONFIRM"] == "true"

    count = Organization.count
    Organization.find_each(&:destroy) # dependent: :destroy needs instance-level destroy, not delete_all
    puts "Deleted #{count} organizations."
  end

  desc "Log page-load time and SQL query count for representative search scenarios (landing, each filter, location change, combined). Usage: rails perf:benchmark_search [REPEATS=3]"
  task benchmark_search: :environment do
    require "benchmark"
    PerfBenchmark.run(repeats: (ENV["REPEATS"] || 3).to_i)
  end
end
