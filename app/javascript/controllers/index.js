// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /_controller\.js$/)
const contextComponents = require.context("../../components", true, /_controller\.js$/)
application.load(
  definitionsFromContext(context).concat(
    definitionsFromContext(contextComponents)
  )
)

import { Tabs, Modal, Toggle } from "tailwindcss-stimulus-components"
application.register('tabs', Tabs)
application.register('modal', Modal)
application.register('toggle', Toggle)
