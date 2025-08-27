namespace :smart_match_new do
  desc "Test the new Smart Match recommendation service"
  task test_service: :environment do
    require_relative "../../app/services/smart_match_recommendation_service"
    puts "Testing new Smart Match Recommendation Service..."
    puts "=" * 60

    # Test case 1: Service Seeker - Food Assistance
    puts "\n1. Testing Service Seeker - Food Assistance"
    test_answers_1 = {
      2 => "myself",  # seeking help for myself
      3 => "adult",   # adult
      4 => "food_groceries", # food assistance
      5 => "emergency", # emergency situation
      6 => "atlantic_city", # Atlantic City area
      7 => "walking_distance", # walking distance
      8 => ["free_sliding_scale", "spanish_language"] # support needs
    }

    service_1 = SmartMatch::RecommendationService.new(test_answers_1, "seeking_help")
    recommendations_1 = service_1.generate_recommendations(5)

    puts "Found #{recommendations_1.length} recommendations:"
    recommendations_1.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name}"
      puts "   Score: #{(rec[:similarity_score] * 100).round(1)}%"
      puts "   Reason: #{rec[:relevance_reason]}"
      puts ""
    end

    # Test case 2: Volunteer - Animal Welfare
    puts "\n2. Testing Volunteer - Animal Welfare"
    test_answers_2 = {
      2 => "animal_welfare", # animal welfare
      3 => "hands_on", # hands-on work
      4 => "local_community", # local community
      5 => "nashville", # Nashville area
      6 => "both", # both in-person and remote
      7 => ["time_1", "time_2"], # few hours weekly and ongoing
      8 => "adult_25_34", # age range
      9 => "female", # gender
      10 => "white" # race/ethnicity
    }

    service_2 = SmartMatch::RecommendationService.new(test_answers_2, "volunteering")
    recommendations_2 = service_2.generate_recommendations(5)

    puts "Found #{recommendations_2.length} recommendations:"
    recommendations_2.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name}"
      puts "   Score: #{(rec[:similarity_score] * 100).round(1)}%"
      puts "   Reason: #{rec[:relevance_reason]}"
      puts ""
    end

    # Test case 3: Donor - Mental Health
    puts "\n3. Testing Donor - Mental Health"
    test_answers_3 = {
      2 => "mental_health", # mental health
      3 => "monthly", # monthly donation
      4 => "local", # local organizations
      5 => "specific_programs", # specific programs
      6 => "yes", # receive updates
      7 => "adult_35_44", # age range
      8 => "male", # gender
      9 => "hispanic" # race/ethnicity
    }

    service_3 = SmartMatch::RecommendationService.new(test_answers_3, "donating")
    recommendations_3 = service_3.generate_recommendations(5)

    puts "Found #{recommendations_3.length} recommendations:"
    recommendations_3.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name}"
      puts "   Score: #{(rec[:similarity_score] * 100).round(1)}%"
      puts "   Reason: #{rec[:relevance_reason]}"
      puts ""
    end

    puts "\n✅ New Smart Match Recommendation Service test completed!"
    puts "=" * 60
  end

  desc "Compare old vs new recommendation service"
  task compare_services: :environment do
    require_relative "../../app/services/smart_match_recommendation_service"
    puts "Comparing old vs new Smart Match services..."
    puts "=" * 60

    # Test case for comparison
    test_answers = {
      2 => "myself",
      3 => "adult",
      4 => "food_groceries",
      5 => "emergency",
      6 => "atlantic_city",
      7 => "walking_distance",
      8 => ["free_sliding_scale", "spanish_language"]
    }

    user_intent = "seeking_help"

    # Test new service
    puts "\n1. Testing NEW Smart Match Service:"
    new_service = SmartMatch::RecommendationService.new(test_answers, user_intent)
    new_recommendations = new_service.generate_recommendations(5)

    puts "Found #{new_recommendations.length} recommendations:"
    new_recommendations.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name} (#{(rec[:similarity_score] * 100).round(1)}%)"
    end

    # Test old service (if available)
    puts "\n2. Testing OLD Recommendation Service:"
    begin
      old_service = RecommendationService.new(test_answers, user_intent)
      old_recommendations = old_service.generate_recommendations(5)

      puts "Found #{old_recommendations.length} recommendations:"
      old_recommendations.each_with_index do |rec, index|
        puts "#{index + 1}. #{rec[:location].name} (#{(rec[:similarity_score] * 100).round(1)}%)"
      end
    rescue => e
      puts "Old service not available or failed: #{e.message}"
    end

    puts "\n✅ Comparison completed!"
    puts "=" * 60
  end

  desc "Test CSV data loading"
  task test_csv_loading: :environment do
    puts "Testing CSV data loading..."
    puts "=" * 60

    csv_path = Rails.root.join("app/views/smart_match/nonprofits_matrix_data.csv")

    if File.exist?(csv_path)
      puts "CSV file found at: #{csv_path}"

      # Count lines
      line_count = `wc -l "#{csv_path}"`.strip.split(" ")[0].to_i
      puts "Total lines in CSV: #{line_count}"

      # Load first few records
      require "csv"
      nonprofits = []
      CSV.foreach(csv_path, headers: true) do |row|
        nonprofits << {
          name: row["name"],
          ntee_code: row["irs_ntee_code"],
          city: row["city"],
          state: row["state"]
        }
        break if nonprofits.length >= 5
      end

      puts "\nFirst 5 nonprofits:"
      nonprofits.each_with_index do |np, index|
        puts "#{index + 1}. #{np[:name]} (#{np[:city]}, #{np[:state]}) - #{np[:ntee_code]}"
      end

      puts "\n✅ CSV loading test completed!"
    else
      puts "❌ CSV file not found at: #{csv_path}"
    end

    puts "=" * 60
  end
end
