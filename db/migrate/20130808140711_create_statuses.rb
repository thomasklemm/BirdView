class CreateStatuses < ActiveRecord::Migration
  def change
    create_table :statuses do |t|
      t.text :token
      t.text :text

      t.belongs_to :project, index: true
      t.belongs_to :user
      t.belongs_to :twitter_account

      t.boolean :published, default: false

      t.integer :in_reply_to_status_id, limit: 8

      t.timestamps
    end

    add_index :statuses, :token, unique: true
  end
end
