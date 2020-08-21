# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params

  def wait_for_handshake
    super
    @auth_method = 'Smart-ID'
    %i[smartid mobileid idcard].each do |method|
      @auth_method = method.to_s unless configure_sign_in_params[method]
    end

    render :wait_for_handshake
  end

  # GET /resource/sign_in
  def new
    @user = User.new
    super
  end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:smartid, :mobileid, :idcard, :personal_id, :mid_phone])
  end
end
