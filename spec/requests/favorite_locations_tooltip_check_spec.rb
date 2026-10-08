require "rails_helper"

# Regression guard: the "card" (result_card) and "map popup"/detail-page
# simplified SaveButton instances for the same location share a tooltip's
# wrapper but need different anchors (right vs left) to avoid overflowing
# their very different containers. They used to share one CSS selector, so
# turbo_stream.replace_all in #create/#destroy could only render ONE of the
# two correct positions, silently breaking whichever variant it didn't
# render. SaveButton::Component#btn_selector now bakes the anchor into the
# selector so each variant can be targeted (and re-rendered correctly) on
# its own.
RSpec.describe "FavoriteLocations turbo_stream tooltip variants", type: :request do
  let(:user) { create(:user) }
  let(:location) { create(:organization).locations.first }

  before { sign_in user }

  def anchor_class_for(body, selector)
    fragment = body[/<turbo-stream action="replace" targets="#{Regexp.escape(selector)}">.*?<\/turbo-stream>/m]
    fragment[/role="tooltip"[^>]*class="([^"]*)"/, 1]
  end

  it "create renders the card and map-popup simplified variants with their own correct tooltip anchor" do
    post favorite_locations_path(location_id: location.id), as: :turbo_stream

    body = response.body
    right_class = anchor_class_for(body, ".save-location-#{location.id}-btn__simplified__right")
    left_class = anchor_class_for(body, ".save-location-#{location.id}-btn__simplified__left")

    expect(right_class).to include("right-0")
    expect(left_class).to include("left-0")
    expect(left_class).not_to include("right-0")
  end

  it "destroy renders the card and map-popup simplified variants with their own correct tooltip anchor" do
    favorite = create(:favorite_location, user: user, location: location)

    delete favorite_location_path(favorite), as: :turbo_stream

    body = response.body
    right_class = anchor_class_for(body, ".save-location-#{location.id}-btn__simplified__right")
    left_class = anchor_class_for(body, ".save-location-#{location.id}-btn__simplified__left")

    expect(right_class).to include("right-0")
    expect(left_class).to include("left-0")
    expect(left_class).not_to include("right-0")
  end
end
