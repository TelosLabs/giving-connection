require 'rails_helper'

RSpec.describe 'Admin Organization System Spec', type: :system do
  before(:each) do
    @admin        = create(:admin_user)
    @organization = create(:organization)
    login_as(@admin, scope: :admin_user)
  end

  context 'Organization admin index page' do
    before { visit admin_organizations_path }

    it 'displays the organizations index panel' do
      expect(page).to have_content 'Organizations'
    end
  end

  context 'Organization show page' do
    before { visit admin_organization_path(@organization) }

    it 'displays specific organization show page' do
      expect(page).to have_content 'Show Organization'
    end
  end

  context 'Creating new organizaton when form is correctly filled' do
    before { visit new_admin_organization_path }

    before(:each) do
      fill_in('organization_name',                   with: 'testing')
      fill_in('organization_ein_number',             with: '161616')
      fill_in('organization_website',                with: 'www.org.com')
      fill_in('organization_mission_statement_en',   with: 'mission testing')
      fill_in('organization_vision_statement_en',    with: 'vision testing')
      fill_in('organization_tagline_en',             with: 'tagline testing')
      fill_in('organization_description_en',         with: 'description testing')
      select('A51',                                  from: 'organization_irs_ntee_code')
      select('National',                             from: 'organization_scope_of_work')

      click_button 'Create Organization'
    end

    it 'should redirect to the organization show page after creating new organization' do
      expect(page).to have_content('Organization was successfully created.')
    end

    it 'creates new organization' do
      expect(Organization.count).to eq 2
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

      click_button 'Create Organization'
    end

    it 'should flash error message' do
      expect(page).to have_content('Name can\'t be blank')
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
      fill_in('organization_name', with: 'Testing')
      click_button 'Update Organization'
    end

    it 'should redirect to the organization show page after updating organization' do
      expect(page).to have_content('Organization was successfully updated.')
    end

    it 'updates the organization' do
      expect(Organization.find(@organization.id).name).to eq 'Testing'
    end
  end
end
