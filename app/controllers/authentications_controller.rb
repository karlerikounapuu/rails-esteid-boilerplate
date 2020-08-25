class AuthenticationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:sign_in]

  def show
    @authentication = AuthSession.find(params[:id])
    render json: @authentication
  end

  def wait_for_handshake
    begin
      @user = User.find_or_create_by(country_alpha3: 'EST', personal_id: authentication_params[:personal_id])
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    @auth_method = authentication_method
    @authentication = AuthSession.new(type: @auth_method, authenticator: authentication_params[:mid_phone])
    @authentication.user = @user

    unless @authentication.valid?
      redirect_to new_user_session_path, notice: 'Select valid authentication method'
      return
    end

    @authentication.save
    cookies.signed[:handshake_uuid] = @authentication.id
    AuthenticationWorker.perform_async(@authentication.id)
    render :wait_for_handshake
  end

  def authorize_by_session
    cookies.delete :handshake_uuid
    @authentication = AuthSession.find(params[:id])
    if @authentication.usable?
      @authentication.mark_as_used!
      sign_in(@authentication.user)

      redirect_to documents_path
    else
      redirect_to new_user_session_path, notice: 'Please reauthenticate yourself'
    end
  end

  def authentication_params
    params.require(:user).permit(:mid_phone, :personal_id)
  end

  def authentication_method
    return 'AuthSessions::SmartId' if params[:channel] == 'smartid'
    return 'AuthSessions::MobileId' if params[:channel] == 'mobileid'
    return 'AuthSessions::IdCard' if params[:channel] == 'idcard'
  end
end
