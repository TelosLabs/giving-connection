module FormHelper
  def errors_for(form, field)
      content_tag(:p, form.object.errors[field].try(:first), class: 'error block text-states-error')
  end

  def form_group_for(form, field, opts={}, &block)
    label = opts.fetch(:label) { true }
    has_errors = form.object.errors[field].present?

    content_tag :div, class: "c-form--group #{'has-error' if has_errors}" do
        if label === true
          concat form.label(field, class: 'control-label')
        elsif label
          concat form.label(label, class: 'control-label')
        end
        concat capture(&block)
        concat errors_for(form, field)
    end
  end
end
