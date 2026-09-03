# frozen_string_literal: true

module SmartMatch
  # Decides how much of a submission's ranked matches the results page shows.
  #
  # The page used to show a fixed three, which made the engine look thinner than
  # it is and gave a user no room to choose. Instead:
  #
  #   * the first page is the highest match tier IN FULL -- if we think eleven
  #     organizations are a great fit, all eleven are options worth seeing;
  #   * if that tier is thinner than `min_visible`, the next tier down is added,
  #     and so on, so a quiz with two great matches still fills a page;
  #   * whatever that produces is capped at `page_size`, and each "Show more"
  #     reveals another `page_size` from further down the ranking, regardless of
  #     tier -- past the top tiers the user has explicitly asked for breadth.
  #
  # Tier boundaries are OrganizationMatch::TIERS, the same ones the cards print,
  # so what the page groups and what a card claims cannot drift apart. A tier
  # bigger than page_size is still split across a "Show more" -- the cap wins,
  # deliberately, over showing 40 cards at once.
  #
  # The pool itself is bounded by scoring.max_results in matching_rules.yml;
  # this class only chooses how much of it to reveal.
  class ResultsPage < ApplicationService
    DEFAULT_MIN_VISIBLE = 6
    DEFAULT_PAGE_SIZE = 20

    Page = Struct.new(:matches, :shown, :total, :next_page, :remaining, :page_size, keyword_init: true) do
      def more? = remaining.positive?

      # What the next click actually adds, which is what the button promises --
      # "Show 20 more" when 40 are left, "Show 3 more" when 3 are.
      def next_batch_size = [remaining, page_size].min
    end

    attr_reader :matches, :page

    # matches: an OrganizationMatch relation for one submission, unordered --
    # this class applies rank order itself.
    def initialize(matches:, page: 1)
      @matches = matches
      @page = [page.to_i, 1].max
    end

    def call
      shown = shown_count
      Page.new(
        matches: ranked.limit(shown),
        shown: shown,
        total: total,
        next_page: (page + 1 if total > shown),
        remaining: total - shown,
        page_size: page_size
      )
    end

    private

    def ranked
      matches.order(:rank)
    end

    # Scores only: the page boundary is decided before any card is loaded, so
    # asking for page 1 never pulls the logos and cover photos of page 3.
    def scores
      @scores ||= ranked.pluck(:score)
    end

    def total
      scores.size
    end

    def shown_count
      [first_page_count + (page - 1) * page_size, total].min
    end

    # How far the first page reaches: complete tiers, best first, until at least
    # min_visible matches are covered -- then capped at page_size.
    #
    # Walking a prefix of the ranking is sound because rank is score order and
    # the tier boundaries are score thresholds, so tiers can only ever appear as
    # consecutive runs.
    def first_page_count
      counts = scores.map { |score| OrganizationMatch.tier_for(score) }.tally

      covered = 0
      OrganizationMatch::TIERS.each_key do |tier|
        covered += counts.fetch(tier, 0)
        break if covered >= min_visible
      end

      [covered, page_size].min
    end

    def min_visible
      display_rules.fetch("min_visible", DEFAULT_MIN_VISIBLE)
    end

    def page_size
      display_rules.fetch("page_size", DEFAULT_PAGE_SIZE)
    end

    def display_rules
      SmartMatch::MATCHING_RULES["results_display"] || {}
    end
  end
end
