# frozen_string_literal: true

module SmartMatch
  class QuizStepConfig
    # Step structure: section_number, section_i18n_key, title_i18n_key, subtitle_kind.
    # Display strings are looked up from config/locales/{en,es}.yml at render
    # time, keeping copy out of Ruby and translatable. The structural metadata
    # (section grouping, subtitle kind = single/multiple/none) stays in code
    # because navigator/scorer branch on it.
    #
    # Note on YAML: STEP_STRUCTURES and STEP_PARTIAL_MAP were considered for
    # extraction to config/smart_match_quiz.yml. Decision: keep in Ruby. The
    # values are stable structural pointers (i18n keys, view-path strings,
    # integers) -- not natural-language or operator-tunable config. YAML adds
    # indirection without easing change. Natural-language copy lives in
    # config/locales/* where it belongs.
    STEP_STRUCTURES = {
      "service_seeker" => {
        1 => {number:1, section_key: :about_you, title_key: "service_seeker.step_1", subtitle: :single},
        2 => {number:1, section_key: :about_you, title_key: "service_seeker.step_2", subtitle: :single},
        3 => {number:2, section_key: :type_of_support, title_key: "service_seeker.step_3", subtitle: :single},
        4 => {number:2, section_key: :type_of_support, title_key: "service_seeker.step_4", subtitle: :multiple},
        5 => {number:2, section_key: :type_of_support, title_key: "service_seeker.step_5", subtitle: :single},
        6 => {number:3, section_key: :location_access, title_key: "service_seeker.step_6", subtitle: :single},
        7 => {number:3, section_key: :location_access, title_key: "service_seeker.step_7", subtitle: :single},
        8 => {number:4, section_key: :prefs_accessibility, title_key: "service_seeker.step_8", subtitle: :multiple},
        9 => {number:4, section_key: :prefs_accessibility, title_key: :personal_details, subtitle: :none}
      }.freeze,
      "volunteer" => {
        1 => {number:1, section_key: :about_you, title_key: "volunteer.step_1", subtitle: :single},
        2 => {number:1, section_key: :about_you, title_key: "volunteer.step_2", subtitle: :multiple},
        3 => {number:2, section_key: :volunteer_prefs, title_key: "volunteer.step_3", subtitle: :multiple},
        4 => {number:2, section_key: :volunteer_prefs, title_key: "volunteer.step_4", subtitle: :multiple},
        5 => {number:3, section_key: :volunteer_availability, title_key: "volunteer.step_5", subtitle: :single},
        6 => {number:3, section_key: :engagement, title_key: "volunteer.step_6", subtitle: :single},
        7 => {number:3, section_key: :volunteer_availability, title_key: "volunteer.step_7", subtitle: :single},
        8 => {number:4, section_key: :prefs_accessibility, title_key: :personal_details, subtitle: :none}
      }.freeze,
      "donor" => {
        1 => {number:1, section_key: :about_you, title_key: "donor.step_1", subtitle: :single},
        2 => {number:1, section_key: :about_you, title_key: "donor.step_2", subtitle: :multiple},
        3 => {number:2, section_key: :donor_prefs, title_key: "donor.step_3", subtitle: :multiple},
        4 => {number:2, section_key: :donor_prefs, title_key: "donor.step_4", subtitle: :multiple},
        5 => {number:2, section_key: :donor_prefs, title_key: "donor.step_5", subtitle: :multiple},
        6 => {number:3, section_key: :engagement, title_key: "donor.step_6", subtitle: :single},
        7 => {number:3, section_key: :engagement, title_key: "donor.step_7", subtitle: :single},
        8 => {number:3, section_key: :engagement, title_key: "donor.step_8", subtitle: :single},
        9 => {number:4, section_key: :prefs_accessibility, title_key: :personal_details, subtitle: :none}
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
      STEP_STRUCTURES[user_type.to_s] || STEP_STRUCTURES["donor"]
    end

    # Returns a display-ready section hash with the same shape the views expect:
    # {number:, name:, title:, subtitle:}. Strings are localized at call time
    # using the current I18n locale.
    def self.section_for(user_type, step)
      map = section_map_for(user_type)
      structure = map[step] || map[1]
      {
        number: structure[:number],
        name: I18n.t("smart_match.quiz.sections.#{structure[:section_key]}"),
        title: title_for(structure[:title_key]),
        subtitle: subtitle_for(structure[:subtitle])
      }
    end

    def self.partial_for(user_type, step)
      entry = STEP_PARTIAL_MAP[step]
      entry.is_a?(Hash) ? (entry[user_type.to_s] || entry["donor"]) : entry
    end

    # title_key is either a Symbol referencing a top-level key
    # (e.g. :personal_details -> smart_match.quiz.titles.personal_details)
    # or a String of the form "<user_type>.<step>" referencing the
    # user_type-scoped section.
    def self.title_for(title_key)
      I18n.t("smart_match.quiz.titles.#{title_key}")
    end

    def self.subtitle_for(kind)
      return nil if kind == :none

      I18n.t("smart_match.quiz.subtitles.#{kind}_choice")
    end
  end
end
