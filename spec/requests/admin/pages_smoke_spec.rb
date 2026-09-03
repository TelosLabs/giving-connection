require "rails_helper"

# Renders every Administrate page once. The admin views override many
# administrate templates, so gem upgrades break them silently otherwise.
RSpec.describe "Admin pages", type: :request do
  include Devise::Test::IntegrationHelpers

  routes = Administrate::Namespace.new(:admin).routes.to_set

  # Admin::CategoriesController has no Category model or dashboard behind it.
  dead_resources = %w[categories]

  record_builders = {
    location: -> { create(:location, :with_office_hours) },
    office_hour: -> { create(:office_hour, location: create(:location, :with_office_hours)) }
  }

  before { sign_in create(:admin_user) }

  Administrate::Namespace.new(:admin).resources.each do |resource|
    name = resource.to_s
    next if dead_resources.include?(name)

    factory = name.singularize.to_sym
    build_record = record_builders.fetch(factory) { -> { create(factory) } }
    has_factory = FactoryBot.factories.registered?(factory)

    describe name do
      if routes.include?([name, "index"])
        it "renders index" do
          get "/admin/#{name}"
          expect(response).to have_http_status(:ok)
        end
      end

      if routes.include?([name, "new"])
        it "renders new" do
          get "/admin/#{name}/new"
          expect(response).to have_http_status(:ok)
        end
      end

      if has_factory && routes.include?([name, "show"])
        it "renders show" do
          get "/admin/#{name}/#{instance_exec(&build_record).id}"
          expect(response).to have_http_status(:ok)
        end
      end

      if has_factory && routes.include?([name, "edit"])
        it "renders edit" do
          get "/admin/#{name}/#{instance_exec(&build_record).id}/edit"
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
