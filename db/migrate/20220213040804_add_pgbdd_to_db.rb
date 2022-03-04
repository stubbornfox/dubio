class AddPgbddToDb < ActiveRecord::Migration[6.0]
  def change
    execute <<-SQL
      drop table if exists Dict;
      drop extension if exists pgbdd cascade;
      create extension pgbdd;
    SQL
  end
end
