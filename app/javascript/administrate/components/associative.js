import $ from 'jquery'
import "selectize/dist/js/standalone/selectize"
import 'selectize/dist/css/selectize.css';

$(document).on("turbo:load", function() {
  $('.field-unit--belongs-to select').selectize({});
  $(".field-unit--has-many select").selectize({});
  $('.field-unit--polymorphic select').selectize({});
})
