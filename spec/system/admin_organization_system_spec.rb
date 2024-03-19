# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Organization System Spec", type: :system, skip: "Needs refactoring" do
  before do
    @admin = create(:admin_user)
    @organization = create(:organization)
    @social_media = create(:social_media, organization: @organization)
    login_as(@admin, scope: :admin_user)
  end

  context "Organization admin index page" do
    before { visit admin_organizations_path }

    it "displays the organizations index panel" do
      expect(page).to have_content "Organizations"
    end
  end

  context "Organization show page" do
    before { visit admin_organization_path(@organization, social_media: @social_media) }

    it "displays specific organization show page" do
      expect(page).to have_content "Show Organization"
    end
  end

  context "Creating new organizaton when form is not correctly filled" do
    before { visit new_admin_organization_path }

    before do
      fill_in("organization_ein_number", with: "161616")
      fill_in("organization_website", with: "www.org.com")
      fill_in("organization_mission_statement_en", with: "mission testing")
      fill_in("organization_vision_statement_en", with: "vision testing")
      fill_in("organization_tagline_en", with: "tagline testing")
      select("A51", from: "organization_irs_ntee_code")
      select("National", from: "organization_scope_of_work")
      attach_file("organization_logo", "#{Rails.root.join("spec/support/images/large_testing.jpg")}")

      click_button "Create Organization"
    end

    it "should flash error message requiring name" do
      sleep(3)
      expect(page).to have_content("Name can't be blank")
    end

    it "should flash error message regarding image size" do
      sleep(3)
      expect(page).to have_content("Must be less than 5MB in size")
    end
  end

  context "Deleting organizaton" do
    before { visit admin_organizations_path }

    before do
      click_link("Destroy")
      alert = page.driver.browser.switch_to.alert
      alert.accept
    end

    it "should redirect to the organizations index page after deleting organization" do
      sleep(3)
      expect(page).to have_content("Organization was successfully destroyed.")
    end

    it "deletes organization" do
      sleep(3)
      expect(Organization.count).to eq 0
    end
  end

  context "Updating organizaton" do
    before { visit edit_admin_organization_path(@organization) }

    before do
      fill_in("organization_name", with: "Testing16")
      fill_in("organization_social_media_attributes_twitter", with: "twitter.com/update")

      sleep 5.seconds

      click_button "Update Organization"
    end

    it "should redirect to the organization show page after updating organization" do
      sleep(3)
      expect(page).to have_content("Organization was successfully updated.")
    end
  end
end
