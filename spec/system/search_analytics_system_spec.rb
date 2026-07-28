require "system_helper"

RSpec.describe "Search analytics tracking", type: :system do
  let!(:user) { create(:user) }

  before do
    sign_in user
  end

  it "pushes a search event to the GTM dataLayer when a search is submitted" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)

    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)

    data_layer = page.evaluate_script("window.dataLayer || []")
    search_event = data_layer.reverse.find { |entry| entry["event"] == "search" }

    expect(search_event).not_to be_nil
    expect(search_event["search_term"]).to eq("food pantry")
    expect(search_event["category"]).to eq("Find Help")
  end

  it "does not re-fire the search event on pagination" do
    visit search_path

    find("#search-keyword-input").set("food pantry")
    find("#search-keyword-input").send_keys(:enter)
    expect(page).to have_current_path(search_path, ignore_query: true, wait: 5)

    count_after_search = page.evaluate_script(
      "(window.dataLayer || []).filter(e => e.event === 'search').length"
    )

    expect(count_after_search).to eq(1)
  end
end
