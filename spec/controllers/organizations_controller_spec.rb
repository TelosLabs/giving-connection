# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::OrganizationsController, type: :controller do
  before(:each) do
    @admin        = create(:admin_user)
    @organization = create(:organization, creator: @admin) do |organization|
      organization.create(:office_hours, day: 0, open_time: '10:00', close_time: '18:00', closed: true, location: organization.main_location)
      organization.create(:office_hours, day: 1, open_time: '10:00', close_time: '18:00', closed: true, location: organization.main_location)
      organization.create(:office_hours, day: 2, open_time: '10:00', close_time: '18:00', closed: true, location: organization.main_location)
      organization.create(:office_hours, day: 3, open_time: '10:00', close_time: '18:00', closed: true, location: organization.main_location)
      organization.create(:office_hours, day: 4, open_time: '10:00', close_time: '18:00', closed: true, location: organization.main_location)
      organization.create(:office_hours, day: 5, open_time: '10:00', close_time: '18:00', closed: true, location: organization.main_location)
      organization.create(:office_hours, day: 6, open_time: '10:00', close_time: '18:00', location: organization.main_location)
    end
    @params       = { name: 'organization', ein_number: 'testing', irs_ntee_code: 'A90',
                      mission_statement_en: 'testing', mission_statement_es: 'pruebas',
                      vision_statement_en: 'testing', vision_statement_es: 'pruebas',
                      tagline_en: 'testing', tagline_es: 'pruebas',
                      website: 'testing', scope_of_work: 'International' }
  end

  describe 'GET #index' do
    context 'when not logged in' do
      it 'redirects to new admin user session' do
        get :new
        expect(response).to redirect_to admin_user_session_path
      end

      it 'responses with 302 status code' do
        get :new
        expect(response).to have_http_status(302)
      end
    end

    context 'when logged in' do
      before { sign_in @admin }

      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end

      it 'responses with 200 status code' do
        get :new
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #show' do
    context 'when user logged in' do
      before { sign_in @admin }

      it 'should sucessfully render organizations dashboard show page' do
        get :show, params: { id: @organization.id }
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
      end

      it 'responses with 200 status code' do
        get :new
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #new' do
    context 'when not logged in' do
      it 'redirects to new user session' do
        get :new
        expect(response).to redirect_to admin_user_session_path
      end

      it 'responses with 302 status code' do
        get :new
        expect(response).to have_http_status(302)
      end
    end

    context 'when logged in' do
      before { sign_in @admin }

      it 'renders the new template' do
        get :new
        expect(response).to render_template(:new)
      end

      it 'responses with 200 status code' do
        get :new
        expect(response).to have_http_status(200)
      end
    end
  end
end
