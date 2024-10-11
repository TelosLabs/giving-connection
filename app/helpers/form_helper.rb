# frozen_string_literal: true

# Helper module for error messages in forms
module FormHelper
  def errors_for(form, field)
    content_tag(:p, form.object.errors[field].try(:first), class: "error block text-states-error")
  end

  def errors_label(form, label, field)
    return form.label(field, class: "control-label") if label == true
    form.label(label, class: "control-label") if label
  end

  def form_group_for(form, field, opts = {}, &block)
    label = opts.fetch(:label, true)
    has_errors = form.object.errors[field].present?

    content_tag :div, class: "c-form--group #{"has-error" if has_errors}" do
      concat errors_label(form, label, field)
      concat capture(&block)
      concat errors_for(form, field)
    end
  end
end
