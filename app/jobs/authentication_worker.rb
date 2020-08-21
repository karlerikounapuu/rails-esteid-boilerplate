class AuthenticationWorker
  include Sidekiq::Worker

  def perform(auth_id)
    auth = Authentication.find(auth_id)

    case auth.channel
    when 'Mobile-ID'
      if auth.state != 'initialized'
        puts 'Returning because auth has been used'
        return
      end

      auth.authenticate_mid!
      if auth.state == 'AUTH_REQUESTED'
        puts 'Waiting user to complete action'
        auth.wait_mid_result!
        puts 'Waiting time is over.'
      else
        puts "Not waiting for user authentication. reason: #{auth.state}"
      end
    else
      puts "#{auth.channel} is not implemented yet."
    end
  end
end
