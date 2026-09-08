# Vendored from TelosLabs/administrate-field-nested_has_many
# (branch feature/stimulus-controller, v2.1.0). The gem caps administrate < 1
# and is unmaintained upstream, so the field lives in the app now. Partials:
# app/views/fields/nested_has_many/. JS relies on @nathanvda/cocoon from the
# webpack admin pack, not the gem's sprockets bundle.
module Administrate
  module Field
    class NestedHasMany < Administrate::Field::HasMany
      DEFAULT_ATTRIBUTES = %i[id _destroy].freeze

      def nested_fields
        all_fields = associated_form.attributes.values.flatten

        all_fields.reject do |nested_field|
          skipped_fields.include?(nested_field.attribute)
        end
      end

      def nested_fields_for_builder(form_builder)
        return nested_fields unless form_builder.index.is_a? Integer

        nested_fields.each do |nested_field|
          next if nested_field.resource.blank?

          # inject current data into field
          resource = data[form_builder.index]
          nested_field.instance_variable_set(
            :@data,
            resource.send(nested_field.attribute)
          )
        end
      end

      def to_s
        data
      end

      def self.dashboard_for_resource(resource_class, attr)
        "#{associated_class_name(resource_class, attr)}Dashboard".constantize
      end

      def self.associated_attributes(resource_class, attr)
        dashboard_class = dashboard_for_resource(resource_class, attr)
        DEFAULT_ATTRIBUTES + dashboard_class.new.permitted_attributes
      end

      def self.permitted_attribute(attr, options = {})
        {
          "#{attr}_attributes": associated_attributes(options[:resource_class], attr)
        }
      end

      def associated_class_name
        self.class.associated_class_name(resource.class, attribute)
      end

      def association_name
        options.fetch(:association_name) do
          associated_class_name.underscore.pluralize[/([^\/]*)$/, 1]
        end
      end

      def associated_form
        Administrate::Page::Form.new(associated_dashboard, new_resource)
      end

      private

      def new_resource
        @new_resource ||= associated_class.new
      end

      def skipped_fields
        Array(options[:skip])
      end
    end
  end
end
