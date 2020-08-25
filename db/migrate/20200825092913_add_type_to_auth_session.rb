class AddTypeToAuthSession < ActiveRecord::Migration[6.0]
  def change
    add_column :auth_sessions, :type, :text, null: false
  end
end
