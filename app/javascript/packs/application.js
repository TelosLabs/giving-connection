// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import '../stylesheets/application'
import 'swiper/swiper-bundle.css';
import Rails from "@rails/ujs"
import * as Turbo from "@hotwired/turbo"
import * as ActiveStorage from "@rails/activestorage"
import "../components"
import "channels"

Rails.start()
ActiveStorage.start()

import "controllers"

window.initMap = function (...args) {
  const event = document.createEvent("Events")
  event.initEvent("google-maps-callback", true, true)
  event.args = args
  window.dispatchEvent(event)
}

document.addEventListener("turbo:load", function (event) {
  window.dataLayer = window.dataLayer || [];

  function gtag() {
    dataLayer.push(arguments);
  }

  gtag('js', new Date());
  gtag('config', 'AW-11382454124');
  gtag('event', 'conversion', { 'send_to': 'AW-11382454124/o0V1CIzO2O8YEOzuybMq' });
}, false);
