require "system_helper"

RSpec.describe "User Login", type: :system do
  before do
    @user = create(:user)
  end

  it "can log in" do
    visit signin_path

    find(:test_id, "user_login_email_input").fill_in with: @user.email
    find(:test_id, "user_login_password_input").fill_in with: "wrong password"
    click_button "user_login_submit_btn"
    expect(page).to have_content("Invalid Email or password.")

    find(:test_id, "user_login_password_input").fill_in with: @user.password
    click_button "user_login_submit_btn"

    expect(page).to have_content("Signed in successfully.")
  end

  it "can log out" do
    sign_in(@user)
    visit my_account_path

    find(:test_id, "user_logout_link").click

    within(:test_id, "flash_messages") do
      expect(page).to have_text("Signed out successfully.")
    end
  end
end
