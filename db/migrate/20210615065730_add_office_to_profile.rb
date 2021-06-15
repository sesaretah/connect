class AddOfficeToProfile < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :office, :string
  end
end
