# frozen_string_literal: true

module SmartMatch
  class QuizStepConfig
    SECTION_MAPS = {
      "service_seeker" => {
        1 => {number: 1, name: "About You", title: "How can we support you today?", subtitle: "Single Choice"},
        2 => {number: 1, name: "About You", title: "Who are you seeking support for?", subtitle: "Single Choice"},
        3 => {number: 2, name: "Type of Support", title: "How would you describe yourself?", subtitle: "Single Choice"},
        4 => {number: 2, name: "Type of Support", title: "Which categories best fits your needs?", subtitle: "Multiple Choice"},
        5 => {number: 2, name: "Type of Support", title: "What best describes your situation?", subtitle: "Single Choice"},
        6 => {number: 3, name: "Location & Access", title: "Where should we look for support?", subtitle: "Single Choice"},
        7 => {number: 3, name: "Location & Access", title: "What kind of travel is possible for you?", subtitle: "Single Choice"},
        8 => {number: 4, name: "Preferences & Accessibility", title: "What should we keep in mind when matching you to services?", subtitle: "Multiple Choice"},
        9 => {number: 4, name: "Preferences & Accessibility", title: "Personal Details", subtitle: nil}
      }.freeze,
      "volunteer" => {
        1 => {number: 1, name: "About You", title: "How can we support you today?", subtitle: "Single Choice"},
        2 => {number: 1, name: "About You", title: "Which causes are close to your heart?", subtitle: "Multiple Choice"},
        3 => {number: 2, name: "Your Volunteering Preferences", title: "How would you like to help?", subtitle: "Multiple Choice"},
        4 => {number: 2, name: "Your Volunteering Preferences", title: "What type of volunteering are you looking for?", subtitle: "Multiple Choice"},
        5 => {number: 3, name: "Your Availability & Location", title: "What format works best for you?", subtitle: "Single Choice"},
        6 => {number: 3, name: "Where & How You Engage", title: "Which community would you like your giving to focus on?", subtitle: "Single Choice"},
        7 => {number: 3, name: "Your Availability & Location", title: "How much time do you have to give?", subtitle: "Single Choice"},
        8 => {number: 4, name: "Preferences & Accessibility", title: "Personal Details", subtitle: nil}
      }.freeze,
      "donor" => {
        1 => {number: 1, name: "About You", title: "How can we support you today?", subtitle: "Single Choice"},
        2 => {number: 1, name: "About You", title: "What causes are close to your heart?", subtitle: "Multiple Choice"},
        3 => {number: 2, name: "Your Donation Preferences", title: "What is your preferred donation style?", subtitle: "Multiple Choice"},
        4 => {number: 2, name: "Your Donation Preferences", title: "What inspires your giving today?", subtitle: "Multiple Choice"},
        5 => {number: 2, name: "Your Donation Preferences", title: "Are there specific communities or populations you'd like your donation to support?", subtitle: "Multiple Choice"},
        6 => {number: 3, name: "Where & How You Engage", title: "Where would you like your donation to make an impact?", subtitle: "Single Choice"},
        7 => {number: 3, name: "Where & How You Engage", title: "Which community would you like your giving to focus on?", subtitle: "Single Choice"},
        8 => {number: 3, name: "Where & How You Engage", title: "How would you like to be involved?", subtitle: "Single Choice"},
        9 => {number: 4, name: "Preferences & Accessibility", title: "Personal Details", subtitle: nil}
      }.freeze
    }.freeze

    STEP_PARTIAL_MAP = {
      1 => "smart_match/quizzes/steps/user_type",
      2 => {
        "service_seeker" => "smart_match/quizzes/steps/support_for",
        "volunteer" => "smart_match/quizzes/steps/causes",
        "donor" => "smart_match/quizzes/steps/causes"
      },
      3 => {
        "service_seeker" => "smart_match/quizzes/steps/self_description",
        "volunteer" => "smart_match/quizzes/steps/volunteer_involvement",
        "donor" => "smart_match/quizzes/steps/donor_giving_style"
      },
      4 => {
        "service_seeker" => "smart_match/quizzes/steps/causes",
        "volunteer" => "smart_match/quizzes/steps/volunteer_type",
        "donor" => "smart_match/quizzes/steps/donor_giving_inspiration"
      },
      5 => {
        "service_seeker" => "smart_match/quizzes/steps/situation",
        "volunteer" => "smart_match/quizzes/steps/volunteer_format",
        "donor" => "smart_match/quizzes/steps/donor_communities"
      },
      6 => {
        "service_seeker" => "smart_match/quizzes/steps/city_selection",
        "volunteer" => "smart_match/quizzes/steps/city_selection",
        "donor" => "smart_match/quizzes/steps/donor_impact_location"
      },
      7 => {
        "service_seeker" => "smart_match/quizzes/steps/travel",
        "volunteer" => "smart_match/quizzes/steps/volunteer_time",
        "donor" => "smart_match/quizzes/steps/city_selection"
      },
      8 => {
        "service_seeker" => "smart_match/quizzes/steps/preferences",
        "volunteer" => "smart_match/quizzes/steps/final",
        "donor" => "smart_match/quizzes/steps/donor_involvement"
      },
      9 => "smart_match/quizzes/steps/final"
    }.freeze

    def self.section_map_for(user_type)
      SECTION_MAPS[user_type.to_s] || SECTION_MAPS["donor"]
    end

    def self.section_for(user_type, step)
      map = section_map_for(user_type)
      map[step] || map[1]
    end

    def self.partial_for(user_type, step)
      entry = STEP_PARTIAL_MAP[step]
      entry.is_a?(Hash) ? (entry[user_type.to_s] || entry["donor"]) : entry
    end
  end
end
