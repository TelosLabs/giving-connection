require "rails_helper"

RSpec.describe ConfirmationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "GET #show" do
    let(:user) { create(:user, confirmed_at: nil) }

    context "with valid confirmation token" do
      it "confirms the user and redirects to root path" do
        get :show, params: {confirmation_token: user.confirmation_token}

        user.reload
        expect(user.confirmed_at).not_to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to be_present
      end

      it "signs in the user after confirmation" do
        get :show, params: {confirmation_token: user.confirmation_token}

        expect(controller.current_user).to eq(user)
      end
    end

    context "with invalid confirmation token" do
      it "renders the new template with errors" do
        get :show, params: {confirmation_token: "invalid_token"}

        expect(response).to render_template(:new)
        expect(response.status).to eq(422)
      end
    end

    context "with already confirmed user" do
      let(:confirmed_user) { create(:user) }

      it "renders the new template with errors" do
        confirmed_user.confirm
        get :show, params: {confirmation_token: confirmed_user.confirmation_token}

        expect(response).to render_template(:new)
        expect(response.status).to eq(422)
      end
    end
  end
end
