class AddVerificationPinToAuthentication < ActiveRecord::Migration[6.0]
  def change
    add_column :authentications, :verification_pin, :string
  end
end
