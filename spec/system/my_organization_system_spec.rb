require "system_helper"

RSpec.describe "Edit My Organization", type: :system do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, :without_services) }

  before do
    create(:organization_admin, user: user, organization: organization, role: "admin")
    sign_in user
    visit edit_organization_path(organization)
  end

  it "allows the user to edit the organization" do
    expect(page).to have_text("Edit Page")

    # Alert user when navigating away without saving changes
    find(:test_id, "organization_name_input").fill_in with: "New Name"
    click_button "search_navbar_link"

    within(:test_id, "unsaved_changes_modal") do
      expect(page).to have_text("You made changes without saving")
      click_button "unsave_changes_modal_return_to_page_btn"
    end

    # Does not save organization when required fields are not filled in
    find(:test_id, "organization_name_input").fill_in with: ""

    click_button "edit_my_organization_submit_btn"

    within(:test_id, "edit_organization_form") do
      expect(page).to have_text("Name can't be blank")
    end

    # # Save changes
    find(:test_id, "organization_name_input").fill_in with: "Cool new name"

    click_button "edit_my_organization_submit_btn"

    expect(page).to have_current_path my_account_path

    expect(page).to have_text("Organization was successfully updated")
  end
end
