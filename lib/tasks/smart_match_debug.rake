namespace :smart_match_debug do
  desc "Debug the Smart Match service for food assistance"
  task debug_food_assistance: :environment do
    require_relative "../../app/services/smart_match_recommendation_service"

    puts "Debugging Smart Match - Food Assistance..."
    puts "=" * 60

    test_answers = {
      2 => "myself",
      3 => "adult",
      4 => "food_groceries",
      5 => "emergency",
      6 => "atlantic_city",
      7 => "walking_distance",
      8 => ["free_sliding_scale", "spanish_language"]
    }

    service = SmartMatch::RecommendationService.new(test_answers, "seeking_help")

    # Debug step 1: Extract user preferences
    user_causes = service.send(:extract_user_causes)
    user_location = service.send(:extract_user_location)
    user_text_terms = service.send(:generate_user_text_terms)

    puts "User causes: #{user_causes}"
    puts "User location: #{user_location}"
    puts "User text terms: #{user_text_terms}"

    # Debug step 2: Check NTEE mappings
    puts "\nNTEE mappings for food_assistance:"
    puts SmartMatch::RecommendationService::NTEE_MAPPINGS["food_assistance"]

    # Debug step 3: Check filtered nonprofits
    filtered_nonprofits = service.send(:apply_deterministic_filters, user_causes, user_location)
    puts "\nFiltered nonprofits count: #{filtered_nonprofits.length}"

    if filtered_nonprofits.length > 0
      puts "\nFirst 5 filtered nonprofits:"
      filtered_nonprofits.first(5).each_with_index do |np, index|
        puts "#{index + 1}. #{np[:name]} (#{np[:city]}, #{np[:state]}) - NTEE: #{np[:ntee_codes]}"
      end
    else
      puts "\nNo nonprofits passed the filters. Let's check why..."

      # Check all nonprofits with food-related NTEE codes
      all_nonprofits = service.instance_variable_get(:@nonprofits_data)
      food_ntee_codes = SmartMatch::RecommendationService::NTEE_MAPPINGS["food_assistance"]

      puts "\nAll nonprofits with food NTEE codes:"
      food_nonprofits = all_nonprofits.select { |np| (np[:ntee_codes] & food_ntee_codes).any? }
      puts "Found #{food_nonprofits.length} nonprofits with food NTEE codes"

      food_nonprofits.first(5).each_with_index do |np, index|
        puts "#{index + 1}. #{np[:name]} (#{np[:city]}, #{np[:state]}) - NTEE: #{np[:ntee_codes]}"
      end

      # Check location filtering
      puts "\nLocation filtering:"
      puts "User location: #{user_location}"
      nj_nonprofits = all_nonprofits.select { |np| np[:state] == "NJ" }
      puts "Found #{nj_nonprofits.length} nonprofits in NJ"

      nj_nonprofits.first(5).each_with_index do |np, index|
        puts "#{index + 1}. #{np[:name]} (#{np[:city]}, #{np[:state]}) - NTEE: #{np[:ntee_codes]}"
      end
    end

    puts "\n✅ Debug completed!"
    puts "=" * 60
  end

  desc "Debug the actual user quiz flow"
  task debug_user_flow: :environment do
    require_relative "../../app/services/smart_match_recommendation_service"

    puts "Debugging actual user quiz flow..."
    puts "=" * 60

    # This is the actual user data from the error
    test_answers = {
      "1" => "seeking_help",
      "2" => "myself",
      "3" => "student",
      "4" => ["employment_job_training", "education_tutoring"],
      "5" => "long_term_support",
      "6" => "nashville",
      "7" => ["car_access"],
      "8" => ["free_sliding_scale"],
      "9" => "19_24",
      "10" => "female",
      "11" => "black_african_american"
    }

    user_intent = "seeking_help"

    puts "User answers: #{test_answers}"
    puts "User intent: #{user_intent}"

    # Test the new service
    puts "\n1. Testing NEW Smart Match Service:"
    begin
      new_service = SmartMatch::RecommendationService.new(test_answers, user_intent)
      new_recommendations = new_service.generate_recommendations(5)

      puts "Found #{new_recommendations.length} recommendations:"
      new_recommendations.each_with_index do |rec, index|
        puts "#{index + 1}. #{rec[:location].name} (#{(rec[:similarity_score] * 100).round(1)}%)"
      end
    rescue => e
      puts "❌ New service failed: #{e.message}"
      puts e.backtrace.first(5)
    end

    # Test the controller method
    puts "\n2. Testing Controller Method:"
    begin
      controller = SmartMatchController.new
      controller.instance_variable_set(:@current_location, {
        city: "Nashville",
        state: "Tennessee",
        country: "USA",
        latitude: 36.16404968727089,
        longitude: -86.78125827725053
      })

      recommendations = controller.send(:generate_recommendations, test_answers, user_intent)

      puts "Found #{recommendations.length} recommendations:"
      if recommendations.any?
        first_rec = recommendations.first
        puts "First recommendation type: #{first_rec.class}"
        if first_rec.is_a?(Hash)
          puts "Keys: #{first_rec.keys}"
          puts "Location: #{first_rec[:location].class}"
          puts "Score: #{first_rec[:similarity_score]}"
        else
          puts "Direct location object: #{first_rec.class}"
        end
      end
    rescue => e
      puts "❌ Controller method failed: #{e.message}"
      puts e.backtrace.first(5)
    end

    puts "\n✅ User flow debug completed!"
    puts "=" * 60
  end

  desc "Test SmartMatch module availability"
  task test_module_availability: :environment do
    puts "Testing SmartMatch module availability..."
    puts "=" * 60

    # Test 1: Direct module check
    puts "\n1. Testing direct module check:"
    begin
      puts "SmartMatch module defined: #{defined?(SmartMatch)}"
      puts "SmartMatch::RecommendationService defined: #{defined?(SmartMatch::RecommendationService)}"
    rescue => e
      puts "❌ Module check failed: #{e.message}"
    end

    # Test 2: Controller context
    puts "\n2. Testing controller context:"
    begin
      controller = SmartMatchController.new
      puts "Controller class: #{controller.class}"
      puts "SmartMatch module available in controller: #{controller.class.const_defined?(:SmartMatch)}"
    rescue => e
      puts "❌ Controller context failed: #{e.message}"
    end

    # Test 3: Service instantiation in controller context
    puts "\n3. Testing service instantiation in controller context:"
    begin
      SmartMatchController.new
      SmartMatch::RecommendationService.new({}, "seeking_help")
      puts "✅ Service instantiated successfully in controller context"
    rescue => e
      puts "❌ Service instantiation failed: #{e.message}"
      puts e.backtrace.first(3)
    end

    puts "\n✅ Module availability test completed!"
    puts "=" * 60
  end

  desc "Test method call directly"
  task test_method_call: :environment do
    puts "Testing method call directly..."
    puts "=" * 60

    # Test the method call directly
    begin
      controller = SmartMatchController.new
      controller.instance_variable_set(:@current_location, {
        city: "Nashville",
        state: "Tennessee",
        country: "USA",
        latitude: 36.16404968727089,
        longitude: -86.78125827725053
      })

      test_answers = {
        "1" => "seeking_help",
        "2" => "myself",
        "3" => "student",
        "4" => ["employment_job_training", "education_tutoring"],
        "5" => "long_term_support",
        "6" => "nashville",
        "7" => ["car_access"],
        "8" => ["free_sliding_scale"],
        "9" => "19_24",
        "10" => "female",
        "11" => "black_african_american"
      }
      user_intent = "seeking_help"

      puts "Calling generate_recommendations directly..."
      recommendations = controller.send(:generate_recommendations, test_answers, user_intent)

      puts "Method returned #{recommendations.length} recommendations"
      if recommendations.any?
        first_rec = recommendations.first
        puts "First recommendation type: #{first_rec.class}"
        if first_rec.is_a?(Hash)
          puts "Keys: #{first_rec.keys}"
          puts "Score: #{first_rec[:similarity_score]}"
        end
      end
    rescue => e
      puts "❌ Direct method call failed: #{e.message}"
      puts e.backtrace.first(5)
    end

    puts "\n✅ Direct method call test completed!"
    puts "=" * 60
  end

  desc "Test different quiz answers to see if filtering works"
  task test_different_answers: :environment do
    require_relative "../../app/services/smart_match_recommendation_service"

    puts "Testing different quiz answers..."
    puts "=" * 60

    # Test 1: Animal and Environment
    puts "\n1. Testing Animal and Environment:"
    test_answers_1 = {
      "1" => "seeking_help",
      "2" => "myself",
      "3" => "adult",
      "4" => ["animal", "environment"],
      "5" => "long_term_support",
      "6" => "nashville",
      "7" => ["car_access"],
      "8" => ["free_sliding_scale"]
    }

    service_1 = SmartMatch::RecommendationService.new(test_answers_1, "seeking_help")
    user_causes_1 = service_1.send(:extract_user_causes)
    user_location_1 = service_1.send(:extract_user_location)
    filtered_1 = service_1.send(:apply_deterministic_filters, user_causes_1, user_location_1)

    puts "User causes: #{user_causes_1}"
    puts "User location: #{user_location_1}"
    puts "Filtered nonprofits: #{filtered_1.length}"

    if filtered_1.length > 0
      puts "First 3 results:"
      filtered_1.first(3).each_with_index do |np, index|
        puts "#{index + 1}. #{np[:name]} - NTEE: #{np[:ntee_codes]}"
      end
    end

    # Test 2: Food Assistance
    puts "\n2. Testing Food Assistance:"
    test_answers_2 = {
      "1" => "seeking_help",
      "2" => "myself",
      "3" => "adult",
      "4" => ["food_groceries"],
      "5" => "emergency",
      "6" => "atlantic_city",
      "7" => ["walking_distance"],
      "8" => ["free_sliding_scale"]
    }

    service_2 = SmartMatch::RecommendationService.new(test_answers_2, "seeking_help")
    user_causes_2 = service_2.send(:extract_user_causes)
    user_location_2 = service_2.send(:extract_user_location)
    filtered_2 = service_2.send(:apply_deterministic_filters, user_causes_2, user_location_2)

    puts "User causes: #{user_causes_2}"
    puts "User location: #{user_location_2}"
    puts "Filtered nonprofits: #{filtered_2.length}"

    if filtered_2.length > 0
      puts "First 3 results:"
      filtered_2.first(3).each_with_index do |np, index|
        puts "#{index + 1}. #{np[:name]} - NTEE: #{np[:ntee_codes]}"
      end
    end

    # Test 3: Mental Health
    puts "\n3. Testing Mental Health:"
    test_answers_3 = {
      "1" => "seeking_help",
      "2" => "myself",
      "3" => "adult",
      "4" => ["mental_health"],
      "5" => "long_term_support",
      "6" => "los_angeles",
      "7" => ["car_access"],
      "8" => ["free_sliding_scale"]
    }

    service_3 = SmartMatch::RecommendationService.new(test_answers_3, "seeking_help")
    user_causes_3 = service_3.send(:extract_user_causes)
    user_location_3 = service_3.send(:extract_user_location)
    filtered_3 = service_3.send(:apply_deterministic_filters, user_causes_3, user_location_3)

    puts "User causes: #{user_causes_3}"
    puts "User location: #{user_location_3}"
    puts "Filtered nonprofits: #{filtered_3.length}"

    if filtered_3.length > 0
      puts "First 3 results:"
      filtered_3.first(3).each_with_index do |np, index|
        puts "#{index + 1}. #{np[:name]} - NTEE: #{np[:ntee_codes]}"
      end
    end

    puts "\n✅ Different answers test completed!"
    puts "=" * 60
  end
end
