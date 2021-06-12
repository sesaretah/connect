class AddModeratorIdsToRooms < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :moderator_ids, :json
  end
end
