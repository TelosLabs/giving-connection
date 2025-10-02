# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchExportsController, type: :controller do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let!(:location) do
    create(:location, :with_office_hours,
      organization: organization,
      address: "123 Main St, Nashville, TN 37201")
  end
  let(:result_ids) { [location.id] }

  describe "POST #create" do
    context "when user is authenticated" do
      before { sign_in user }

      it "generates and downloads CSV file" do
        post :create, params: {result_ids: result_ids}

        expect(response.status).to eq(200)
        expect(response.headers["Content-Type"]).to eq("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("search_results")
      end

      it "includes result count in filename" do
        post :create, params: {result_ids: result_ids}

        expect(response.headers["Content-Disposition"]).to include("1_locations")
      end

      it "returns CSV with proper headers" do
        post :create, params: {result_ids: result_ids}

        csv_content = response.body
        expect(csv_content).to include("Nonprofit Name")
        expect(csv_content).to include("Description")
        expect(csv_content).to include("Address")
        expect(csv_content).to include("Phone Number")
        expect(csv_content).to include("Email")
        expect(csv_content).to include("Website")
        expect(csv_content).to include("Verified")
      end

      context "with rate limiting" do
        it "allows multiple exports within limit" do
          9.times do
            post :create, params: {result_ids: result_ids}
            expect(response.status).to eq(200)
          end
        end

        it "blocks exports after rate limit exceeded" do
          # Mock the cache read to return a value at the threshold
          cache_key = "export_count_#{user.id}_#{Time.current.hour}"
          allow(Rails.cache).to receive(:read).with(cache_key).and_return(10)

          post :create, params: {result_ids: result_ids}

          expect(response).to redirect_to(search_path)
          expect(flash[:alert]).to include("Export limit reached")
        end
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        post :create, params: {result_ids: result_ids}

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "with invalid result IDs" do
      before { sign_in user }

      it "handles missing result IDs gracefully" do
        post :create, params: {result_ids: []}

        expect(response).to redirect_to(search_path)
        expect(flash[:alert]).to include("No search results to export")
      end
    end

    context "when service raises an error" do
      before do
        sign_in user
        allow(SearchResultsExporter).to receive(:call).and_raise(StandardError, "Service error")
      end

      it "handles service errors gracefully" do
        post :create, params: {result_ids: result_ids}

        expect(response).to redirect_to(search_path)
        expect(flash[:alert]).to include("couldn't generate your download")
      end
    end
  end
end
