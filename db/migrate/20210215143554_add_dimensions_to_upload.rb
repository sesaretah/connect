class AddDimensionsToUpload < ActiveRecord::Migration[5.2]
  def change
    add_column :uploads, :dimensions, :json
  end
end
