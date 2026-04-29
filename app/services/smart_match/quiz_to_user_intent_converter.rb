# frozen_string_literal: true

module SmartMatch
  class QuizToUserIntentConverter < ApplicationService
    attr_reader :session_answers, :user_type

    def initialize(session_answers:, user_type:)
      @session_answers = session_answers.with_indifferent_access
      @user_type = user_type
    end

    def call
      UserIntent.new(
        user_type:       user_type,
        state:           session_answers[:state],
        city:            session_answers[:city],
        travel_bucket:   session_answers[:travel_bucket],
        causes_selected: parse_array(:causes),
        prefs_selected:  parse_array(:preferences),
        language_input:  session_answers[:language_input]
      )
    end

    private

    def parse_array(key)
      Array(session_answers[key]).map(&:strip).reject(&:blank?)
    end
  end
end
