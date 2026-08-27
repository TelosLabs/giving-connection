# frozen_string_literal: true

require "rails_helper"

# The feedback widget is rendered inline by its host pages, so a malformed tag in
# shared/_feedback takes the whole page down with it (search, discover and every
# nonprofit page at once). These specs exist to turn that into a red build.
RSpec.describe "Feedback widget", type: :request do
  shared_examples "renders the feedback widget" do
    it "returns 200 with the widget mounted" do
      subject

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="feedback"')
      expect(response.body).to include('aria-label="Give feedback"')
      expect(response.body).to include("Please tell us about your experience")
    end
  end

  # The widget's category menu is a hand-rolled listbox (each option carries an
  # icon), so the ARIA wiring is markup that can silently disappear.
  describe "category dropdown accessibility" do
    before do
      create(:cause)
      get discover_path
    end

    it "exposes the trigger as a collapsed listbox control" do
      expect(response.body).to include('aria-haspopup="listbox"')
      expect(response.body).to include('aria-expanded="false"')
      expect(response.body).to include('aria-controls="feedback_category_listbox"')
    end

    it "marks the menu and its options with listbox roles" do
      expect(response.body).to include('role="listbox"')
      expect(response.body.scan('role="option"').size).to eq(Feedback::CATEGORY_OPTIONS.size)
    end
  end

  describe "honeypot field" do
    before do
      create(:cause)
      get discover_path
    end

    # The view hardcodes the field name; this keeps it tied to the constant the
    # controller checks without the view reaching into the controller.
    it "renders the field name the controller treats as the honeypot" do
      expect(response.body).to include(%(name="feedback[#{FeedbacksController::HONEYPOT_FIELD}]"))
    end
  end

  describe "GET /discover" do
    subject { get discover_path }

    before { create(:cause) }

    it_behaves_like "renders the feedback widget"
  end

  describe "GET /search" do
    subject { get search_path }

    it_behaves_like "renders the feedback widget"
  end

  describe "GET /locations/:id" do
    subject { get location_path(location) }

    let(:location) { create(:location, :with_office_hours) }

    it_behaves_like "renders the feedback widget"
  end
end
