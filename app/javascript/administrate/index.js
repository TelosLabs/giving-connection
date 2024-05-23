import './components/table'
import './components/date_time_picker'
import './components/associative'
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"
import "controllers"
import UniquenessWarningController from "./controllers/uniqueness_warning_controller"

const application = Application.start()
const context = require.context("controllers", true, /_controller\.js$/)
application.load(definitionsFromContext(context))
application.register("uniqueness-warning", UniquenessWarningController)


