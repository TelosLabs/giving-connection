# Comprehensive Recommendation Service
# Implements the full workflow with BGE embeddings, deterministic filtering, and configurable scoring
class ComprehensiveRecommendationService
  include Math

  def initialize(user_intent)
    @user_intent = user_intent
    @config = load_config
    @city_centroids = load_city_centroids
    @matrix_data = load_matrix_data
    @chunk_embeddings = load_chunk_embeddings
  end

  def generate_recommendations(limit = 10)
    Rails.logger.info "Comprehensive Recommendation Service - Starting for #{@user_intent}"

    # Step 1: Basic validation (skip for OpenStruct)
    return [] unless @user_intent.respond_to?(:causes_selected) && @user_intent.causes_selected.any?

    # Step 2: Apply deterministic filters
    candidates = apply_deterministic_filters
    Rails.logger.info "Comprehensive Recommendation Service - Found #{candidates.length} candidates after filtering"

    return [] if candidates.empty?

    # Step 3: Build query text for BGE
    query_text = build_query_text
    Rails.logger.info "Comprehensive Recommendation Service - Query text: #{query_text}"

    # Step 4: Generate query embedding
    query_embedding = generate_query_embedding(query_text)
    return [] unless query_embedding

    # Step 5: Calculate scores for all candidates
    scored_candidates = calculate_scores(candidates, query_embedding)
    Rails.logger.info "Comprehensive Recommendation Service - Scored #{scored_candidates.length} candidates"

    # Step 6: Sort and limit results
    recommendations = scored_candidates
      .sort_by { |c| -c[:final_score] }
      .first(limit)
      .map { |c| build_recommendation(c) }

    Rails.logger.info "Comprehensive Recommendation Service - Generated #{recommendations.length} recommendations"
    recommendations
  end

  private

  def load_config
    YAML.load_file(Rails.root.join("config/matching_rules.yml"))
  end

  def load_city_centroids
    YAML.load_file(Rails.root.join("config/city_centroids.yml"))
  end

  def load_matrix_data
    # Load enhanced BGE matrix (new comprehensive matrix with all 928 nonprofits)
    enhanced_bge_matrix_path = Rails.root.join("app/views/smart_match/data/enhanced_bge_nonprofits_matrix.json")
    if File.exist?(enhanced_bge_matrix_path)
      @enhanced_matrix = JSON.parse(File.read(enhanced_bge_matrix_path))
      Rails.logger.info "Comprehensive Recommendation Service - Loaded enhanced BGE matrix (#{@enhanced_matrix["nonprofits"].size} nonprofits)"
      return @enhanced_matrix
    end

    # Fallback to old matrices if enhanced BGE matrix doesn't exist
    Rails.logger.warn "Comprehensive Recommendation Service - Enhanced BGE matrix not found, falling back to old matrices"

    # Load BGE matrix for embeddings
    bge_matrix_path = Rails.root.join("app/views/smart_match/data/bge_nonprofits_matrix.json")
    return nil unless File.exist?(bge_matrix_path)

    @bge_matrix = JSON.parse(File.read(bge_matrix_path))

    # Load enhanced matrix for location data
    enhanced_matrix_path = Rails.root.join("app/views/smart_match/data/enhanced_nonprofits_matrix.json")
    if File.exist?(enhanced_matrix_path)
      @enhanced_matrix = JSON.parse(File.read(enhanced_matrix_path))

      # Create a mapping from BGE nonprofit names to enhanced data
      @enhanced_lookup = {}
      @enhanced_matrix["nonprofits"].each do |np|
        @enhanced_lookup[np["name"]] = np
      end

      Rails.logger.info "Comprehensive Recommendation Service - Loaded BGE matrix (#{@bge_matrix["nonprofits"].size} nonprofits) and enhanced matrix (#{@enhanced_matrix["nonprofits"].size} nonprofits)"
    else
      Rails.logger.warn "Comprehensive Recommendation Service - Enhanced matrix not found, using BGE matrix only"
    end

    @bge_matrix
  end

  def load_chunk_embeddings
    # For now, we'll use the existing matrix structure
    # In a full implementation, this would load from a separate chunk embeddings table
    @matrix_data
  end

  def apply_deterministic_filters
    # Use the enhanced BGE matrix as primary data source
    if @enhanced_matrix
      candidates = @enhanced_matrix["nonprofits"] || []
      Rails.logger.info "Comprehensive Recommendation Service - Using enhanced BGE matrix with #{candidates.length} nonprofits"

      # Step 1: State filter
      candidates = candidates.select do |np|
        np["state"] == @user_intent.user_state
      end
      Rails.logger.info "Comprehensive Recommendation Service - After state filter: #{candidates.length}"

      # Step 2: Distance filter (only if coordinates are available)
      has_coordinates = candidates.any? { |np| np["lat"] && np["lng"] }

      if has_coordinates
        user_coords = get_user_coordinates
        return [] unless user_coords

        radius_miles = @config["radius_miles_by_bucket"][@user_intent.travel_bucket]
        candidates = filter_by_distance_enhanced(candidates, user_coords, radius_miles)
        Rails.logger.info "Comprehensive Recommendation Service - After distance filter: #{candidates.length}"

        # If no candidates, try progressive radius expansion
        if candidates.empty?
          candidates = expand_radius_progressively_enhanced(user_coords)
          Rails.logger.info "Comprehensive Recommendation Service - After radius expansion: #{candidates.length}"
        end
      else
        Rails.logger.info "Comprehensive Recommendation Service - No coordinates available, skipping distance filter"
      end

      return candidates
    end

    # Fallback to old method if enhanced matrix not available
    Rails.logger.warn "Comprehensive Recommendation Service - Enhanced matrix not available, falling back to old method"
    return [] unless @bge_matrix

    candidates = @bge_matrix["nonprofits"] || []

    # Use enhanced lookup to get location data
    if @enhanced_lookup
      # Step 1: State filter using enhanced data
      candidates = candidates.select do |np|
        enhanced_data = @enhanced_lookup[np["name"]]
        enhanced_data && enhanced_data["state"] == @user_intent.user_state
      end
      Rails.logger.info "Comprehensive Recommendation Service - After state filter: #{candidates.length}"

      # Step 2: Distance filter (only if coordinates are available in enhanced data)
      has_coordinates = candidates.any? do |np|
        enhanced_data = @enhanced_lookup[np["name"]]
        enhanced_data && enhanced_data["lat"] && enhanced_data["lng"]
      end

      if has_coordinates
        user_coords = get_user_coordinates
        return [] unless user_coords

        radius_miles = @config["radius_miles_by_bucket"][@user_intent.travel_bucket]
        candidates = filter_by_distance_with_enhanced(candidates, user_coords, radius_miles)
        Rails.logger.info "Comprehensive Recommendation Service - After distance filter: #{candidates.length}"

        # If no candidates, try progressive radius expansion
        if candidates.empty?
          candidates = expand_radius_progressively_with_enhanced(user_coords)
          Rails.logger.info "Comprehensive Recommendation Service - After radius expansion: #{candidates.length}"
        end
      else
        Rails.logger.info "Comprehensive Recommendation Service - No coordinates available, skipping distance filter"
      end
    else
      Rails.logger.info "Comprehensive Recommendation Service - No enhanced data available, using all candidates"
    end

    candidates
  end

  def get_user_coordinates
    city = @user_intent.user_city
    state = @user_intent.user_state

    # Try main city centroids first
    if @city_centroids["city_centroids"][city]&.[](state)
      return @city_centroids["city_centroids"][city][state]
    end

    # Try additional cities
    if @city_centroids["additional_cities"][city]&.[](state)
      return @city_centroids["additional_cities"][city][state]
    end

    Rails.logger.warn "Comprehensive Recommendation Service - No coordinates found for #{city}, #{state}"
    nil
  end

  def filter_by_distance(candidates, user_coords, radius_miles)
    user_lat, user_lng = user_coords

    candidates.select do |np|
      next false unless np["lat"] && np["lng"]

      distance = haversine_distance(user_lat, user_lng, np["lat"], np["lng"])
      distance <= radius_miles
    end
  end

  def filter_by_distance_enhanced(candidates, user_coords, radius_miles)
    user_lat, user_lng = user_coords

    candidates.select do |np|
      next false unless np["lat"] && np["lng"]

      distance = haversine_distance(user_lat, user_lng, np["lat"], np["lng"])
      distance <= radius_miles
    end
  end

  def filter_by_distance_with_enhanced(candidates, user_coords, radius_miles)
    user_lat, user_lng = user_coords

    candidates.select do |np|
      enhanced_data = @enhanced_lookup[np["name"]]
      next false unless enhanced_data && enhanced_data["lat"] && enhanced_data["lng"]

      distance = haversine_distance(user_lat, user_lng, enhanced_data["lat"], enhanced_data["lng"])
      distance <= radius_miles
    end
  end

  def expand_radius_progressively(user_coords)
    candidates = []
    user_lat, user_lng = user_coords

    # Progressive radius expansion: 5 → 10 → 25 → 50 miles
    [5, 10, 25, 50].each do |radius|
      candidates = @matrix_data["nonprofits"].select do |np|
        np["state"] == @user_intent.user_state &&
          np["lat"] && np["lng"] &&
          haversine_distance(user_lat, user_lng, np["lat"], np["lng"]) <= radius
      end

      break if candidates.any?
    end

    candidates
  end

  def expand_radius_progressively_enhanced(user_coords)
    candidates = []
    user_lat, user_lng = user_coords

    # Progressive radius expansion: 5 → 10 → 25 → 50 miles
    [5, 10, 25, 50].each do |radius|
      candidates = @enhanced_matrix["nonprofits"].select do |np|
        np["state"] == @user_intent.user_state &&
          np["lat"] && np["lng"] &&
          haversine_distance(user_lat, user_lng, np["lat"], np["lng"]) <= radius
      end

      break if candidates.any?
    end

    candidates
  end

  def expand_radius_progressively_with_enhanced(user_coords)
    candidates = []
    user_lat, user_lng = user_coords

    # Progressive radius expansion: 5 → 10 → 25 → 50 miles
    [5, 10, 25, 50].each do |radius|
      candidates = @bge_matrix["nonprofits"].select do |np|
        enhanced_data = @enhanced_lookup[np["name"]]
        enhanced_data &&
          enhanced_data["state"] == @user_intent.user_state &&
          enhanced_data["lat"] && enhanced_data["lng"] &&
          haversine_distance(user_lat, user_lng, enhanced_data["lat"], enhanced_data["lng"]) <= radius
      end

      break if candidates.any?
    end

    candidates
  end

  def haversine_distance(lat1, lng1, lat2, lng2)
    # Convert to radians
    lat1_rad = lat1 * PI / 180
    lng1_rad = lng1 * PI / 180
    lat2_rad = lat2 * PI / 180
    lng2_rad = lng2 * PI / 180

    # Haversine formula
    dlat = lat2_rad - lat1_rad
    dlng = lng2_rad - lng1_rad
    a = sin(dlat / 2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlng / 2)**2
    c = 2 * asin(sqrt(a))

    # Earth radius in miles
    earth_radius = 3959
    earth_radius * c
  end

  def build_query_text
    parts = []

    # Add cause synonyms
    @user_intent.causes_selected.each do |cause|
      if @config["causes"][cause]&.[]("synonyms")
        parts << @config["causes"][cause]["synonyms"].join(" ")
      end
    end

    # Add language preference
    if @user_intent.has_language_preference?
      parts << @user_intent.language_preference
    end

    # Add accessibility preferences
    if @user_intent.prefs_selected.include?("wheelchair_access")
      parts << "wheelchair accessible"
    end

    # Add caregiver support
    if @user_intent.prefs_selected.include?("caregiver")
      parts << "caregiver support"
    end

    # Add location context
    parts << "#{@user_intent.user_city} #{@user_intent.user_state}"

    query_text = parts.join("; ")

    # Debug logging
    Rails.logger.info "Comprehensive Recommendation Service - Query text: #{query_text}"
    Rails.logger.info "Comprehensive Recommendation Service - User intent causes: #{@user_intent.causes_selected}"
    Rails.logger.info "Comprehensive Recommendation Service - User location: #{@user_intent.user_city}, #{@user_intent.user_state}"

    query_text
  end

  def generate_query_embedding(query_text)
    script_path = Rails.root.join("app/views/smart_match/scripts/generate_user_embedding.py")

    begin
      # Use Open3 for better command execution
      require "open3"

      # Use array format to avoid shell escaping issues
      cmd_array = ["conda", "run", "-n", "bge_env", "python", script_path.to_s, query_text, "BAAI/bge-large-en-v1.5"]

      stdout, stderr, status = Open3.capture3(*cmd_array)

      if status.success?
        response = JSON.parse(stdout)
        response["embedding"]
      else
        Rails.logger.error "Comprehensive Recommendation Service - Failed to generate query embedding: #{stderr}"
        Rails.logger.error "Comprehensive Recommendation Service - Falling back to simple embedding"
        # Return a simple fallback embedding (all zeros) to avoid complete failure
        Array.new(1024, 0.0)
      end
    rescue => e
      Rails.logger.error "Comprehensive Recommendation Service - Error generating query embedding: #{e.message}"
      Rails.logger.error "Comprehensive Recommendation Service - Falling back to simple embedding"
      # Return a simple fallback embedding (all zeros) to avoid complete failure
      Array.new(1024, 0.0)
    end
  end

  def calculate_scores(candidates, query_embedding)
    candidates.map do |candidate|
      # Calculate dense similarity (using existing embedding for now)
      dense_similarity = calculate_dense_similarity(candidate, query_embedding)

      # Calculate attribute bonus
      attribute_bonus = calculate_attribute_bonus(candidate)

      # Calculate distance score
      distance_score = calculate_distance_score(candidate)

      # Calculate final score
      final_score = calculate_final_score(dense_similarity, attribute_bonus, distance_score)

      {
        candidate: candidate,
        dense_similarity: dense_similarity,
        attribute_bonus: attribute_bonus,
        distance_score: distance_score,
        final_score: final_score
      }
    end
  end

  def calculate_dense_similarity(candidate, query_embedding)
    # Check if candidate has embedding (from BGE matrix)
    unless candidate["embedding"]
      # If no embedding, calculate similarity based on semantic content
      return calculate_text_based_similarity(candidate, query_embedding)
    end

    # Check if we have a fallback embedding (all zeros)
    if query_embedding.all? { |x| x == 0.0 }
      Rails.logger.info "Comprehensive Recommendation Service - Using fallback similarity calculation"
      return 0.5
    end

    # Enhanced BGE embedding similarity calculation
    candidate_emb = candidate["embedding"]
    return 0.5 unless candidate_emb.length == query_embedding.length

    # Calculate cosine similarity
    dot_product = candidate_emb.zip(query_embedding).sum { |a, b| a * b }
    magnitude_a = sqrt(candidate_emb.sum { |x| x**2 })
    magnitude_b = sqrt(query_embedding.sum { |x| x**2 })

    return 0.5 if magnitude_a == 0 || magnitude_b == 0

    raw_similarity = dot_product / (magnitude_a * magnitude_b)

    # Debug logging for education-related organizations
    if candidate["name"]&.downcase&.include?("education") || candidate["causes"]&.downcase&.include?("education")
      Rails.logger.info "Comprehensive Recommendation Service - Education org similarity: #{candidate["name"]} - Raw: #{raw_similarity.round(3)}"
    end

    # Apply content-based boost for nonprofits with rich descriptions
    content_boost = calculate_content_boost(candidate)
    boosted_similarity = raw_similarity * (1.0 + content_boost)

    # Check if normalization is enabled
    behavior_config = @config["scoring_behavior"] || {}
    enable_normalization = behavior_config["enable_normalization"] != false
    enable_sigmoid = behavior_config["enable_sigmoid_transformation"] != false
    min_sim = behavior_config["similarity_min"] || 0.1
    max_sim = behavior_config["similarity_max"] || 0.95

    if enable_normalization && enable_sigmoid
      # Normalize similarity to prevent extreme values
      # Apply sigmoid-like transformation to smooth out extreme values
      # Use a less aggressive sigmoid to preserve higher scores
      normalized_similarity = 1.0 / (1.0 + Math.exp(-3.0 * (boosted_similarity - 0.3)))

      # Clamp to reasonable range to prevent 100% or 0% scores
      final_similarity = normalized_similarity.clamp(min_sim, max_sim)

      # Log significant transformations for monitoring
      if (raw_similarity - final_similarity).abs > 0.1
        Rails.logger.info "Comprehensive Recommendation Service - Similarity transformed: #{raw_similarity.round(3)} -> #{final_similarity.round(3)} (boost: #{content_boost.round(3)}) for #{candidate["name"]}"
      end

      final_similarity
    else
      # Return boosted similarity without normalization
      [boosted_similarity, 1.0].min
    end
  end

  def calculate_content_boost(candidate)
    # Calculate a boost based on the richness of the nonprofit's content
    # This rewards nonprofits with detailed descriptions, even if cause labels are missing
    boost = 0.0

    # Boost for detailed mission/vision/services
    if candidate["mission_vision_services"]
      content_length = candidate["mission_vision_services"].length
      if content_length > 500
        boost += 0.1  # 10% boost for very detailed descriptions
      elsif content_length > 200
        boost += 0.05  # 5% boost for moderately detailed descriptions
      end
    end

    # Boost for multiple causes (indicates comprehensive services)
    if candidate["causes"]
      cause_count = candidate["causes"].split(",").length
      if cause_count > 3
        boost += 0.05  # 5% boost for NGOs with many causes
      elsif cause_count > 1
        boost += 0.02  # 2% boost for NGOs with multiple causes
      end
    end

    # Boost for having complete information
    if candidate["name"] && candidate["city"] && candidate["state"] && candidate["mission_vision_services"]
      boost += 0.03  # 3% boost for complete profiles
    end

    # Cap the total boost at 20%
    [boost, 0.2].min
  end

  def calculate_text_based_similarity(candidate, query_embedding)
    # For nonprofits without BGE embeddings, calculate similarity based on semantic content

    # Load CSV to quiz mapping
    csv_to_quiz_mapping = @config["csv_to_quiz_mapping"] || {}

    # Build comprehensive text representation of the candidate
    candidate_text_parts = []

    # Add organization name
    candidate_text_parts << candidate["name"] if candidate["name"]

    # Add causes (but with lower weight since we want to rely more on content)
    if candidate["causes"]
      candidate_causes_raw = candidate["causes"].split(",").map(&:strip)
      candidate_causes = candidate_causes_raw.map do |cause|
        csv_to_quiz_mapping[cause] || cause.downcase
      end
      candidate_text_parts << candidate_causes.join(" ")
    end

    # Add mission/vision/services (most important for semantic matching)
    if candidate["mission_vision_services"]
      candidate_text_parts << candidate["mission_vision_services"]
    end

    # Add location context
    if candidate["city"] && candidate["state"]
      candidate_text_parts << "#{candidate["city"]} #{candidate["state"]}"
    end

    candidate_text = candidate_text_parts.join(" ").downcase

    # Build user query text (same as in build_query_text method)
    user_query_parts = []

    # Add cause synonyms
    @user_intent.causes_selected.each do |cause|
      if @config["causes"][cause]&.[]("synonyms")
        user_query_parts << @config["causes"][cause]["synonyms"].join(" ")
      end
    end

    # Add language preference
    if @user_intent.has_language_preference?
      user_query_parts << @user_intent.language_preference
    end

    # Add accessibility preferences
    if @user_intent.prefs_selected.include?("wheelchair_access")
      user_query_parts << "wheelchair accessible"
    end

    # Add caregiver support
    if @user_intent.prefs_selected.include?("caregiver")
      user_query_parts << "caregiver support"
    end

    # Add location context
    user_query_parts << "#{@user_intent.user_city} #{@user_intent.user_state}"

    user_query_text = user_query_parts.join(" ").downcase

    # Calculate semantic similarity using keyword matching and content analysis
    similarity_score = calculate_semantic_similarity(candidate_text, user_query_text)

    # Apply normalization to prevent extreme values
    behavior_config = @config["scoring_behavior"] || {}
    enable_normalization = behavior_config["enable_normalization"] != false
    enable_sigmoid = behavior_config["enable_sigmoid_transformation"] != false
    min_sim = behavior_config["similarity_min"] || 0.1
    max_sim = behavior_config["similarity_max"] || 0.95

    if enable_normalization && enable_sigmoid
      normalized_similarity = 1.0 / (1.0 + Math.exp(-3.0 * (similarity_score - 0.3)))
      final_similarity = normalized_similarity.clamp(min_sim, max_sim)

      Rails.logger.info "Comprehensive Recommendation Service - Text-based similarity: #{similarity_score.round(3)} -> #{final_similarity.round(3)} for #{candidate["name"]}"
      final_similarity
    else
      [similarity_score, 1.0].min
    end
  end

  def calculate_semantic_similarity(candidate_text, user_query_text)
    # Enhanced semantic similarity calculation that relies more on content than exact matches
    similarity = 0.0

    # Split into words and create sets
    candidate_words = candidate_text.split(/\s+/).to_set
    user_words = user_query_text.split(/\s+/).to_set

    # Calculate word overlap (Jaccard similarity)
    intersection = candidate_words & user_words
    union = candidate_words | user_words

    if union.size > 0
      word_similarity = intersection.size.to_f / union.size
      similarity += word_similarity * 0.4  # 40% weight for word overlap
    end

    # Calculate phrase matching (for multi-word concepts)
    user_phrases = extract_meaningful_phrases(user_query_text)
    candidate_phrases = extract_meaningful_phrases(candidate_text)

    phrase_matches = 0
    total_phrases = user_phrases.size

    user_phrases.each do |phrase|
      if candidate_phrases.any? { |cp| cp.include?(phrase) || phrase.include?(cp) }
        phrase_matches += 1
      end
    end

    if total_phrases > 0
      phrase_similarity = phrase_matches.to_f / total_phrases
      similarity += phrase_similarity * 0.6  # 60% weight for phrase matching
    end

    similarity
  end

  def extract_meaningful_phrases(text)
    # Extract meaningful phrases (2-4 word combinations) from text
    words = text.split(/\s+/)
    phrases = []

    # Extract 2-4 word phrases
    (2..4).each do |length|
      (0..words.length - length).each do |start|
        phrase = words[start, length].join(" ")
        # Only include phrases that are meaningful (not just common words)
        if phrase.length > 3 && !phrase.match?(/^(the|and|or|but|in|on|at|to|for|of|with|by)$/i)
          phrases << phrase
        end
      end
    end

    phrases.uniq
  end

  def calculate_attribute_bonus(candidate)
    bonus = 0.0

    @user_intent.prefs_selected.each do |pref|
      rule = @config["attributes"][@user_intent.user_type]&.[](pref)
      next unless rule

      if rule["match_input"] && @user_intent.has_language_preference?
        # Language matching
        candidate_languages = candidate["languages"] || []
        if candidate_languages.include?(@user_intent.language_preference)
          bonus += rule["weight"]
        end
      else
        # Field matching
        field_value = candidate[rule["field"]] || []
        field_value = [field_value] unless field_value.is_a?(Array)

        if (field_value & rule["any_of"]).any?
          bonus += rule["weight"]
        end
      end
    end

    # Clamp to attribute cap
    attribute_cap = @config["scoring_weights"]["attribute_cap"]
    [bonus, attribute_cap].min
  end

  def calculate_distance_score(candidate)
    user_coords = get_user_coordinates
    return 0.5 unless user_coords

    # Get coordinates from enhanced data if available
    lat, lng = if @enhanced_lookup && @enhanced_lookup[candidate["name"]]
      enhanced_data = @enhanced_lookup[candidate["name"]]
      [enhanced_data["lat"], enhanced_data["lng"]]
    else
      [candidate["lat"], candidate["lng"]]
    end

    return 0.5 unless lat && lng

    distance = haversine_distance(user_coords[0], user_coords[1], lat, lng)

    # Map distance to score using buckets
    buckets = @config["distance_buckets_miles"]
    bucket_scores = [1.00, 0.95, 0.90, 0.80, 0.70]

    buckets.each_with_index do |bucket, index|
      return bucket_scores[index] if distance <= bucket
    end

    0.70 # Default for distances > 50 miles
  end

  def calculate_final_score(dense_similarity, attribute_bonus, distance_score)
    weights = @config["scoring_weights"]

    raw_final_score = weights["dense_similarity"] * dense_similarity +
      weights["attribute_bonus"] * attribute_bonus +
      weights["distance_score"] * distance_score

    # Check if normalization is enabled
    behavior_config = @config["scoring_behavior"] || {}
    enable_normalization = behavior_config["enable_normalization"] != false
    enable_sigmoid = behavior_config["enable_sigmoid_transformation"] != false
    min_score = behavior_config["min_score"] || 0.05
    max_score = behavior_config["max_score"] || 0.95

    if enable_normalization && enable_sigmoid
      # Apply additional normalization to create better distribution
      # Use a less aggressive sigmoid to preserve higher scores
      normalized_score = 1.0 / (1.0 + Math.exp(-2.0 * (raw_final_score - 0.4)))

      # Clamp to reasonable range to prevent extreme scores
      final_score = normalized_score.clamp(min_score, max_score)

      # Log significant transformations for monitoring
      if (raw_final_score - final_score).abs > 0.1
        Rails.logger.info "Comprehensive Recommendation Service - Final score transformed: #{raw_final_score.round(3)} -> #{final_score.round(3)} (dense: #{dense_similarity.round(3)}, attr: #{attribute_bonus.round(3)}, dist: #{distance_score.round(3)})"
      end

      final_score
    else
      # Return raw score without normalization
      [raw_final_score, 1.0].min
    end
  end

  def build_recommendation(scored_candidate)
    candidate = scored_candidate[:candidate]

    # Get location data from enhanced lookup if available
    city, state = if @enhanced_lookup && @enhanced_lookup[candidate["name"]]
      enhanced_data = @enhanced_lookup[candidate["name"]]
      [enhanced_data["city"], enhanced_data["state"]]
    else
      [candidate["city"], candidate["state"]]
    end

    {
      id: candidate["id"],
      name: candidate["name"],
      url: candidate["url"] || candidate["id"], # Use ID as URL if no URL field
      city: city || "Unknown",
      state: state || "Unknown",
      score: scored_candidate[:final_score],
      relevance_reason: generate_relevance_reason(scored_candidate),
      metadata: {
        dense_similarity: scored_candidate[:dense_similarity],
        attribute_bonus: scored_candidate[:attribute_bonus],
        distance_score: scored_candidate[:distance_score]
      }
    }
  end

  def generate_relevance_reason(scored_candidate)
    candidate = scored_candidate[:candidate]

    parts = []

    # Add the actual causes this nonprofit serves (from CSV data)
    if candidate["causes"].present?
      # Parse the causes (they come as comma-separated string)
      nonprofit_causes = candidate["causes"].split(",").map(&:strip)

      # Format the causes nicely
      parts << if nonprofit_causes.length == 1
        "Serves: #{nonprofit_causes.first}"
      elsif nonprofit_causes.length == 2
        "Serves: #{nonprofit_causes.join(" and ")}"
      else
        "Serves: #{nonprofit_causes[0...-1].join(", ")}, and #{nonprofit_causes.last}"
      end
    end

    # Add user's selected causes that match
    user_causes = @user_intent.causes_selected.map(&:titleize)
    if user_causes.any?
      parts << "Matches your interest in #{user_causes.join(", ")}"
    end

    # Add location information
    city, state = if @enhanced_lookup && @enhanced_lookup[candidate["name"]]
      enhanced_data = @enhanced_lookup[candidate["name"]]
      [enhanced_data["city"], enhanced_data["state"]]
    else
      [candidate["city"], candidate["state"]]
    end

    if city && state && city != "Unknown"
      parts << "Located in #{city}, #{state}"
    elsif state && state != "Unknown"
      parts << "Located in #{state}"
    end

    # Add distance information if available
    user_coords = get_user_coordinates
    if user_coords
      # Get coordinates from enhanced data if available
      lat, lng = if @enhanced_lookup && @enhanced_lookup[candidate["name"]]
        enhanced_data = @enhanced_lookup[candidate["name"]]
        [enhanced_data["lat"], enhanced_data["lng"]]
      else
        [candidate["lat"], candidate["lng"]]
      end

      if lat && lng
        distance = haversine_distance(user_coords[0], user_coords[1], lat, lng)
        bucket = get_distance_bucket(distance)
        parts << "within #{bucket} miles of you"
      end
    end

    # Add language if applicable
    if @user_intent.has_language_preference?
      parts << "Offers services in #{@user_intent.language_preference.titleize}"
    end

    # Add accessibility if applicable
    if @user_intent.prefs_selected.include?("wheelchair_access")
      parts << "Wheelchair accessible"
    end

    # Add organizational identity if applicable
    if @user_intent.prefs_selected.include?("women_bipoc_led")
      parts << "Women/BIPOC-led organization"
    end

    parts.join(". ")
  end

  def get_distance_bucket(distance)
    buckets = @config["distance_buckets_miles"]
    bucket_labels = ["2", "5", "10", "25", "50"]

    buckets.each_with_index do |bucket, index|
      return bucket_labels[index] if distance <= bucket
    end

    "50+"
  end
end
