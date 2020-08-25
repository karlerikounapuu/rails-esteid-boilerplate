class RemoveChannelFromAuthSession < ActiveRecord::Migration[6.0]
  def change
    remove_column :auth_sessions, :channel
  end
end
