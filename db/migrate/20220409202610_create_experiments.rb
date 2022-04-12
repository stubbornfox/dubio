class CreateExperiments < ActiveRecord::Migration[6.0]
  def change
    create_table :experiments do |t|
      t.string :name
      t.string :description
      t.json :result
      t.references :algorithm, null: false, foreign_key: true
    end
  end
end
