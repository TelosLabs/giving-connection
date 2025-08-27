# Quiz to UserIntent Converter
# Converts quiz answers to structured UserIntent for the recommendation system
class QuizToUserIntentConverter
  def initialize(quiz_answers, user_intent_type)
    @quiz_answers = quiz_answers
    @user_intent_type = user_intent_type
  end

  def convert
    UserIntent.new(
      user_state: extract_user_state,
      user_city: extract_user_city,
      travel_bucket: extract_travel_bucket,
      user_type: map_user_type(@user_intent_type),
      causes_selected: extract_causes,
      prefs_selected: extract_preferences,
      language_input: extract_language_preference
    )
  end

  private

  def map_user_type(user_intent_type)
    case user_intent_type
    when "seeking_help"
      "seeker"
    when "volunteering"
      "volunteer"
    when "donating"
      "donor"
    else
      "seeker" # default
    end
  end

  private

  def extract_user_state
    # Extract state from quiz answers
    # For service seekers, city selection is in step 6
    city_answer = @quiz_answers["6"] || @quiz_answers["city"] || @quiz_answers["location"] || @quiz_answers["user_state"]

    # Map common state formats to our supported states
    case city_answer&.downcase
    when "atlantic city", "new jersey", "nj"
      "NJ"
    when "los angeles", "california", "ca"
      "CA"
    when "nashville", "tennessee", "tn"
      "TN"
    else
      # Default to first supported state if not found
      "NJ"
    end
  end

  def extract_user_city
    # Extract city from quiz answers
    # For service seekers, city selection is in step 6
    city_answer = @quiz_answers["6"] || @quiz_answers["city"] || @quiz_answers["location"] || @quiz_answers["user_city"]

    # Map to supported cities or use as-is
    case city_answer&.downcase
    when "atlantic city"
      "Atlantic City"
    when "los angeles", "la"
      "Los Angeles"
    when "nashville"
      "Nashville"
    else
      # Use the provided city or default
      city_answer&.titleize || "Atlantic City"
    end
  end

  def extract_travel_bucket
    # Extract travel preference from quiz answers
    # For service seekers, travel preference is in step 5
    # For donors and volunteers, step 5 is not about travel
    travel_answer = if @user_intent_type == "seeking_help"
      @quiz_answers["5"] || @quiz_answers["travel"] || @quiz_answers["transportation"] || @quiz_answers["travel_preference"]
    else
      # For donors and volunteers, travel is not collected in step 5
      @quiz_answers["travel"] || @quiz_answers["transportation"] || @quiz_answers["travel_preference"]
    end

    # Handle array input (convert to string)
    if travel_answer.is_a?(Array)
      travel_answer = travel_answer.first
    end

    case travel_answer&.downcase
    when "walk", "walking", "foot", "near_me"
      "walk"
    when "transit", "public transportation", "bus", "train", "subway"
      "transit"
    when "car", "driving", "drive"
      "car"
    else
      # Default to car if not specified
      "car"
    end
  end

  def extract_causes
    # Extract causes from quiz answers
    causes = []

    # Load the mapping configuration
    config = YAML.load_file(Rails.root.join("config/matching_rules.yml"))
    quiz_mapping = config["quiz_mapping"] || {}

    # Get the appropriate mapping for this user type
    user_type_key = case @user_intent_type
    when "seeking_help"
      "service_seeker"
    when "volunteering"
      "volunteer"
    when "donating"
      "donor"
    else
      "service_seeker"
    end

    mapping = quiz_mapping[user_type_key] || {}

    # For service seekers, causes are selected in step 4
    if @user_intent_type == "seeking_help"
      step_4_causes = @quiz_answers["4"]
      if step_4_causes.is_a?(Array)
        step_4_causes.each do |cause|
          # Use the mapping configuration if available, otherwise fall back to direct mapping
          mapped_cause = mapping[cause] || cause
          causes << mapped_cause if mapped_cause
        end
      end
    elsif @user_intent_type == "volunteering"
      # For volunteers, causes are selected in step 2
      step_2_causes = @quiz_answers["2"]
      if step_2_causes.is_a?(Array)
        step_2_causes.each do |cause|
          mapped_cause = mapping[cause] || cause
          causes << mapped_cause if mapped_cause
        end
      end
    elsif @user_intent_type == "donating"
      # For donors, causes are selected in step 2
      step_2_causes = @quiz_answers["2"]
      if step_2_causes.is_a?(Array)
        step_2_causes.each do |cause|
          mapped_cause = mapping[cause] || cause
          causes << mapped_cause if mapped_cause
        end
      end
    end

    # Remove duplicates and return
    causes.uniq
  end

  def extract_preferences
    # Extract user preferences based on user type
    preferences = []

    case @user_intent_type
    when "seeking_help"
      preferences = extract_seeker_preferences
    when "volunteering"
      preferences = extract_volunteer_preferences
    when "donating"
      preferences = extract_donor_preferences
    end

    # Always add default preferences to ensure UserIntent is valid
    case @user_intent_type
    when "seeking_help"
      preferences << "free_or_sliding" unless preferences.include?("free_or_sliding")
    when "volunteering"
      preferences << "family_friendly" unless preferences.include?("family_friendly")
    when "donating"
      preferences << "children_families" unless preferences.include?("children_families")
    end

    preferences
  end

  def extract_race_ethnicity
    # Extract race/ethnicity from step 11 for service seekers
    if @user_intent_type == "seeking_help"
      race_answer = @quiz_answers["11"]
      return race_answer if race_answer.present?
    end
    nil
  end

  def extract_seeker_preferences
    prefs = []

    # For service seekers, preferences are selected in step 3 (identity) and step 8 (additional preferences)
    # Step 3: Identity preferences
    step_3_identity = @quiz_answers["3"]
    if step_3_identity.present?
      case step_3_identity
      when "student"
        prefs << "student"
      when "veteran_military"
        prefs << "veteran"
      when "caregiver"
        prefs << "caregiver"
      when "lgbtqia"
        prefs << "lgbtqia"
      when "disabilities"
        prefs << "disability"
      when "crisis_hardships"
        prefs << "facing_crisis"
      end
    end

    # Step 8: Additional preferences
    step_8_prefs = @quiz_answers["8"]
    if step_8_prefs.is_a?(Array)
      step_8_prefs.each do |pref|
        case pref
        when "free_services"
          prefs << "free_or_sliding"
        when "no_id"
          prefs << "no_id_required"
        when "lgbtq_affirming"
          prefs << "lgbtq_affirming"
        when "wheelchair"
          prefs << "wheelchair_access"
        when "women_led"
          prefs << "women_bipoc_led"
        when "no_special_needs"
          # If user selects "no_special_needs", don't add any special preferences
          next
        end
      end
    end

    prefs
  end

  def extract_volunteer_preferences
    prefs = []

    @quiz_answers.each do |key, value|
      next if value.blank?

      case key.downcase
      when "work_with_kids", "work_with_seniors"
        prefs << "work_with_kids_seniors" if value == "yes" || value == true
      when "veterans", "military_support"
        prefs << "support_veterans" if value == "yes" || value == true
      when "spanish", "spanish_opportunities"
        prefs << "spanish_opps" if value == "yes" || value == true
      when "grassroots", "bipoc_led"
        prefs << "grassroots_bipoc_led" if value == "yes" || value == true
      when "behind_scenes", "admin", "logistics"
        prefs << "behind_the_scenes" if value == "yes" || value == true
      when "accessible", "wheelchair"
        prefs << "accessible_opps" if value == "yes" || value == true
      when "family_friendly", "group_opportunities"
        prefs << "family_friendly" if value == "yes" || value == true
      end
    end

    prefs
  end

  def extract_donor_preferences
    prefs = []

    @quiz_answers.each do |key, value|
      next if value.blank?

      case key.downcase
      when "seniors", "elderly"
        prefs << "seniors" if value == "yes" || value == true
      when "veterans", "military"
        prefs << "veterans" if value == "yes" || value == true
      when "spanish_speaking", "hispanic"
        prefs << "spanish_speaking" if value == "yes" || value == true
      when "bipoc", "people_of_color"
        prefs << "bipoc" if value == "yes" || value == true
      when "disabilities", "disability"
        prefs << "disabilities" if value == "yes" || value == true
      when "lgbtq", "lgbtqia"
        prefs << "lgbtq" if value == "yes" || value == true
      when "children", "families"
        prefs << "children_families" if value == "yes" || value == true
      end
    end

    prefs
  end

  def extract_language_preference
    # Extract language preference from quiz answers
    # For service seekers, language is selected in step 8 (special needs)
    # For donors and volunteers, language is not collected
    language_answer = if @user_intent_type == "seeking_help"
      # For service seekers, check if spanish_language is selected in step 8
      step_8_answers = @quiz_answers["8"]
      if step_8_answers.is_a?(Array) && step_8_answers.include?("spanish_language")
        "spanish"
      end
    else
      # For donors and volunteers, language is not collected
      @quiz_answers["language"] || @quiz_answers["preferred_language"] || @quiz_answers["language_preference"]
    end

    return nil if language_answer.blank?

    # Handle array input (convert to string)
    if language_answer.is_a?(Array)
      language_answer = language_answer.first
    end

    return nil if language_answer.blank?

    # Normalize language input
    case language_answer.downcase
    when "spanish", "espa\u00F1ol", "espanol"
      "spanish"
    when "english", "en"
      "english"
    else
      language_answer.downcase
    end
  end
end
