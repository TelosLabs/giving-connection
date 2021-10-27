# frozen_string_literal: true

module Admin
  class OrganizationsController < Admin::ApplicationController
    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    def new
      resource = new_resource
      authorize_resource(resource)
      resource.build_social_media
      resource.build_main_location
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource)
      }
    end

    def create
      resource = resource_class.new(resource_params)
      # binding.pry
      resource.creator = current_admin_user
      authorize_resource(resource)
      if resource.save
        redirect_to([namespace, resource], notice: translate_with_resource('create.success'))
      else
        render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) }, status: :unprocessable_entity
      end
    end

    def update
      requested_resource.creator = current_admin_user
      requested_resource.update(resource_params)
      if requested_resource
        redirect_to([namespace, requested_resource], notice: translate_with_resource('update.success'))
      else
        render :edit, locals: { page: Administrate::Page::Form.new(dashboard, requested_resource) },
                      status: :unprocessable_entity
      end
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
    def resource_params
      permit = dashboard.permitted_attributes << {
        social_media_attributes: %i[facebook instagram twitter linkedin youtube blog],
        main_location_attributes: %i[address latitude longitude website main physical offer_services]
      }

      params.require(resource_class.model_name.param_key)
            .permit(permit)
            .transform_values { |value| value == '' ? nil : value }
    end

    # See https://administrate-prototype.herokuapp.com/customizing_controller_actions
    # for more information
  end
end
