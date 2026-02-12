namespace :smart_match_improved do
  desc "Test the improved Smart Match recommendation service"
  task test_service: :environment do
    require_relative "../../app/services/improved_smart_match_service"
    puts "Testing Improved Smart Match Recommendation Service..."
    puts "=" * 60

    # Test case 1: Service Seeker - Food Assistance (Atlantic City)
    puts "\n1. Testing Service Seeker - Food Assistance (Atlantic City, NJ)"
    test_answers_1 = {
      2 => "myself",  # seeking help for myself
      3 => "crisis_hardships",   # facing crisis
      4 => "food_groceries", # food assistance
      5 => "urgent_services", # urgent situation
      6 => "atlantic_city", # Atlantic City area
      7 => "walking_distance", # walking distance
      8 => ["free_sliding_scale", "spanish_language"] # support needs
    }

    service_1 = SmartMatch::ImprovedRecommendationService.new(test_answers_1, "seeking_help")
    recommendations_1 = service_1.generate_recommendations(5)

    puts "Found #{recommendations_1.length} recommendations:"
    recommendations_1.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name} (#{rec[:location].state})"
      puts "   Score: #{(rec[:similarity_score] * 100).round(1)}%"
      puts "   Reason: #{rec[:relevance_reason]}"
      puts ""
    end

    # Test case 2: Service Seeker - Mental Health (Los Angeles)
    puts "\n2. Testing Service Seeker - Mental Health (Los Angeles, CA)"
    test_answers_2 = {
      2 => "myself",
      3 => "lgbtqia",
      4 => "mental_health_services",
      5 => "long_term_support",
      6 => "los_angeles",
      7 => "public_transportation",
      8 => ["lgbtqia_affirming", "free_sliding_scale"]
    }

    service_2 = SmartMatch::ImprovedRecommendationService.new(test_answers_2, "seeking_help")
    recommendations_2 = service_2.generate_recommendations(5)

    puts "Found #{recommendations_2.length} recommendations:"
    recommendations_2.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name} (#{rec[:location].state})"
      puts "   Score: #{(rec[:similarity_score] * 100).round(1)}%"
      puts "   Reason: #{rec[:relevance_reason]}"
      puts ""
    end

    # Test case 3: Volunteer - Animal Welfare (Nashville)
    puts "\n3. Testing Volunteer - Animal Welfare (Nashville, TN)"
    test_answers_3 = {
      2 => ["animal_welfare", "environment"],
      3 => "hands_on",
      4 => ["work_with_kids_seniors", "family_friendly"],
      5 => "specific_location",
      6 => "nashville",
      7 => "ongoing",
      8 => "adult_25_34",
      9 => "female",
      10 => "white"
    }

    service_3 = SmartMatch::ImprovedRecommendationService.new(test_answers_3, "volunteering")
    recommendations_3 = service_3.generate_recommendations(5)

    puts "Found #{recommendations_3.length} recommendations:"
    recommendations_3.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name} (#{rec[:location].state})"
      puts "   Score: #{(rec[:similarity_score] * 100).round(1)}%"
      puts "   Reason: #{rec[:relevance_reason]}"
      puts ""
    end

    # Test case 4: Donor - Education (Any location)
    puts "\n4. Testing Donor - Education (Any location)"
    test_answers_4 = {
      2 => ["education", "children_family_services"],
      3 => "medium",
      4 => "recurring",
      5 => ["children_families", "bipoc_communities"],
      6 => "anywhere",
      7 => "programs",
      8 => "yes",
      9 => "adult_35_44",
      10 => "female"
    }

    service_4 = SmartMatch::ImprovedRecommendationService.new(test_answers_4, "donating")
    recommendations_4 = service_4.generate_recommendations(5)

    puts "Found #{recommendations_4.length} recommendations:"
    recommendations_4.each_with_index do |rec, index|
      puts "#{index + 1}. #{rec[:location].name} (#{rec[:location].state})"
      puts "   Score: #{(rec[:similarity_score] * 100).round(1)}%"
      puts "   Reason: #{rec[:relevance_reason]}"
      puts ""
    end

    puts "\n✅ All tests completed!"
    puts "=" * 60
  end

  desc "Compare old vs improved recommendation service"
  task compare_services: :environment do
    require_relative "../../app/services/smart_match_recommendation_service"
    require_relative "../../app/services/improved_smart_match_service"
    puts "Comparing old vs improved Smart Match services..."
    puts "=" * 60

    # Test case for comparison
    test_answers = {
      2 => "myself",
      3 => "crisis_hardships",
      4 => "food_groceries",
      5 => "urgent_services",
      6 => "atlantic_city",
      7 => "walking_distance",
      8 => ["free_sliding_scale", "spanish_language"]
    }

    user_intent = "seeking_help"

    # Test old service
    puts "\n1. Testing OLD Smart Match Service:"
    begin
      old_service = SmartMatch::RecommendationService.new(test_answers, user_intent)
      old_recommendations = old_service.generate_recommendations(5)

      puts "Found #{old_recommendations.length} recommendations:"
      old_recommendations.each_with_index do |rec, index|
        puts "#{index + 1}. #{rec[:location].name} (#{rec[:location].state}) - #{(rec[:similarity_score] * 100).round(1)}%"
      end
    rescue => e
      puts "Old service failed: #{e.message}"
    end

    # Test improved service
    puts "\n2. Testing IMPROVED Smart Match Service:"
    begin
      improved_service = SmartMatch::ImprovedRecommendationService.new(test_answers, user_intent)
      improved_recommendations = improved_service.generate_recommendations(5)

      puts "Found #{improved_recommendations.length} recommendations:"
      improved_recommendations.each_with_index do |rec, index|
        puts "#{index + 1}. #{rec[:location].name} (#{rec[:location].state}) - #{(rec[:similarity_score] * 100).round(1)}%"
      end
    rescue => e
      puts "Improved service failed: #{e.message}"
    end

    puts "\n✅ Comparison completed!"
    puts "=" * 60
  end

  desc "Test location filtering accuracy"
  task test_location_filtering: :environment do
    require_relative "../../app/services/improved_smart_match_service"
    puts "Testing location filtering accuracy..."
    puts "=" * 60

    # Test NJ filtering
    puts "\n1. Testing New Jersey (Atlantic City) filtering:"
    test_answers_nj = {
      2 => "myself",
      3 => "student",
      4 => "employment_job_training",
      6 => "atlantic_city"
    }

    service_nj = SmartMatch::ImprovedRecommendationService.new(test_answers_nj, "seeking_help")
    recommendations_nj = service_nj.generate_recommendations(10)

    nj_count = recommendations_nj.count { |rec| rec[:location].state == "NJ" }
    puts "Total recommendations: #{recommendations_nj.length}"
    puts "NJ recommendations: #{nj_count}"
    puts "Accuracy: #{(nj_count.to_f / recommendations_nj.length * 100).round(1)}%"

    # Test CA filtering
    puts "\n2. Testing California (Los Angeles) filtering:"
    test_answers_ca = {
      2 => "myself",
      3 => "lgbtqia",
      4 => "mental_health_services",
      6 => "los_angeles"
    }

    service_ca = SmartMatch::ImprovedRecommendationService.new(test_answers_ca, "seeking_help")
    recommendations_ca = service_ca.generate_recommendations(10)

    ca_count = recommendations_ca.count { |rec| rec[:location].state == "CA" }
    puts "Total recommendations: #{recommendations_ca.length}"
    puts "CA recommendations: #{ca_count}"
    puts "Accuracy: #{(ca_count.to_f / recommendations_ca.length * 100).round(1)}%"

    # Test TN filtering
    puts "\n3. Testing Tennessee (Nashville) filtering:"
    test_answers_tn = {
      2 => "myself",
      3 => "veteran_military",
      4 => "housing_shelter",
      6 => "nashville"
    }

    service_tn = SmartMatch::ImprovedRecommendationService.new(test_answers_tn, "seeking_help")
    recommendations_tn = service_tn.generate_recommendations(10)

    tn_count = recommendations_tn.count { |rec| rec[:location].state == "TN" }
    puts "Total recommendations: #{recommendations_tn.length}"
    puts "TN recommendations: #{tn_count}"
    puts "Accuracy: #{(tn_count.to_f / recommendations_tn.length * 100).round(1)}%"

    puts "\n✅ Location filtering tests completed!"
    puts "=" * 60
  end
end
