# frozen_string_literal: true

# Services and models are now in standard Rails autoloading paths

class SmartMatchController < ApplicationController
  skip_before_action :authenticate_user!
  skip_after_action :verify_policy_scoped
  skip_after_action :verify_authorized

  def index
    # Clear any existing session data when starting fresh
    session.delete(:smart_match_progress)
    session.delete(:smart_match_answers)
    session.delete(:user_intent)

    # Main Smart Match introduction page
    render "smart_match/views/index"
  end

  def quiz
    @current_step = params[:step]&.to_i || 1
    @user_intent = session[:user_intent] || params[:intent] || "seeking_help"

    Rails.logger.debug { "Current Step: #{@current_step}" }
    Rails.logger.debug { "User Intent: #{@user_intent}" }

    # If user is starting fresh (step 1, no answer, no intent param), clear any existing session data
    if @current_step == 1 && params[:answer].blank? && params[:intent].blank?
      session.delete(:smart_match_progress)
      session.delete(:smart_match_answers)
      session.delete(:user_intent)
    end

    # Check if user has already completed the quiz
    # Only redirect to results if user is trying to access step 1 without an intent parameter
    # This allows going back to step 1 when the intent is preserved
    if session[:smart_match_answers]&.keys&.any? && @current_step == 1 && params[:answer].blank? && params[:intent].blank?
      # User has answers but is trying to access step 1 again without intent - redirect to results
      redirect_to smart_match_results_path and return
    end

    # Store user intent from first question
    if @current_step == 1 && params[:answer].present?
      session[:user_intent] = params[:answer]
      @user_intent = params[:answer]
    end

    # Determine total steps based on user intent
    @total_steps = get_total_steps(@user_intent)

    # Store quiz progress in session
    session[:smart_match_progress] ||= {}
    session[:smart_match_answers] ||= {}

    # Handle quiz navigation
    if params[:answer].present?
      Rails.logger.debug { "Processing answer: #{params[:answer]}" }

      # Parse the answer (handle both single and multiple choice)
      answer = params[:answer]
      begin
        # Try to parse as JSON first
        parsed_answer = JSON.parse(answer)
        answer = parsed_answer
      rescue JSON::ParserError
        # If JSON parsing fails, use the raw string (for step 1 answers)
        Rails.logger.debug { "JSON parsing failed, using raw string: #{answer}" }
      end

      Rails.logger.debug { "Parsed answer: #{answer}" }
      Rails.logger.debug { "Current step: #{@current_step}" }
      Rails.logger.debug { "User intent: #{@user_intent}" }

      session[:smart_match_answers][@current_step] = answer

      # Clear any subsequent answers when modifying a previous answer
      # This ensures data consistency when navigating back and changing answers
      session[:smart_match_answers].keys.each do |step_key|
        if step_key.to_f > @current_step.to_f
          session[:smart_match_answers].delete(step_key)
        end
      end

      next_step = get_next_step(@current_step, @user_intent)
      Rails.logger.debug { "Next step calculated: #{next_step}" }

      if next_step
        redirect_url = smart_match_quiz_path(step: next_step, intent: @user_intent)
        Rails.logger.debug { "Redirecting to: #{redirect_url}" }
        redirect_to redirect_url and return
      else
        Rails.logger.debug { "Redirecting to results" }
        redirect_to smart_match_results_path and return
      end
    end

    render "smart_match/views/quiz/quiz"
  end

  def results
    @answers = session[:smart_match_answers] || {}
    @user_intent = session[:user_intent]

    Rails.logger.info "Smart Match Results - User Intent: #{@user_intent}"
    Rails.logger.info "Smart Match Results - Answers: #{@answers}"

    # Check if we have the minimum required data
    if @answers.empty? || @user_intent.blank?
      Rails.logger.warn "Smart Match Results - Missing required data, redirecting to index"
      redirect_to smart_match_index_path and return
    end

    # Generate recommendations based on answers
    begin
      Rails.logger.info "Smart Match Results - Starting recommendation generation..."
      result_data = generate_recommendations(@answers, @user_intent)
      Rails.logger.info "Smart Match Results - Generated result_data: #{result_data.class}"

      # Handle both old array format and new hash format for backward compatibility
      if result_data.is_a?(Array)
        Rails.logger.warn "Smart Match Results - Received array format, converting to hash format"
        @recommendations = result_data
        @threshold_metrics = calculate_threshold_metrics(result_data)
      else
        @recommendations = result_data[:recommendations] || []
        @threshold_metrics = result_data[:threshold_metrics] || {}
      end

      # Ensure we have valid data
      @recommendations = [] unless @recommendations.is_a?(Array)
      @threshold_metrics = {} unless @threshold_metrics.is_a?(Hash)

      Rails.logger.info "Smart Match Results - Final recommendations count: #{@recommendations.length}"
      Rails.logger.info "Smart Match Results - Threshold metrics: #{@threshold_metrics}"
      Rails.logger.info "Smart Match Results - Recommendations data: #{@recommendations.inspect}" if @recommendations.any?
      Rails.logger.info "Smart Match Results - First recommendation: #{@recommendations.first.inspect}" if @recommendations.any?

      # Debug: Check if recommendations have the expected structure
      if @recommendations.any?
        first_rec = @recommendations.first
        Rails.logger.info "Smart Match Results - First recommendation structure:"
        Rails.logger.info "  - Keys: #{first_rec.keys}"
        Rails.logger.info "  - Has location: #{first_rec.key?(:location)}"
        Rails.logger.info "  - Location class: #{first_rec[:location].class}" if first_rec[:location]
        if first_rec[:location]
          Rails.logger.info "  - Location name: #{begin
            first_rec[:location].name
          rescue
            "N/A"
          end}"
        end
      end
    rescue => e
      Rails.logger.error "Smart Match Results - Error generating recommendations: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Set default values on error
      @recommendations = []
      @threshold_metrics = {
        show_warning: true,
        warning_message: "We encountered an error while generating your recommendations. Please try again.",
        average_score: 0.0,
        max_score: 0.0
      }
    end

    # Don't clear session data immediately - let users refresh the page
    # Session data will be cleared when they start over or complete a new quiz
    # session.delete(:smart_match_progress)
    # session.delete(:smart_match_answers)
    # session.delete(:user_intent)

    render "smart_match/views/results/results"
  end

  def current_answers
    # Return current answers from session for AJAX requests
    respond_to do |format|
      format.json do
        render json: {
          answers: session[:smart_match_answers] || {},
          user_intent: session[:user_intent]
        }
      end
    end
  end

  def feedback
    nonprofit_id = params[:nonprofit_id]
    feedback_type = params[:feedback_type]
    session_id = session.id.to_s

    # Validate feedback type
    unless %w[like dislike].include?(feedback_type)
      render json: {error: "Invalid feedback type"}, status: :bad_request
      return
    end

    # Check if feedback already exists
    if RecommendationFeedback.feedback_given?(session_id, nonprofit_id)
      render json: {error: "Feedback already provided for this nonprofit"}, status: :unprocessable_entity
      return
    end

    # Create feedback record
    feedback = RecommendationFeedback.new(
      nonprofit_id: nonprofit_id,
      feedback_type: feedback_type,
      session_id: session_id,
      user: current_user, # Will be nil if user not logged in
      user_answers: session[:smart_match_answers]&.to_json,
      recommendation_data: params[:recommendation_data]&.to_json
    )

    if feedback.save
      render json: {
        success: true,
        message: "Thank you for your feedback!",
        feedback_type: feedback_type
      }
    else
      render json: {error: feedback.errors.full_messages.join(", ")}, status: :unprocessable_entity
    end
  end

  helper_method :get_previous_step, :needs_language_support?, :get_step_sequence, :needs_location_details?

  # Generate recommendations using BGE matrix and methods with fallback
  def generate_recommendations(answers, user_intent)
    Rails.logger.info "Smart Match - Starting recommendation generation"
    Rails.logger.info "Smart Match - Answers: #{answers}"
    Rails.logger.info "Smart Match - User intent: #{user_intent}"

    begin
      # Try the comprehensive recommendation service first (BGE-based)
      Rails.logger.info "Smart Match - Converting quiz answers to UserIntent..."
      converter = QuizToUserIntentConverter.new(answers, user_intent)
      user_intent_obj = converter.convert
      Rails.logger.info "Smart Match - UserIntent: #{user_intent_obj}"
      Rails.logger.info "Smart Match - UserIntent causes: #{user_intent_obj.causes_selected}"
      Rails.logger.info "Smart Match - UserIntent prefs: #{user_intent_obj.prefs_selected}"

      Rails.logger.info "Smart Match - Creating BGE-based comprehensive service instance..."
      recommendation_service = ComprehensiveRecommendationService.new(user_intent_obj)
      Rails.logger.info "Smart Match - BGE service instance created successfully"

      Rails.logger.info "Smart Match - Calling BGE generate_recommendations..."
      recommendations = recommendation_service.generate_recommendations(10)
      Rails.logger.info "Smart Match - BGE service returned #{recommendations.length} recommendations"
      Rails.logger.info "Smart Match - First recommendation: #{recommendations.first}" if recommendations.any?

      # Convert to expected format and calculate threshold metrics
      formatted_recommendations = recommendations.map do |rec|
        # Create a mock Location object using OpenStruct
        location_obj = OpenStruct.new(
          id: rec[:id],
          name: rec[:name],
          organization: OpenStruct.new(
            name: rec[:name],
            website: rec[:url],
            donation_link: nil,
            volunteer_link: nil,
            volunteer_availability?: false,
            decorate: OpenStruct.new(
              donation_link: nil,
              volunteer_link: nil
            )
          ),
          website: rec[:url],
          formatted_address: rec[:city].present? ? "#{rec[:city]}, #{rec[:state]}" : rec[:state],
          city: rec[:city],
          state: rec[:state],
          # Add missing properties that the template expects
          donation_link: nil,
          volunteer_link: nil,
          volunteer_availability?: false
        )

        {
          location: location_obj,
          similarity_score: rec[:score] || rec[:final_score] || 0.0,
          relevance_reason: rec[:relevance_reason] || "General match"
        }
      end

      # Calculate threshold metrics
      threshold_metrics = calculate_threshold_metrics(formatted_recommendations)

      Rails.logger.info "Smart Match - Formatted recommendations: #{formatted_recommendations.length}"
      Rails.logger.info "Smart Match - Threshold metrics: #{threshold_metrics}"
      Rails.logger.info "Smart Match - First formatted recommendation: #{formatted_recommendations.first}" if formatted_recommendations.any?

      # Return both recommendations and threshold info
      {
        recommendations: formatted_recommendations,
        threshold_metrics: threshold_metrics
      }
    rescue => e
      Rails.logger.error "Smart Match comprehensive service failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Return empty results with warning
      {
        recommendations: [],
        threshold_metrics: {
          show_warning: true,
          warning_message: "We're experiencing technical difficulties. Please try again or contact support.",
          average_score: 0.0,
          max_score: 0.0
        }
      }
    end
  end

  private

  def calculate_threshold_metrics(recommendations)
    return {show_warning: false, average_score: 0.0, max_score: 0.0} if recommendations.empty?

    # Filter out nil scores and ensure we have valid numeric scores
    scores = recommendations.pluck(:similarity_score).compact.select { |score| score.is_a?(Numeric) }

    if scores.empty?
      return {
        show_warning: true,
        warning_level: "no_scores",
        warning_message: "We couldn't calculate match scores for the recommendations.",
        average_score: 0.0,
        max_score: 0.0,
        strong_match_threshold: 0.7,
        moderate_match_threshold: 0.4,
        weak_match_threshold: 0.2
      }
    end

    average_score = scores.sum / scores.length
    max_score = scores.max

    # Define thresholds
    strong_match_threshold = 0.7  # 70% - strong matches
    moderate_match_threshold = 0.4  # 40% - moderate matches
    weak_match_threshold = 0.2   # 20% - weak matches

    # Determine warning level
    if max_score >= strong_match_threshold
      show_warning = false
      warning_level = "none"
      warning_message = nil
    elsif max_score >= moderate_match_threshold
      show_warning = true
      warning_level = "moderate"
      warning_message = "We found some relevant nonprofits, but they may not perfectly match your specific needs. These organizations could still be helpful for your situation."
    elsif max_score >= weak_match_threshold
      show_warning = true
      warning_level = "weak"
      warning_message = "We found limited matches for your specific needs. The organizations below may not be exactly what you're looking for, but they could still provide useful services or referrals."
    else
      show_warning = true
      warning_level = "very_weak"
      warning_message = "We couldn't find nonprofits that closely match your specific needs. The organizations below are general recommendations that might still be helpful, or you may want to contact them for referrals to more specialized services."
    end

    {
      show_warning: show_warning,
      warning_level: warning_level,
      warning_message: warning_message,
      average_score: average_score,
      max_score: max_score,
      strong_match_threshold: strong_match_threshold,
      moderate_match_threshold: moderate_match_threshold,
      weak_match_threshold: weak_match_threshold
    }
  end

  def get_total_steps(user_intent)
    case user_intent
    when "seeking_help"
      # Service Seeker path has 12 total steps (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
      12
    when "donating"
      # Donor path has 11 total steps (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
      11
    when "volunteering"
      # Volunteer path has 10 total steps (1, 2, 3, 4, 5*, 6, 7, 8, 9, 10)
      base_steps = 10
      if needs_location_details?
        base_steps # Include location step
      else
        base_steps - 1 # Skip location step
      end
    else
      1 # Default to first question
    end
  end

  def get_next_step(current_step, user_intent)
    case user_intent
    when "seeking_help"
      get_service_seeker_next_step(current_step)
    when "donating"
      get_donor_next_step(current_step)
    when "volunteering"
      get_volunteer_next_step(current_step)
    else
      # Step 1 is the universal branch - no specific path yet
      current_step + 1
    end
  end

  def get_service_seeker_next_step(current_step)
    case current_step
    when 1
      2 # Who are you filling this out for?
    when 2
      3 # What best describes you?
    when 3
      4 # What type of help are you looking for?
    when 4
      5 # What best describes your situation?
    when 5
      6 # Which area are you located at?
    when 6
      7 # How far can you travel?
    when 7
      8 # Do you need any of the following?
    when 8
      9 # Age range (language selection is handled within step 8)
    when 9
      10 # Gender identity
    when 10
      11 # Race or ethnicity
    when 11
      nil # End of quiz - redirect to results
    when 12
      nil # End of quiz
    end
  end

  def get_previous_step(current_step, user_intent)
    case user_intent
    when "seeking_help"
      get_service_seeker_previous_step(current_step)
    when "donating"
      get_donor_previous_step(current_step)
    when "volunteering"
      get_volunteer_previous_step(current_step)
    else
      [current_step - 1, 1].max
    end
  end

  def get_service_seeker_previous_step(current_step)
    case current_step
    when 2
      1
    when 3
      2
    when 4
      3
    when 5
      4
    when 6
      5
    when 7
      6
    when 8
      7
    when 9
      8
    when 10
      9
    when 11
      10
    when 12
      11
    else
      [current_step - 1, 1].max
    end
  end

  def get_donor_previous_step(current_step)
    case current_step
    when 2
      1
    when 3
      2
    when 4
      3
    when 5
      4
    when 6
      5
    when 7
      6
    when 8
      7
    when 9
      8
    when 10
      9
    when 11
      10
    else
      [current_step - 1, 1].max
    end
  end

  def get_volunteer_previous_step(current_step)
    case current_step
    when 2
      1
    when 3
      2
    when 4
      3
    when 5
      4
    when 6
      # Check if user came from location step or skipped it
      if needs_location_details?
        5
      else
        4
      end
    when 7
      6
    when 8
      7
    when 9
      8
    else
      [current_step - 1, 1].max
    end
  end

  def needs_language_support?
    # Check if user selected "Spanish or another language available" in step 8
    return false unless session[:smart_match_answers]
    step_8_answers = session[:smart_match_answers][8]
    return false unless step_8_answers

    # Handle both array and string formats
    if step_8_answers.is_a?(Array)
      step_8_answers.include?("spanish_language")
    else
      step_8_answers == "spanish_language"
    end
  end

  def get_step_sequence(user_intent)
    # Return the sequence of steps based on user intent
    case user_intent
    when "seeking_help"
      # Service Seeker path - 12 steps
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    when "volunteering"
      # Volunteer path - 10 steps
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    when "donating"
      # Donor path - 10 steps
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    else
      [1]
    end
  end

  def needs_location_details?
    # Check if user selected "Near me" or "Specific city or zip code" in step 5 (volunteer path)
    return false unless session[:smart_match_answers]
    step_5_answers = session[:smart_match_answers][5]
    return false unless step_5_answers

    # Step 5 is single choice
    step_5_answers == "near_me" || step_5_answers == "specific_location"
  end

  def get_donor_next_step(current_step)
    case current_step
    when 1
      2 # Donor path starts at step 2
    when 2
      3 # What causes are you passionate about?
    when 3
      4 # How much would you like to donate?
    when 4
      5 # Do you prefer one-time or recurring donations?
    when 5
      6 # What type of impact are you looking for?
    when 6
      7 # Do you want to support local or national organizations?
    when 7
      8 # Do you prefer to donate to specific programs or general operations?
    when 8
      9 # Do you want to receive updates about your donation?
    when 9
      10 # Age range
    when 10
      nil # End of quiz - redirect to results (after race/ethnicity)
    when 11
      nil # End of quiz
    end
  end

  def get_volunteer_next_step(current_step)
    case current_step
    when 1
      2 # What causes are close to your heart?
    when 2
      3 # How would you like to help?
    when 3
      4 # Volunteer preferences
    when 4
      5 # Where do you want to focus your impact?
    when 5
      if needs_location_details?
      end
      6
    when 6
      7 # How much time do you have to give?
    when 7
      8 # Age range
    when 8
      9 # Gender identity
    when 9
      10 # Race or ethnicity
    when 10
      nil # End of quiz - redirect to results
    end
  end

  def generate_fallback_recommendations(answers, user_intent)
    # Fallback to the original filtering logic
    search = Search.new(location_params)
    search.save

    results = search.results.limit(20)

    # Apply filters based on user intent and answers
    case user_intent
    when "seeking_help"
      results = filter_for_service_seeker(results, answers)
    when "donating"
      results = filter_for_donor(results, answers)
    when "volunteering"
      results = filter_for_volunteer(results, answers)
    end

    # Convert to the same format as the new service
    results.map do |location|
      {
        location: location,
        similarity_score: 0.5, # Default fallback score
        relevance_reason: "Based on your search criteria and location preferences"
      }
    end
  end

  def filter_for_service_seeker(results, answers)
    # Filter based on service seeker answers
    if answers[4].present? # Type of help needed
      case answers[4]
      when "food_groceries"
        results = results.joins(:services).where(services: {name: ["Food Assistance", "Meal Programs", "Food Pantry"]})
      when "housing_shelter"
        results = results.joins(:services).where(services: {name: ["Housing Assistance", "Emergency Shelter", "Transitional Housing"]})
      when "mental_health"
        results = results.joins(:services).where(services: {name: ["Mental Health Services", "Counseling", "Therapy"]})
      when "medical_healthcare"
        results = results.joins(:services).where(services: {name: ["Medical Care", "Health Services", "Dental Care"]})
      when "employment_training"
        results = results.joins(:services).where(services: {name: ["Job Training", "Employment Services", "Career Counseling"]})
      when "legal_help"
        results = results.joins(:services).where(services: {name: ["Legal Services", "Legal Aid", "Legal Consultation"]})
      when "financial_assistance"
        results = results.joins(:services).where(services: {name: ["Financial Assistance", "Emergency Financial Aid", "Utility Assistance"]})
      end
    end

    # Filter by location preference
    if answers[6].present? # Location
      case answers[6]
      when "atlantic_city"
        results = results.where(city: "Atlantic City")
      when "los_angeles"
        results = results.where(city: "Los Angeles")
      when "nashville"
        results = results.where(city: "Nashville")
      end
    end

    # Filter by travel distance
    if answers[7].present? # Travel distance
      case answers[7]
      when "walking_distance"
        # Filter for locations within 5 miles
        results = results.near([@current_location[:latitude], @current_location[:longitude]], 5)
      when "public_transport"
        # Filter for locations within 10 miles
        results = results.near([@current_location[:latitude], @current_location[:longitude]], 10)
      when "car_access"
        # No distance filter for car access
      end
    end

    # Filter by special requirements
    if answers[8].present? && answers[8].is_a?(Array)
      answers[8].each do |requirement|
        case requirement
        when "free_sliding_scale"
          # Filter for organizations offering free or sliding scale services
          results = results.joins(:organization).where(organizations: {offers_free_services: true})
        when "no_id_required"
          # Filter for organizations that don't require ID
          results = results.joins(:organization).where(organizations: {requires_id: false})
        when "spanish_language"
          # Filter for organizations offering Spanish services
          results = results.joins(:organization).where(organizations: {offers_spanish: true})
        when "lgbtqia_affirming"
          # Filter for LGBTQIA+ affirming organizations
          results = results.joins(:organization).where(organizations: {lgbtqia_affirming: true})
        when "wheelchair_accessible"
          # Filter for wheelchair accessible locations
          results = results.where(wheelchair_accessible: true)
        when "women_bipoc_led"
          # Filter for women or BIPOC-led organizations
          results = results.joins(:organization).where(organizations: {women_or_bipoc_led: true})
        end
      end
    end

    results
  end

  def filter_for_donor(results, answers)
    # To be implemented for donor filtering
    results
  end

  def filter_for_volunteer(results, answers)
    # Filter based on volunteer answers

    # Filter by causes they care about
    if answers[2].present? && answers[2].is_a?(Array)
      answers[2].each do |cause|
        case cause
        when "food_groceries"
          results = results.joins(:services).where(services: {name: ["Food Assistance", "Meal Programs", "Food Pantry"]})
        when "housing_shelter"
          results = results.joins(:services).where(services: {name: ["Housing Assistance", "Emergency Shelter", "Transitional Housing"]})
        when "mental_health"
          results = results.joins(:services).where(services: {name: ["Mental Health Services", "Counseling", "Therapy"]})
        when "medical_healthcare"
          results = results.joins(:services).where(services: {name: ["Medical Care", "Health Services", "Dental Care"]})
        when "employment_training"
          results = results.joins(:services).where(services: {name: ["Job Training", "Employment Services", "Career Counseling"]})
        when "legal_help"
          results = results.joins(:services).where(services: {name: ["Legal Services", "Legal Aid", "Legal Consultation"]})
        when "financial_assistance"
          results = results.joins(:services).where(services: {name: ["Financial Assistance", "Emergency Financial Aid", "Utility Assistance"]})
        end
      end
    end

    # Filter by location preference
    if answers[4].present?
      case answers[4]
      when "near_me"
        # Filter for locations near user
        results = results.near([@current_location[:latitude], @current_location[:longitude]], 25)
      when "specific_city_zip"
        # Filter by specific city (handled in step 5)
        if answers[5].present?
          case answers[5]
          when "atlantic_city"
            results = results.where(city: "Atlantic City")
          when "los_angeles"
            results = results.where(city: "Los Angeles")
          when "nashville"
            results = results.where(city: "Nashville")
          end
        end
      when "anywhere_virtual"
        # No location filter for virtual opportunities
      end
    end

    # Filter by in-person/remote preference
    if answers[6].present?
      case answers[6]
      when "only_in_person"
        # Filter for in-person opportunities only
        results = results.where(remote_opportunities: false)
      when "only_remote"
        # Filter for remote opportunities only
        results = results.where(remote_opportunities: true)
      when "both"
        # No filter - show both
      end
    end

    # Filter by time commitment
    if answers[7].present? && answers[7].is_a?(Array)
      answers[7].each do |time_commitment|
        case time_commitment
        when "time_0"
          # One-time events
          results = results.joins(:organization).where(organizations: {offers_one_time_events: true})
        when "time_1"
          # Few hours a week
          results = results.joins(:organization).where(organizations: {offers_weekly_opportunities: true})
        when "time_2"
          # Ongoing role
          results = results.joins(:organization).where(organizations: {offers_ongoing_roles: true})
        end
      end
    end

    results
  end

  def location_params
    {
      city: @current_location[:city],
      state: @current_location[:state],
      lat: @current_location[:latitude],
      lon: @current_location[:longitude]
    }
  end
end
