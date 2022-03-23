class CreateAlgorithms < ActiveRecord::Migration[6.0]
  def change
    create_table :algorithms do |t|
      t.string :name
      t.text :code

      t.timestamps
    end
  end
end
