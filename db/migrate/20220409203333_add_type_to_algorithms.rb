class AddTypeToAlgorithms < ActiveRecord::Migration[6.0]
  def change
    add_column :algorithms, :type_of_count, :string
  end
end
