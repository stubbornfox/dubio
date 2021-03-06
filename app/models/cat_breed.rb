class CatBreed < ApplicationRecord
  require 'faker'
  require 'activerecord-import'

   # default_scope { order(:name, :breed) }

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

    def create_list(cats)
      cats = cats.map{ |(name, breed, bdd)| CatBreed.new(name: name, breed: breed, sentence: bdd) }
      self.import cats
    end

    def make_experiment_b(number_of_records, n_rv)
      CatBreed.in_batches.delete_all
      n_tuples = 0
      cats = []
      cat_name_index = 0

      while n_tuples < number_of_records
        RVA_50[0...n_rv].each_with_index do |rv, _|
          rv.each_with_index do |rva, breed_index|
            cats << [CAT_NAME[cat_name_index], CAT_BREED[breed_index], rva]
          end
          n_tuples += rv.size
          cat_name_index += rv.size
        end
      end
      create_list cats[0...number_of_records]
    end

    def make_experiment_c(number_of_records, number_of_alternatives)
      CatBreed.in_batches.delete_all

      number_of_random_variables = number_of_records
      Dict.my_dict.create_rva(number_of_random_variables, number_of_alternatives)

      cats = []
      dicts = Dict.my_dict.rva_pairs
      length_dict = dicts.length
      offset_d = 0

      while cats.size < number_of_records do
        j = 0
        number_of_records.times do |i|
          rva = dicts[i*number_of_alternatives + j]
          cats << [CAT_NAME[i], CAT_BREED[i], rva]
        end
        j += 1
      end
      create_list cats[0...number_of_records]
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
      sql = "select cat_breeds.id, cat_breeds.name, cat_breeds.breed, sentence, round(prob(dict, cat_breeds.sentence)::numeric,5) as prob from cat_breeds, dicts where dicts.name='mydict';"
      all_cats = ActiveRecord::Base.connection.execute(sql)
    end

    def exact_count
      sql = "select count, agg_or(sentence) as bdd from dicts, comb_count('select sentence from cat_breeds', dict) where dicts.name='mydict'
              group by count;"
      ActiveRecord::Base.connection.execute(sql)
    end

    def hist_count(bin)
      sql = "select hist_count('select * from cat_breeds', #{bin});"
      ActiveRecord::Base.connection.execute(sql)
    end

    def top_count(k)
      sql = "select (q.c).count, bdd(STRING_AGG((q.c).sentence, '|')) as bdd from (select unnest(count_on_topk_worlds(top_k_worlds(dict, #{k}), sentence)) as c from cat_breeds, dicts where dicts.name='mydict') q group by count;"
      ActiveRecord::Base.connection.execute(sql)
    end

    def top_5_count
      sql="select (q.c).count, bdd(STRING_AGG((q.c).sentence, '|')) as bdd from (select unnest(count_on_topk_worlds(top_k_worlds(dict, 5), sentence)) as c from cat_breeds, dicts where dicts.name='mydict') q group by count;"
      ActiveRecord::Base.connection.execute(sql)
    end

    def top_10_count
      sql="select (q.c).count, bdd(STRING_AGG((q.c).sentence, '|')) as bdd from (select unnest(count_on_topk_worlds(top_k_worlds(dict, 10), sentence)) as c from cat_breeds, dicts where dicts.name='mydict') q group by count;"
      ActiveRecord::Base.connection.execute(sql)
    end

    def possible_world_count
      sql = "select * from count_on_possible_worlds('select * from cat_breeds', (select dict from dicts where dicts.name='mydict')) order by count desc;";
      ActiveRecord::Base.connection.execute(sql)
    end

    def count
      sql ="select (q.c).count, agg_or((q.c).sentence) as bdd from (select unnest(count_worlds(cat_breeds.sentence,  dicts.dict)) as c FROM cat_breeds, dicts where dicts.name='mydict') q group by count;"
      ActiveRecord::Base.connection.execute(sql)
    end

    alias_method :seed_cat, :make
    alias_method :seed, :make
  end
end
