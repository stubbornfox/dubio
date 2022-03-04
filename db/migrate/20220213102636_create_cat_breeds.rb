class CreateCatBreeds < ActiveRecord::Migration[6.0]
  enable_extension 'pgbdd' unless extension_enabled?('pgbdd')

  def change
    create_table :cat_breeds do |t|
      t.string :name
      t.string :breed
      t.column :sentence, :bdd

      t.timestamps
    end
  end
end
