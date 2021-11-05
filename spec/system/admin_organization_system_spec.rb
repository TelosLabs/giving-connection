# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Organization System Spec', type: :system do
  before(:each) do
    @admin        = create(:admin_user)
    @organization = create(:organization)
    @social_media = create(:social_media, organization: @organization)
    login_as(@admin, scope: :admin_user)
  end

  context 'Organization admin index page' do
    before { visit admin_organizations_path }

    it 'displays the organizations index panel' do
      expect(page).to have_content 'Organizations'
    end
  end

  context 'Organization show page' do
    before { visit admin_organization_path(@organization, social_media: @social_media) }

    it 'displays specific organization show page' do
      expect(page).to have_content 'Show Organization'
    end
  end

  context 'Creating new organizaton when form is correctly filled' do
    before { visit new_admin_organization_path }

    before(:each) do
      fill_in('organization_name',                             with: 'testing')
      fill_in('organization_ein_number',                       with: '161616')
      fill_in('organization_website',                          with: 'www.org.com')
      fill_in('organization_mission_statement_en',             with: 'mission testing')
      fill_in('organization_vision_statement_en',              with: 'vision testing')
      fill_in('organization_tagline_en',                       with: 'tagline testing')
      fill_in('organization_description_en',                   with: 'description testing')
      fill_in('organization_social_media_attributes_facebook', with: 'facebook.com/test')
      # fill_in('tags_attributes',                               with: 'special care')
      select('A51',                                            from: 'organization_irs_ntee_code')
      select('National',                                       from: 'organization_scope_of_work')
      # select('Advocacy',                                       from: 'organization_category_ids')
      attach_file('organization_logo', "#{Rails.root}/spec/support/images/testing.png")

      click_button 'Create Organization'
    end

    it 'should redirect to the organization show page after creating new organization' do
      expect(page).to have_content('Organization was successfully created.')
    end

    it 'creates new organization' do
      sleep(3)
      expect(Organization.count).to eq 2
    end

    it 'creates social media associated with organization' do
      sleep(3)
      expect(Organization.last.social_media.facebook).to eq('facebook.com/test')
    end

    it 'attaches a default cover photo' do
      expect(Organization.last.cover_photo.attached?).to eq(true)
    end

    it 'attaches the uploaded logo when file is provided' do
      sleep(3)
      expect(Organization.last.logo.blob.filename).to eq('testing.png')
    end
  end

  context 'Creating new organizaton when form is not correctly filled' do
    before { visit new_admin_organization_path }

    before(:each) do
      fill_in('organization_ein_number',             with: '161616')
      fill_in('organization_website',                with: 'www.org.com')
      fill_in('organization_mission_statement_en',   with: 'mission testing')
      fill_in('organization_vision_statement_en',    with: 'vision testing')
      fill_in('organization_tagline_en',             with: 'tagline testing')
      fill_in('organization_description_en',         with: 'description testing')
      select('A51',                                  from: 'organization_irs_ntee_code')
      select('National',                             from: 'organization_scope_of_work')
      attach_file('organization_logo', "#{Rails.root}/spec/support/images/large_testing.jpg")

      click_button 'Create Organization'
    end

    it 'should flash error message requiring name' do
      expect(page).to have_content('Name can\'t be blank')
    end

    it 'should flash error message regarding image size' do
      expect(page).to have_content('Must be less than 5MB in size')
    end
  end

  context 'Deleting organizaton' do
    before { visit admin_organizations_path }

    before(:each) do
      click_link('Destroy')
      alert = page.driver.browser.switch_to.alert
      alert.accept
    end

    it 'should redirect to the organizations index page after deleting organization' do
      expect(page).to have_content('Organization was successfully destroyed.')
    end

    it 'deletes organization' do
      expect(Organization.count).to eq 1
    end
  end

  context 'Updating organizaton' do
    before { visit  edit_admin_organization_path(@organization) }

    before(:each) do
      fill_in('organization_name',                             with: 'Testing16')
      fill_in('organization_social_media_attributes_twitter',  with: 'twitter.com/update')

      sleep 5.seconds

      click_button 'Update Organization'
    end

    it 'should redirect to the organization show page after updating organization' do
      expect(page).to have_content('Organization was successfully updated.')
    end

    # it 'updates the organization name' do
    #   expect(@organization.name).to eq 'Testing'
    # end

    # it 'updates the organization twitter' do
    #   expect(Organization.last.social_media.twitter).to eq 'twitter.com/update'
    # end
  end
end
