class RemoveChannelFromAuthSession < ActiveRecord::Migration[6.0]
  def up
    remove_column :auth_sessions, :channel
  end

  def down
    add_column :auth_sessions, :channel, :string
  end
end
