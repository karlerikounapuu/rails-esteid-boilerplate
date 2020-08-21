import consumer from "./consumer"
import alertify from "alertifyjs";

$(document).on('turbolinks:load', function() {
  if (this.subscription) {
      consumer.subscriptions.remove(this.subscription);
  }

  if (document.getElementById("handshake-code")) {
      var subscription = consumer.subscriptions.create("AuthenticationChannel", {
        connected() {
          var obj = null;
        },
        disconnected() {
          var obj = null;
        },
        received(data) {

          console.log(data);
          var obj = JSON.parse(data)
          if(obj['state'] == 'INIT') {
            return;
          } else if(obj['state'] == 'AUTH_REQUESTED') {
            document.getElementById('handshake-code').innerText = obj['pin'];
            document.getElementById('handshake-message').innerText = obj['message'];
          } else if(obj['state'] == 'AUTH_SUCCEEDED') {
            consumer.subscriptions.remove(subscription);
            document.getElementById('handshake-message').innerText = obj['message'];
            window.location.replace(obj['redirect'])
          } else {
            document.getElementById('handshake-code').innerText = 'Auth failed.';
            document.getElementById('handshake-message').innerText = obj['message'];
            $('#action-button').html("<a class='btn btn-primary btn-block' href=" + obj['redirect_back'] + ">Back to login page</a")
          }
      }});

      this.subscription = subscription;
  }

});