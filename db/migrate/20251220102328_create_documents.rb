class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :doc_type
      t.string :title
      t.string :s3_key
      t.json :metadata
      t.references :stock, null: false, foreign_key: true

      t.timestamps
    end
  end
end
