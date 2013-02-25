class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.belongs_to :user
      t.belongs_to :account
      t.boolean :admin, null: false, default: false

      t.timestamps
    end
    add_index :memberships, [:user_id, :account_id], unique: true
  end
end
