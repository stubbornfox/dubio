require 'set'

class Dict < ApplicationRecord
  class << self
    def my_dict
      Dict.first || Dict.create(name: 'mydict', dict: '')
    end

    alias_method :mydict, :my_dict
  end

  #"[Dictionary(#vars=1000, #values=2020)]"
  def values_size
    (self.dict.scan(/#values=(\d+)/)[0][0]).to_i
  end

  def vars_size
    (self.dict.scan(/#vars=(\d+)/)[0][0]).to_i
  end

  def create_rva(number_of_random_variables=1, number_of_alternatives=nil)
    rva_str = RvaGenerator.rva_str(number_of_random_variables, number_of_alternatives)
    self.clear
    self.add_rva(rva_str)
  end

  def clear
    self.update('dict': '')
  end


  def rva
    query = <<-SQL
      select print(dict) from Dicts
      where name='#{self.name}';
    SQL
    pairs = self.execute_sql(query).values[0][0].split(" \n")
    return pairs
  end

  def rva_pairs
    rva.map{|rva| rva.split(';')}.flatten.map{|r| r.split(':')[0].strip}
  end

  def rvs
    rva.map{|rva| rva.split(';')}.flatten.map{|r| r.split('=')[0].strip}.uniq
  end

  def rvs
    rva.map{|rva| rva.split(';')}.flatten.map{|r| r.split('=')[0].strip}.uniq
  end

  def rva_hash
    rhash = Hash.new { |hash, key| hash[key] = [] }
    rva.each do |irva|
      r = irva.split(';').first.split('=')[0]
      rhash[r]=irva
    end
    rhash
  end

  def add_rva(rva_str)
    query = <<-SQL
      update Dicts
      set dict=add(dict,'#{rva_str}')
      where name='#{self.name}';
    SQL

    self.execute_sql(query)
  end

  def update_rva(rva_str)
    query = <<-SQL
      update Dicts
      set dict=upd(dict,'#{rva_str}')
      where name='#{self.name}';
    SQL

    self.execute_sql(query)
  end

  def delete_rva(rva_str)
    query = <<-SQL
      update Dicts
      set dict=del(dict,'#{rva_str}')
      where name='#{self.name}';
    SQL

    self.execute_sql(query)
  end

  def delete_rv(rv)
    query = <<-SQL
      update Dicts
      set dict=del(dict,'#{rv}: *')
      where name='#{self.name}';
    SQL

    self.execute_sql(query)
  end
end

