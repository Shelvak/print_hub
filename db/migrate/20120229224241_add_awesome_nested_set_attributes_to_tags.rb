class AddAwesomeNestedSetAttributesToTags < ActiveRecord::Migration[4.2]
  def change
    change_table(:tags) do |t|
      t.integer :lft
      t.integer :rgt
      t.integer :depth
    end

    # Tag.rebuild! # Awesome! =) Don't work in rails 4
  end
end
