# frozen_string_literal: true

module Admin
  class OrganizationAdminsController < Admin::ApplicationController
    # Linked from the organization show page ("Associate admin user") with
    # ?organization_id=<id> so the form opens pre-scoped to that one
    # organization instead of making the admin pick one out of 5000+ (see
    # OrganizationAdminDashboard's organization field).
    def new
      resource = new_resource(organization_id: params[:organization_id])
      authorize_resource(resource)
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource)
      }
    end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
