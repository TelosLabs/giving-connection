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
      # Derived from the navigator's own constants so inserting a step
      # upstream (as the services question did) doesn't silently invalidate
      # these assertions.
      let(:seeker_detail_step) { SmartMatch::QuizNavigator::LOCATION_DETAIL_STEP["service_seeker"] }
      let(:seeker_city_step) { seeker_detail_step - 1 }
      let(:seeker_travel_step) { SmartMatch::QuizNavigator::SERVICE_SEEKER_TRAVEL_STEP }
      let(:donor_detail_step) { SmartMatch::QuizNavigator::LOCATION_DETAIL_STEP["donor"] }

      it "stores a nationwide scope from the detail step and clears any specific location" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_state] = "TN"
        session[:smart_match_city] = "Nashville"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(location_scope_choice: "national").permit!,
          step: seeker_detail_step
        )

        expect(session[:smart_match_location_scope]).to eq("national")
        expect(session[:smart_match_state]).to be_nil
        expect(session[:smart_match_city]).to be_nil
      end

      it "stores an international scope from the detail step" do
        session[:smart_match_user_type] = "donor"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(location_scope_choice: "international").permit!,
          step: donor_detail_step
        )

        expect(session[:smart_match_location_scope]).to eq("international")
      end

      it "stores a local scope with state/city from the detail step" do
        session[:smart_match_user_type] = "service_seeker"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(location_scope_choice: "local", state: "OR", city: "Portland").permit!,
          step: seeker_detail_step
        )

        expect(session[:smart_match_location_scope]).to eq("local")
        expect(session[:smart_match_state]).to eq("OR")
        expect(session[:smart_match_city]).to eq("Portland")
      end

      it "marks a local scope when a preset city is picked and skips the detail step" do
        session[:smart_match_user_type] = "service_seeker"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "Nashville").permit!,
          step: seeker_city_step
        )

        expect(session[:smart_match_location_scope]).to eq("local")
        expect(session[:smart_match_city]).to eq("Nashville")
        expect(session[:smart_match_city_choice]).to eq("Nashville")
        # Jumps straight to travel, skipping the detail step since a preset was chosen.
        expect(session[:smart_match_step]).to eq(seeker_travel_step)
      end

      it "routes to the detail step when 'Somewhere else' is chosen" do
        session[:smart_match_user_type] = "service_seeker"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "elsewhere").permit!,
          step: seeker_city_step
        )

        expect(session[:smart_match_city_choice]).to eq("elsewhere")
        expect(session[:smart_match_step]).to eq(seeker_detail_step)
      end

      it "skips the service_seeker travel step when scope is non-local" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_city_choice] = "elsewhere"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(location_scope_choice: "national").permit!,
          step: seeker_detail_step
        )

        # Jumps over the (now irrelevant) distance step.
        expect(session[:smart_match_location_scope]).to eq("national")
        expect(session[:smart_match_step]).to eq(seeker_travel_step + 1)
      end

      it "keeps the travel step for a local service_seeker search" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_location_scope] = "local"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(city_selection: "Nashville").permit!,
          step: seeker_city_step
        )

        expect(session[:smart_match_step]).to eq(seeker_travel_step)
      end

      it "skips back over the travel step when scope is non-local" do
        session[:smart_match_user_type] = "service_seeker"
        session[:smart_match_location_scope] = "national"
        session[:smart_match_city_choice] = "elsewhere"

        described_class.call(
          session: session,
          params: ActionController::Parameters.new(direction: "back").permit!,
          step: seeker_travel_step + 1
        )

        # Back over the distance step to the detail step.
        expect(session[:smart_match_step]).to eq(seeker_detail_step)
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
    it "returns 11 for service_seeker" do
      expect(described_class.total_steps_for("service_seeker")).to eq(12)
    end

    it "returns 10 for volunteer" do
      expect(described_class.total_steps_for("volunteer")).to eq(11)
    end

    it "returns 11 for donor" do
      expect(described_class.total_steps_for("donor")).to eq(12)
    end

    it "returns default for unknown type" do
      expect(described_class.total_steps_for("unknown")).to eq(4)
    end
  end
end
