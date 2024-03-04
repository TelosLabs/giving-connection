// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"
import Carousel from 'stimulus-carousel'
import { Autocomplete } from "stimulus-autocomplete"


const application = Application.start()
application.register('carousel', Carousel)
application.register('autocomplete', Autocomplete)
const context = require.context("controllers", true, /_controller\.js$/)
const contextComponents = require.context("../../components", true, /_controller\.js$/)
application.load(
  definitionsFromContext(context).concat(
    definitionsFromContext(contextComponents)
  )
)
