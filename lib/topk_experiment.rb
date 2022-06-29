require 'timeout'

class TopkExperiment < ExperimentSetup
  attr_accessor :k, :algorithm

  def initialize
    @k = 5
    @algorithm = Algorithm.find 26
  end

  def query
    "select (q.c).count, STRING_AGG((q.c).sentence, '|') as bdd from (select unnest(count_on_topk_worlds(top_k_worlds(dict, #{@k}), sentence)) as c from cat_breeds, dicts where dicts.name='mydict') q group by count;"
  end

  def experiment_a
    results = {}
    clear_data

    Rails.logger.info "Run Experiment A for #{algorithm.name}"
    rv = []

    begin
      sql = explain_query
      CAT_BREEDS_A.each_with_index do |(name, breed, bdd), index|
        query_plan = nil
        r = bdd.split('=')[0]
        unless rv.include? r
          Dict.my_dict.add_rva(DICTS[r]);
        end

        rv << r;

        cat = CatBreed.create(name: name, breed: breed, sentence: bdd)

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
        }

        time_ex =  get_execution_time(query_plan)
        Rails.logger.info "Count #{index + 1} tooks #{time_ex} ms"
        results[index+1] = time_ex
      end
    rescue Error => e
      puts e
    ensure
      index = results.size
      save_result(results, :experiment_a)
      Rails.logger.info "Finish Experiment A for #{algorithm.name}: #{index} tuples in #{results[index]}ms"
      return results
    end
  end

  def experiment_b
    nrv = 0
    n = 15
    results = {}
    @bins = @bins && 4
    max_nr = 15
    Rails.logger.info "Run Experiment B for #{algorithm.name}"

    begin
      while nrv < max_nr do
        nrv += 1;
        query_plan = nil
        CatBreed.make_experiment_b(n, nrv)
        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }
        time_ex = get_execution_time(query_plan)
        Rails.logger.info "#{nrv} variables took #{time_ex} ms"
        results[nrv] = time_ex
      end
    rescue Timeout::Error => e
      puts e.message
    ensure
      index = results.size
      save_result(results, :experiment_b)
      Rails.logger.info "Finish Experiment B for #{algorithm.name}: #{index} variables in #{results[index]}ms"
      return results
    end
  end

  def experiment_c
    i = 1
    n = 10
    results = {}
    @bins = @bins && 4
    begin
      while true && i < 5 do
        i += 1
        query_plan = nil
        puts i

        CatBreed.make_experiment_c(n, i)

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }

        time_ex =  get_execution_time(query_plan)
        Rails.logger.info "#{i} alternatives took #{time_ex} ms"
        results[i] = time_ex
      end
    rescue Timeout::Error => e
     puts e.message
    ensure
      puts results
      index = results.size
      save_result(results, :experiment_c)
      Rails.logger.info "Finish Experiment Cfor #{algorithm.name}: #{index} alternatives in #{results[index]}ms"
      return results
    end
  end

  def experiment_d
    n = 10
    cats = CatBreed.make(n);
    Dict.find_or_create_by(name: 'mydict')
    Dict.my_dict.clear
    Dict.my_dict.add_rva(RVA_50_WITH_PROB.flatten.join(';'))
    i = 0
    results = {}
    @bins = @bins && 4
    arity = 8

    begin
      COMPLEX_RVA.each do |rva_arr|
        CatBreed.all.each_with_index do |cat, j|
          cat.update(sentence: rva_arr[j])
        end
        i += 1
        query_plan = nil

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }

        time_ex =  get_execution_time(query_plan)
        results[i] = time_ex
        Rails.logger.info "#{i} arity took #{time_ex} ms"
      end
    rescue Timeout::Error => e
      puts e.message
    ensure
      puts results
      index = results.size
      save_result(results, :experiment_d)
      Rails.logger.info "Finish Experiment D for #{algorithm.name}: #{index} arity in #{results[index]}ms"
      return results
    end
  end

  def experiment_e
    results = {}
    clear_data

    bins = 0
    n = 15

    Rails.logger.info "Run Experiment E for #{algorithm.name}"
    CatBreed.create_list(CAT_BREEDS_A[0...n])

    begin
      while bins < n do
        query_plan = nil
        bins += 1
        @bins = bins
        sql = query

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
        }

        time_ex = get_execution_time(query_plan)
        results[bins] = time_ex
        Rails.logger.info "Count #{bins} bins took #{time_ex} ms"
      end
    rescue Timeout::Error => e
    ensure
      index = results.size
      save_result(results, :experiment_e)
      Rails.logger.info "Finish Experiment E for #{algorithm.name}: #{index} bins of #{n} tuples in #{results[index]}ms"
      return results
    end
  end

  def experiment_f
    results = {}
    clear_data

    k = 0
    n = 15

    Rails.logger.info "Run Experiment F for #{algorithm.name}"

    CatBreed.create_list(CAT_BREEDS_A[0...n])

    begin
      while k < n do
        k += 1
        query_plan = nil
        @k = k
        sql = explain_query
        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
        }

        time_ex = get_execution_time(query_plan)
        results[k] = time_ex

        Rails.logger.info "Count top #{k} tooks #{time_ex} ms"
      end
    rescue Timeout::Error => e
    ensure
      index = results.size
      save_result(results, :experiment_f)
      Rails.logger.info "Finish Experiment F for #{algorithm.name}: top #{index} of #{n} tuples in #{results[index]}ms"
      return results
    end
  end
end
