import './components/table'
import './components/date_time_picker'
import './components/associative'
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"
import "controllers"

const application = Application.start()
const context = require.context("controllers", true, /_controller\.js$/)
application.load(definitionsFromContext(context))
