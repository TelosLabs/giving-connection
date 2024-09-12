// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import '../stylesheets/application'
import 'swiper/css/bundle'
import Rails from "@rails/ujs"
import * as Turbo from "@hotwired/turbo"
import * as ActiveStorage from "@rails/activestorage"
import "../components"
import "../channels"
import filterStore from "../utils/filterStore"
import "../controllers"

Rails.start()
ActiveStorage.start()


window.initMap = function (...args) {
  const event = new CustomEvent("google-maps-callback", {
    detail: args,
    bubbles: true,
    cancelable: true
  });
  window.dispatchEvent(event);
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
