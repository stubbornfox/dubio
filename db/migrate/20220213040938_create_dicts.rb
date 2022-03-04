class CreateDicts < ActiveRecord::Migration[6.0]
  enable_extension 'pgbdd' unless extension_enabled?('pgbdd')

  def change
    create_table :dicts do |t|
      t.string :name
      t.column :dict, :dictionary

      t.timestamps
    end
  end
end
