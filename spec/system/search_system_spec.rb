require "system_helper"

RSpec.describe "Search", type: :system do
  let!(:user) { create(:user) }

  before do
    sign_in user
  end

  it "searches by keyword" do
    visit root_path
    find(:test_id, "search_input").fill_in with: "health"
    click_button "home_search_btn"

    expect(page).to have_current_path(search_path, ignore_query: true)
  end
end
