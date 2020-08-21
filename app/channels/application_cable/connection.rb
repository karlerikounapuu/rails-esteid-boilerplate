module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :authentication_session

    def connect
      self.authentication_session = find_authentication_session
    end

    def find_authentication_session
      auth = Authentication.find(cookies.signed[:handshake_uuid])

      auth
    rescue StandardError
      reject_unauthorized_connection
    end
  end
end
