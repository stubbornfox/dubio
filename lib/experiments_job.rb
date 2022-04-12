require 'timeout'

class ExperimentsJob
  attr_accessor :algorithm, :query, :n, :bins, :topk

  def initialize(algorithm_id)
    @algorithm = Algorithm.find(algorithm_id)
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
    i = 0
    results = {}

    begin
      while true && i <=1000 do
        i += 1;
        query_plan = nil
        puts i
        @bins = @bins && Math.sqrt(i).to_i
        CatBreed.make(i)

        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }

        time_ex =  get_execution_time(query_plan)
        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      save_result(results, :experiment_a)
      return results
    end

    puts 'Finish experiment a'
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
    bins = 0
    n = 8
    number_of_random_variables = 6
    results = {}

    CatBreed.make(n, number_of_random_variables)
    query_plan = nil
    begin
      while true && bins < n do
        bins += 1
        @bins = bins
        sql = query
        puts bins
        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
        }

        time_ex =  get_execution_time(query_plan)
        puts time_ex
        results[bins] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      save_result(results, :experiment_e)
      return results
    end
    save_result(results, :experiment_e)
    return results
  end

  def experiment_f
    k = 0
    n = 8
    number_of_random_variables = 8
    results = {}
    CatBreed.make(n, number_of_random_variables)
    begin
      while k < n do
        k += 1
        query_plan = nil
        puts k
        @k = k
        Timeout::timeout(30) {
          query_plan = ActiveRecord::Base.connection.execute(query)
        }

        time_ex = get_execution_time(query_plan)
        puts time_ex
        results[k] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      save_result(results, :experiment_f)
      return results
    end
    save_result(results, :experiment_f)
    return results
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
end
