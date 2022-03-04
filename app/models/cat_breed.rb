class CatBreed < ApplicationRecord
  require 'faker'
  require 'activerecord-import'

   default_scope { order(:name, :breed) }

  class << self
    def make(number_of_records, number_of_random_variables, number_of_alternatives, arity_in_sentence)
      arity_in_sentence = 1 if arity_in_sentence.zero?
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


    alias_method :seed_cat, :make
    alias_method :seed, :make
  end
end
