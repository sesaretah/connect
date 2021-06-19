class CreateDisplays < ActiveRecord::Migration[5.2]
  def change
    create_table :displays do |t|
      t.integer :user_id
      t.integer :room_id
      t.integer :position

      t.timestamps
    end
  end
end
