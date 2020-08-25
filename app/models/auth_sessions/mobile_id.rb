module AuthSessions
  class MobileId < AuthSession

    def authenticate_mid!
      digest = OpenSSL::Digest::SHA256.digest(SecureRandom.hex)
      create_verification_pin!(digest)
      mid_hash = hash_from_digest(digest)
      mid_auth_request!(mid_hash)
    end

    def create_verification_pin!(digest)
      bits = digest.unpack1('B*')
      code = "#{bits.split(//).first(6).join}#{bits.split(//).last(7).join}".to_i(2).to_s
      update(verification_pin: code.length == 3 ? "0#{code}" : code.to_s)
    end

    def hash_from_digest(digest)
      encoded_hash = Base64.encode64(digest)
      encoded_hash = encoded_hash.sub("\n", '').strip

      encoded_hash
    end

    def mid_auth_request!(mid_hash)
      destination = "#{ENV['mid_api_base_url']}/authentication"
      headers = { content_type: :json, accept: :json }

      payload = {
        relyingPartyUUID: ENV['mid_api_rp_uuid'],
        relyingPartyName: ENV['mid_api_rp_name'],
        phoneNumber: "+372#{authenticator}",
        nationalIdentityNumber: user.personal_id,
        hash: mid_hash,
        hashType: 'SHA256',
        language: 'EST',
        displayText: 'Log in to Broilerplate',
        displayTextFormat: 'GSM-7'
      }.to_json

      response = RestClient.post destination, payload, headers
      body = JSON.parse(response.body)

      self.session = body['sessionID'] if body['sessionID']
      self.precheck_response = body
      self.state = 'AUTH_REQUESTED' if session

      save!
      broadcast_pin_to_channel!
    rescue RestClient::ExceptionWithResponse => e
      puts e.response
      self.precheck_response = e
      self.state = 'AUTH_FAILURE'

      save!
      broadcast_error_to_channel!
    end

    def broadcast_error_to_channel!
      message = "Authentication failed. #{precheck_response['error']}"
      redirect_uri = Rails.application.routes.url_helpers.new_user_session_path
      redirect_uri = "http://localhost:3000#{redirect_uri}"

      ActionCable.server.broadcast(
        "authentication_session_#{id}",
        { state: state, message: message, redirect_back: redirect_uri }.to_json
      )
    end

    def broadcast_pin_to_channel!
      puts 'Going to broadcast PIN to channel'
      ActionCable.server.broadcast(
        "authentication_session_#{id}",
        { state: 'INIT' }.to_json
      )

      message = "We've sent authentication request to +372#{authenticator}. If the verification code is #{verification_pin}, please enter your PIN1."
      ActionCable.server.broadcast(
        "authentication_session_#{id}",
        { state: 'AUTH_REQUESTED', pin: verification_pin, message: message }.to_json
      )
    end

    def broadcast_success_to_channel!
      message = 'Thanks. Looking great! Logging you in...'
      redirect_uri = Rails.application.routes.url_helpers.authorize_eid_session_path(id)
      redirect_uri = "http://localhost:3000#{redirect_uri}"
      ActionCable.server.broadcast(
        "authentication_session_#{id}",
        { state: state, message: message, redirect: redirect_uri }.to_json
      )
    end

    def broadcast_user_error_to_channel!
      why = case auth_response['result']
            when 'TIMEOUT'
              'Did not receive response within reasonable period.'
            when 'NOT_MID_CLIENT'
              "Appears like you're not Mobile-ID client."
            when 'USER_CANCELLED'
              "Seems like you've canceled authentication operation."
            when 'SIGNATURE_HASH_MISMATCH'
              "There's something wrong with your Mobile-ID. Contact your operator."
            when 'PHONE_ABSENT'
              'Failed to locate your phone. Is it turned on?'
            when 'DELIVERY_ERROR'
              'Failed to send authentication SMS. Please try again'
            when 'SIM_ERROR'
              "We're received gibberish in return. Please try again."
            else
              "Failed to authenticate and we don't know why. Please try again."
            end

      redirect_uri = Rails.application.routes.url_helpers.new_user_session_path
      redirect_uri = "http://localhost:3000#{redirect_uri}"

      ActionCable.server.broadcast(
        "authentication_session_#{id}",
        { state: state, message: why, redirect_back: redirect_uri }.to_json
      )
    end

    def populate_person_name!
      cert_bin = Base64.decode64(auth_response['cert'])
      cert = OpenSSL::X509::Certificate.new(cert_bin)
      first_name = cert.subject.to_a[3][1]
      last_name = cert.subject.to_a[2][1]
      user.update(first_name: first_name, last_name: last_name)
    end

    def wait_mid_result!
      destination = "#{ENV['mid_api_base_url']}/authentication/session/#{session}?timeoutMs=60000"
      headers = { accept: :json }

      puts 'Sending request'
      response = RestClient.get destination, headers
      body = JSON.parse(response.body)
      puts response.code

      self.auth_response = body
      self.state = 'AUTH_USER_ERROR'
      if body['state'] == 'COMPLETE' && body['result'] == 'OK'
        self.state = 'AUTH_SUCCEEDED'
      end

      save!

      if state == 'AUTH_SUCCEEDED'
        populate_person_name!
        broadcast_success_to_channel!
      else

        broadcast_user_error_to_channel!
      end
    rescue StandardError
      self.state = 'AUTH_FAILURE'
      self.auth_response = { result: 'TIMEOUT' }.to_json
      save!
      broadcast_user_error_to_channel!
    end
  end
end
