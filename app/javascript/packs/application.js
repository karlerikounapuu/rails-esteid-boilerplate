require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
require("alertifyjs")
import "bootstrap";
import "../stylesheets/application";
import 'bootstrap/dist/js/bootstrap';

import alertify from 'alertifyjs';
global.alertify = alertify;

document.addEventListener("turbolinks:load", () => {
  $('[data-toggle="tooltip"]').tooltip()
  $('[data-toggle="popover"]').popover()
})