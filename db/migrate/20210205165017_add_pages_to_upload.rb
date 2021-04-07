class AddPagesToUpload < ActiveRecord::Migration[5.2]
  def change
    add_column :uploads, :pages, :integer
  end
end
