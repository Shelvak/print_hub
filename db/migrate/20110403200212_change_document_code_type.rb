class ChangeDocumentCodeType < ActiveRecord::Migration[4.2]
  def self.up
    change_column :documents, :code, :integer, null: false, using: 'code::integer'
  end

  def self.down
    change_column :documents, :code, :string, null: false
  end
end
