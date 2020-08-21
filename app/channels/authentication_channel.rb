class AuthenticationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "authentication_session_#{authentication_session.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
