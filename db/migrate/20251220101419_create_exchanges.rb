class CreateExchanges < ActiveRecord::Migration[8.1]
  def change
    create_table :exchanges do |t|
      t.string :code
      t.string :name
      t.json :metadata
      t.timestamps
    end

    add_index :exchanges, :code, unique: true
  end
end
