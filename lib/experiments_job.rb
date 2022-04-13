require 'timeout'

class ExperimentsJob
  attr_accessor :algorithm, :query, :n, :bins, :topk

  def initialize(algorithm_id)
    @algorithm = Algorithm.find(algorithm_id)
    te = TestingEnvironment.new(@algorithm.name, @algorithm.code)
    te.create_count_func
    if @algorithm.type_of_count == 'hist_count'
      @bins = 1
    elsif @algorithm.type_of_count == 'top_count'
      @k = 5
    end
  end

  def query
    if @k
      @query = "explain(analyze, format json) select * from #{@algorithm.name}('select * from cat_breeds;', #{@k});"
    elsif @bins
      @query = "explain(analyze, format json) select * from #{@algorithm.name}('select * from cat_breeds;', #{@bins});"
    else
      @query = "explain(analyze, format json) select * from #{@algorithm.name}('select * from cat_breeds;');"
    end
  end

  def run
    if @algorithm.type_of_count == 'exact_count'
      exact_count_experiment
    elsif @algorithm.type_of_count == 'hist_count'
      @bins = 1
      hist_count_experiment
    elsif @algorithm.type_of_count == 'top_count'
      @k = 5
      top_count_experiment
    end
  end

  def experiment_a
    results = {}
    clear_data

    Rails.logger.info "Run Experiment A for #{algorithm.name}"

    begin
      CAT_BREEDS_A.each_with_index do |(name, breed, bdd), index|

        query_plan = nil
        @bins = @bins && Math.sqrt(index+1).to_i

        cat = CatBreed.create(name: name, breed: breed, sentence: bdd)
        sql = query
        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
        }

        time_ex =  get_execution_time(query_plan)
        Rails.logger.info "Count #{index + 1} tooks #{time_ex} ms"
        results[index+1] = time_ex
      end
    rescue Timeout::Error => e
    ensure
      index = results.size
      save_result(results, :experiment_a)
      Rails.logger.info "Finish Experiment A for #{algorithm.name}: #{index} tuples in #{results[index]}ms"
      return results
    end
  end

  def experiment_b
    i = 0
    n = 14
    results = {}
    @bins = @bins && 3
    begin
      while true && i < n do
        i += 1;
        query_plan = nil
        puts i

        CatBreed.make_experiment_b(n, i)

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }

        time_ex =  get_execution_time(query_plan)

        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts 'Finish experiment b'
      puts results
      save_result(results, :experiment_b)
      return results
    end
    save_result(results, :experiment_b)
    return results
    puts 'Finish experiment b'
  end

  def experiment_c
    i = 0
    n = 10
    results = {}
    @bins = @bins && 3
    begin
      while true && i < n do
        i += 1
        query_plan = nil
        puts i

        CatBreed.make_experiment_c(n, i)

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }

        time_ex =  get_execution_time(query_plan)
        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      save_result(results, :experiment_c)
      return results
    end
    save_result(results, :experiment_c)
    return results
  end

  def experiment_d
    i = 0
    n = 8
    results = {}
    @bins = @bins && 2
    begin
      while true && i < n do
        i += 1
        query_plan = nil
        puts i

        CatBreed.make_experiment_d(n, i)

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }

        time_ex =  get_execution_time(query_plan)
        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      save_result(results, :experiment_d)
      return results
    end
    save_result(results, :experiment_d)
    return results
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
        sql = query
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

  def exact_count_experiment
    experiment_a
    experiment_b
    experiment_c
    experiment_d
  end

  def hist_count_experiment
    experiment_a
    experiment_b
    experiment_c
    experiment_d
    experiment_e
  end

  def top_count_experiment
    experiment_a
    experiment_b
    experiment_c
    experiment_d
    experiment_f
  end

  private
  def get_execution_time(query_plan)
    JSON(query_plan[0]['QUERY PLAN'])[0]['Execution Time']
  end

  def save_result(results, experiment_name)
    Experiment.create(result: results, name: experiment_name, algorithm_id: @algorithm.id)
  end

  def clear_data
    CatBreed.in_batches.delete_all
  end

end
