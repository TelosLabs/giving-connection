require "system_helper"

RSpec.describe "User Registration", type: :system do
  it "can register" do
    visit signup_path

    find(:test_id, "signup_name_input").fill_in with: "Jane Doe"
    find(:test_id, "signup_email_input").fill_in with: "jane@example.com"
    find(:test_id, "signup_password_input").fill_in with: "password"
    find(:test_id, "signup_password_confirmation_input").fill_in with: "password"
    click_button "signup_submit_btn"

    expect(page).to have_content("Welcome! You have signed up successfully.")
  end
end
