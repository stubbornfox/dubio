class CatBreed < ApplicationRecord
  require 'faker'
  require 'activerecord-import'

   default_scope { order(:name, :breed) }

  class << self
    def make(number_of_records, number_of_random_variables=nil, number_of_alternatives=nil, arity_in_sentence=nil)
      arity_in_sentence = 1 if arity_in_sentence.to_i.zero?
      cat_names = Set.new

      CatBreed.in_batches.delete_all

      number_of_random_variables = number_of_records if number_of_random_variables.to_i.zero?
      Dict.my_dict.create_rva(number_of_random_variables, number_of_alternatives)
      cat_breeds = []
      dicts = Dict.my_dict.rva

      puts dicts

      i = 0
      n = 0

      while n < number_of_records do
        begin
          name = [Faker::Name.male_first_name, Faker::Name.female_first_name].sample
        end while name.in? cat_names

        cat_names << name

        breeds = Set.new
        if arity_in_sentence == 1
          alternatives = dicts.sample.split(';')
          alternatives.each do |a|
            bdd = a.split(':')[0]
            begin
              breed = Faker::Creature::Cat.breed
            end while breed.in? breeds
            breeds << breed
            cat_breeds << CatBreed.new(name: name, breed: breed, sentence: bdd)
            n += 1
            break if n == number_of_records
          end
        else
          alternatives = rand(1..4)
          sentences = SentenceGenerator.new(alternatives, arity_in_sentence).make
          sentences.each do |sentence|
            begin
              breed = Faker::Creature::Cat.breed
            end while breed.in? breeds
            breeds << breed
            cat_breeds << CatBreed.new(name: name, breed: breed, sentence: sentence)
            n += 1
            break if n == number_of_records
          end
        end

        puts i
        i += 1
      end
      self.import cat_breeds
    end


    def make_experiment_b(number_of_records, number_of_random_variables)
      CatBreed.in_batches.delete_all

      number_of_alternatives = 1
      Dict.my_dict.create_rva(number_of_random_variables, number_of_alternatives)
      cat_breeds = []
      dicts = Dict.my_dict.rva_pairs

      number_of_records.times do |index|
        name = Faker::Name.male_first_name
        breed = Faker::Creature::Cat.breed
        rva = dicts[index % number_of_random_variables]
        cat_breeds << CatBreed.new(name: name, breed: breed, sentence: rva)
      end
      self.import cat_breeds
    end

    def make_experiment_c(number_of_records, number_of_alternatives)
      CatBreed.in_batches.delete_all

      number_of_random_variables = 3
      Dict.my_dict.create_rva(number_of_random_variables, number_of_alternatives)
      cat_breeds = []
      dicts = Dict.my_dict.rva_pairs
      length_dict = dicts.length
      number_of_records.times do |index|
        name = Faker::Name.male_first_name
        breed = Faker::Creature::Cat.breed
        rva = dicts[index % length_dict]
        cat_breeds << CatBreed.new(name: name, breed: breed, sentence: rva)
      end
      self.import cat_breeds
    end

    def make_experiment_d(number_of_records, n_arity)
      CatBreed.in_batches.delete_all

      number_of_random_variables = number_of_records
      number_of_alternatives = 2
      Dict.my_dict.create_rva(number_of_random_variables, number_of_alternatives)
      cat_breeds = []
      dicts = Dict.my_dict.rva_pairs
      sentences = SentenceGenerator.new(number_of_records, n_arity).make
      sentences.each do |sentence|
        name = Faker::Name.male_first_name
        breed = Faker::Creature::Cat.breed
        cat_breeds << CatBreed.new(name: name, breed: breed, sentence: sentence)
      end
      self.import cat_breeds
    end

    def all_with_prob
      sql = "select cat_breeds.name, cat_breeds.breed, sentence, round(prob(dict, cat_breeds.sentence)::numeric,5) as prob from cat_breeds, dicts where dicts.name='mydict';"
      all_cats = ActiveRecord::Base.connection.execute(sql)
    end

    def exact_count
      sql = "select exact_count('select * from cat_breeds');"
      ActiveRecord::Base.connection.execute(sql)
    end


    alias_method :seed_cat, :make
    alias_method :seed, :make
  end
end
