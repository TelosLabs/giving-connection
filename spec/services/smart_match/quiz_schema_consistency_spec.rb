# frozen_string_literal: true

require "rails_helper"

# Drift guard: SmartMatch::QuizNavigator and SmartMatch::QuizStepConfig each
# encode the quiz's step schema independently -- the navigator as step-number
# constants (total steps, which step is location_detail/travel/preferences) and
# the config as per-user-type step -> partial/section maps. These two duplicated
# schemas must stay in agreement; if a step is inserted or reordered in one but
# not the other, navigation silently skips or mis-routes questions. These specs
# assert the constants agree with the maps so a divergence fails loudly here
# instead of in production. (They intentionally do NOT refactor the maps.)
RSpec.describe "SmartMatch quiz step schema consistency" do
  let(:user_types) { %w[service_seeker volunteer donor] }

  it "QuizNavigator total steps match the size of each QuizStepConfig section map" do
    user_types.each do |user_type|
      total = SmartMatch::QuizNavigator.total_steps_for(user_type)
      map = SmartMatch::QuizStepConfig.section_map_for(user_type)

      expect(total).to eq(map.keys.max),
        "expected QuizNavigator total (#{total}) to equal the highest " \
        "QuizStepConfig step (#{map.keys.max}) for #{user_type}"
      expect(map.keys).to eq((1..total).to_a),
        "expected QuizStepConfig #{user_type} steps to be contiguous 1..#{total}"
    end
  end

  it "QuizNavigator LOCATION_DETAIL_STEP points at each flow's location_detail partial" do
    SmartMatch::QuizNavigator::LOCATION_DETAIL_STEP.each do |user_type, step|
      expect(SmartMatch::QuizStepConfig.partial_for(user_type, step))
        .to eq("smart_match/quizzes/steps/location_detail"),
          "LOCATION_DETAIL_STEP[#{user_type}] = #{step} does not map to the location_detail partial"
    end
  end

  it "QuizNavigator SERVICE_SEEKER_TRAVEL_STEP points at the service_seeker travel partial" do
    step = SmartMatch::QuizNavigator::SERVICE_SEEKER_TRAVEL_STEP
    expect(SmartMatch::QuizStepConfig.partial_for("service_seeker", step))
      .to eq("smart_match/quizzes/steps/travel")
  end

  it "QuizNavigator SERVICE_SEEKER_PREFERENCES_STEP points at the service_seeker preferences partial" do
    step = SmartMatch::QuizNavigator::SERVICE_SEEKER_PREFERENCES_STEP
    expect(SmartMatch::QuizStepConfig.partial_for("service_seeker", step))
      .to eq("smart_match/quizzes/steps/preferences")
  end

  # Third duplicated schema: QuizNavigator writes answers into the session, and
  # UserIntent reads them back out. For most of the engine's life these two
  # disagreed silently -- the navigator stored 20 answers and UserIntent
  # accepted 7, so 13 questions were collected from users and then discarded
  # before scoring. Nothing failed; the answers simply had no effect.
  #
  # These specs make that class of drift loud. Adding a question to the quiz
  # now forces an explicit decision about whether it scores.
  describe "QuizNavigator answers reach UserIntent" do
    # Session keys the navigator writes that intentionally never become a
    # UserIntent answer attribute, with the reason each is exempt.
    let(:non_answer_session_params) do
      {
        user_type: "the path itself -- passed to from_session separately",
        causes: "kept under the historical causes_selected accessor",
        prefs: "kept under the historical prefs_selected accessor",
        language_input: "free text -- feeds embedding text, not preset scoring",
        travel_bucket: "drives the retrieval radius, not an answer weight"
      }
    end

    it "every navigator answer param is readable from UserIntent" do
      SmartMatch::QuizNavigator::PARAM_SESSION_MAP.each_key do |param|
        next if non_answer_session_params.key?(param)

        expect(UserIntent::QUIZ_ANSWERS).to have_key(param),
          "QuizNavigator stores :#{param} in the session but UserIntent::QUIZ_ANSWERS " \
          "does not declare it, so the answer is collected and then dropped before " \
          "scoring. Add it to QUIZ_ANSWERS (with its form arity), or add it to " \
          "NON_ANSWER_SESSION_PARAMS with a reason."
      end
    end

    it "every declared UserIntent answer is actually stored by the navigator" do
      UserIntent::QUIZ_ANSWERS.each_key do |answer|
        expect(SmartMatch::QuizNavigator::PARAM_SESSION_MAP).to have_key(answer),
          "UserIntent declares :#{answer} but QuizNavigator never stores it, " \
          "so it will always be blank."
      end
    end

    it "declares each answer with the arity its step partial submits" do
      partials = Rails.root.glob("app/views/smart_match/quizzes/steps/*.html.erb")
        .map(&:read).join("\n")

      UserIntent::QUIZ_ANSWERS.each do |answer, arity|
        submits_array = partials.include?(%(name="#{answer}[]"))
        submits_scalar = partials.match?(/radio_button :#{answer}\b|f\.select :#{answer}\b|name="#{answer}"/)

        # Skip answers whose control we can't find -- covered by the specs above.
        next unless submits_array || submits_scalar

        expected = submits_array ? :multiple : :single
        expect(arity).to eq(expected),
          "UserIntent::QUIZ_ANSWERS declares :#{answer} as #{arity.inspect} but its " \
          "step partial submits it as #{expected.inspect}"
      end
    end
  end
end
