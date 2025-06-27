// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"
import Carousel from '@stimulus-components/carousel'
import { Autocomplete } from "stimulus-autocomplete"
import { Dropdown } from "tailwindcss-stimulus-components"

const application = Application.start()
application.register('carousel', Carousel)
application.register('autocomplete', Autocomplete)
application.register('dropdown', Dropdown)
application.register("calendar-component", CalendarComponentController)
const context = require.context(".", true, /_controller\.js$/)
const contextComponents = require.context("../../components", true, /_controller\.js$/)
application.load(
  definitionsFromContext(context).concat(
    definitionsFromContext(contextComponents)
  )
)

document.addEventListener("show-unsaved-modal", (e) => {
  const controllerElement = document.querySelector('[data-controller~="halt-navigation-on-change"]');

  // Use Stimulus API to get controller instance
  const controller = application.getControllerForElementAndIdentifier(controllerElement, "halt-navigation-on-change");

  if (controller) controller.displayModalOnChange(e);
});