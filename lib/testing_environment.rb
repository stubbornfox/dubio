require 'timeout'

class TestingEnvironment
  attr_accessor :experiment, :algo_name, :algo_code

  def initialize(algo_name=nil, algo_code=nil)
    # self.experiment = Experiment.new
    self.algo_name = algo_name
    self.algo_code = algo_code
  end

  def create_count_func
    queries = <<-SQL
      create or replace function exact_count(osql text)
      returns  setof holder
      language plpgsql
      as
      $$
      declare
         i integer;
         j integer;

         counter integer;
         count integer;

         total_combination integer;

         record_indexes integer[];
         record_bdds bdd[];

         combination integer[];
         combination_length integer;
         combination_bdd bdd;

         count_bdds bdd[];
         r holder%rowtype;
      begin
         EXECUTE osql INTO count;
         total_combination = power(2, count);

         record_indexes = ARRAY(SELECT id from cat_breeds);
         record_bdds = ARRAY(SELECT cat_breeds.sentence from cat_breeds);

         FOR i IN 0..count
         LOOP
            count_bdds[i] = bdd('0');
         END LOOP;

         FOR counter IN 0..total_combination - 1
         LOOP
            combination = ARRAY[]::integer[];

            combination_bdd = bdd('1');
            FOR i IN 0..count-1
            LOOP
               if (counter & (1<<i)) > 0 then
                  combination = combination || record_indexes[i+1];
                  combination_bdd = bdd(tostring(combination_bdd & record_bdds[i+1]));
               else
                  combination_bdd = bdd(tostring(combination_bdd & !record_bdds[i+1]));
               end if;
            END LOOP;

            combination_length = cardinality(combination);
            count_bdds[combination_length] = bdd(tostring(count_bdds[combination_length]|combination_bdd));
         END LOOP;

         FOR i IN 0..count
         LOOP
            r.count = i;
            r.sentence = count_bdds[i];
            RETURN NEXT r;
         END LOOP;
      end;
      $$
    SQL
    a = ActiveRecord::Base.connection.execute(queries)
  end
end
