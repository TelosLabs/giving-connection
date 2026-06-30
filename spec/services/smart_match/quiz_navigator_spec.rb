# frozen_string_literal: true

require "rails_helper"

RSpec.describe SmartMatch::QuizNavigator do
  let(:session) { {} }

  describe ".call" do
    context "when navigating forward" do
      it "stores user type and advances step" do
        result = described_class.call(
          session: session,
          params: ActionController::Parameters.new(user_type: "volunteer").permit!,
          step: 1
        )

        expect(session[:smart_match_user_type]).to eq("volunteer")
        expect(session[:smart_match_step]).to eq(2)
        expect(result[:completed]).to be false
      end

      it "stores location data" do
        session[:smart_match_user_type] = "volunteer"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(state: "TN", city: "Nashville", travel_bucket: "moderate").permit!,
          step: 2
        )

        expect(session[:smart_match_state]).to eq("TN")
        expect(session[:smart_match_city]).to eq("Nashville")
        expect(session[:smart_match_travel_bucket]).to eq("moderate")
      end

      it "stores causes" do
        session[:smart_match_user_type] = "volunteer"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(causes: ["Education", "Health"]).permit!,
          step: 3
        )

        expect(session[:smart_match_causes]).to eq(["Education", "Health"])
      end

      it "marks completed on final step for volunteer" do
        session[:smart_match_user_type] = "volunteer"
        final_step = described_class.total_steps_for("volunteer")

        result = described_class.call(
          session: session,
          params: ActionController::Parameters.new(language_input: "help with education").permit!,
          step: final_step
        )

        expect(result[:completed]).to be true
      end

      it "does not mark completed before final step for service_seeker" do
        session[:smart_match_user_type] = "service_seeker"

        result = described_class.call(
          session: session,
          params: ActionController::Parameters.new(causes: ["Education"]).permit!,
          step: 3
        )

        expect(result[:completed]).to be false
        expect(session[:smart_match_step]).to eq(4)
      end
    end

    context "with location scope (nationwide / international)" do
      it "stores a nationwide scope and clears any specific location" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_state] = "TN"
        session[:smart_match_city] = "Nashville"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "national").permit!,
          step: 6
        )

        expect(session[:smart_match_location_scope]).to eq("national")
        expect(session[:smart_match_state]).to be_nil
        expect(session[:smart_match_city]).to be_nil
      end

      it "stores an international scope" do
        session[:smart_match_user_type] = "donor"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "international").permit!,
          step: 7
        )

        expect(session[:smart_match_location_scope]).to eq("international")
      end

      it "marks a local scope when a specific city is picked" do
        session[:smart_match_user_type] = "service_seeker"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "Nashville").permit!,
          step: 6
        )

        expect(session[:smart_match_location_scope]).to eq("local")
        expect(session[:smart_match_city]).to eq("Nashville")
      end

      it "skips the service_seeker travel step (7) when scope is non-local" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_location_scope] = "national"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "national").permit!,
          step: 6
        )

        # 6 -> 8, jumping over the (now irrelevant) distance step 7.
        expect(session[:smart_match_step]).to eq(8)
      end

      it "keeps the travel step for a local service_seeker search" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_location_scope] = "local"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "Nashville").permit!,
          step: 6
        )

        expect(session[:smart_match_step]).to eq(7)
      end

      it "skips back over the travel step when scope is non-local" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_location_scope] = "national"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(direction: "back").permit!,
          step: 8
        )

        expect(session[:smart_match_step]).to eq(6)
      end
    end

    context "when navigating back" do
      it "decrements step" do
        session[:smart_match_user_type] = "volunteer"

        result = described_class.call(
          session: session,
          params: ActionController::Parameters.new(direction: "back").permit!,
          step: 3
        )

        expect(session[:smart_match_step]).to eq(2)
        expect(result[:completed]).to be false
      end

      it "does not go below step 1" do
        session[:smart_match_user_type] = "volunteer"

        result = described_class.call(
          session: session,
          params: ActionController::Parameters.new(direction: "back").permit!,
          step: 1
        )

        expect(session[:smart_match_step]).to eq(1)
        expect(result[:completed]).to be false
      end
    end
  end

  describe ".total_steps_for" do
    it "returns 10 for service_seeker" do
      expect(described_class.total_steps_for("service_seeker")).to eq(10)
    end

    it "returns 9 for volunteer" do
      expect(described_class.total_steps_for("volunteer")).to eq(9)
    end

    it "returns 10 for donor" do
      expect(described_class.total_steps_for("donor")).to eq(10)
    end

    it "returns default for unknown type" do
      expect(described_class.total_steps_for("unknown")).to eq(4)
    end
  end
end
