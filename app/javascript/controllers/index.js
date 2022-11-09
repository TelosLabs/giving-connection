// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"
// import Swiper from 'swiper/css/bundle';
import Carousel from 'stimulus-carousel'


const application = Application.start()
application.register('carousel', Carousel)
const context = require.context("controllers", true, /_controller\.js$/)
const contextComponents = require.context("../../components", true, /_controller\.js$/)
application.load(
  definitionsFromContext(context).concat(
    definitionsFromContext(contextComponents)
  )
)
