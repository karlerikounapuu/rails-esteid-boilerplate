class CreateAuthSessions < ActiveRecord::Migration[6.0]
  def change
    create_table :auth_sessions, id: :uuid do |t|
      t.belongs_to :user, type: :uuid, foreign_key: true, index: true
      t.string :channel, null: false
      t.string :authenticator, null: false
      t.string :session
      t.string :state, null: false, default: 'initialized'
      t.json :precheck_response
      t.json :auth_response

      t.timestamps
    end
  end
end
