class OrganizationFormPresenter
  # Make sure to assign to :data option
  def change_detection_form_container_setup
    {
      controller: "detect-form-changes halt-navigation-on-change",
      detect_form_changes_input_types_value: "input, textarea, select",
      halt_navigation_on_change_modal_container_id_value: "main-modal-container",
      halt_navigation_on_change_discard_option_id_value: "discard-changes-option",
      halt_navigation_on_change_is_saving_value: false,
      action: "turbo:before-visit@document->halt-navigation-on-change#displayModalOnChange"
    }
  end

  def change_detection_form_setup
    {
      detect_form_changes_target: "form",
      halt_navigation_on_change_target: "form",
      action: "input->detect-form-changes#captureUserInput change->detect-form-changes#captureUserInput \
      nested-form:domupdate->detect-form-changes#captureDOMUpdate"
    }
  end
end
