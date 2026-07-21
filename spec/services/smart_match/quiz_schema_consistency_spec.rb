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
end
