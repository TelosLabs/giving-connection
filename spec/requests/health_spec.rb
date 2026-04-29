# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health check", type: :request do
  describe "GET /up" do
    it "returns 200 OK when the database is reachable" do
      get "/up"

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("OK")
    end

    it "does not require authentication" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end

    it "returns 503 when the database is unreachable" do
      allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(PG::ConnectionBad.new("connection lost"))

      get "/up"

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).to eq("Service Unavailable")
    end
  end
end
