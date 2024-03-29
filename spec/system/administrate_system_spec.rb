require "system_helper"

RSpec.describe "Administrate", type: :system do
  before do
    @admin = create(:admin_user)
  end

  it "can log in" do
    visit admin_root_path

    find(:test_id, "admin_login_email_input").fill_in with: @admin.email
    find(:test_id, "admin_login_password_input").fill_in with: "wrong password"
    click_button "admin_login_submit_btn"
    expect(page).to have_content("Invalid Email or password.")

    find(:test_id, "admin_login_password_input").fill_in with: @admin.password
    click_button "admin_login_submit_btn"

    expect(page).to have_content("Signed in successfully.")
  end
end
