class AddVerificationPinToAuthentication < ActiveRecord::Migration[6.0]
  def change
    add_column :auth_sessions, :verification_pin, :string
  end
end
