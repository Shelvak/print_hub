class AddStockToDocuments < ActiveRecord::Migration[4.2]
  def change
    add_column :documents, :stock, :integer, null: false, default: 0
  end
end
