# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Feedbacks", type: :request do
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:valid_params) do
    { feedback: { rating: 5, category: "search_results", comment: "Great!", context: "search" } }
  end

  describe "POST /feedbacks" do
    context "with a valid rating (turbo_stream)" do
      it "persists the feedback and returns a success stream" do
        expect do
          post feedbacks_path, params: valid_params, headers: turbo_headers
        end.to change(Feedback, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(Feedback.last.rating).to eq(5)
      end
    end

    context "with an invalid rating (turbo_stream)" do
      it "does not persist and returns 422" do
        expect do
          post feedbacks_path, params: { feedback: { rating: nil } }, headers: turbo_headers
        end.not_to change(Feedback, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "html format" do
      it "redirects back to the fallback location on success" do
        post feedbacks_path, params: valid_params, headers: { "Referer" => "/search" }
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to("/search")
      end
    end

    context "page_url" do
      it "falls back to the referer when no page_url is submitted" do
        post feedbacks_path, params: valid_params, headers: turbo_headers.merge("Referer" => "https://example.com/search")
        expect(Feedback.last.page_url).to eq("https://example.com/search")
      end

      it "keeps a submitted page_url" do
        params = valid_params.deep_merge(feedback: { page_url: "https://example.com/explicit" })
        post feedbacks_path, params: params, headers: turbo_headers
        expect(Feedback.last.page_url).to eq("https://example.com/explicit")
      end
    end

    context "user association" do
      it "associates the feedback with the signed-in user" do
        user = create(:user)
        login_as(user, scope: :user)
        post feedbacks_path, params: valid_params, headers: turbo_headers
        expect(Feedback.last.user).to eq(user)
      end

      it "leaves the user nil for anonymous submissions" do
        post feedbacks_path, params: valid_params, headers: turbo_headers
        expect(Feedback.last.user).to be_nil
      end
    end
  end
end
