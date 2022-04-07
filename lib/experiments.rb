require 'timeout'
EXACT_COUNT_SQL = "explain analyze select exact_count('select * from cat_breeds');"

class Experiments
  def time_calc(query_plan)
    query_plan[3].values[0].scan(/(\d+\.\d+)/)[0][0]
  end

  def experiment_a
    i = 0
    results = {}
    begin
      while true && i <=1000 do
        i += 1;
        query_plan = nil
        puts i

        CatBreed.make(i)

        Timeout::timeout(60) {
          query_plan = ActiveRecord::Base.connection.execute(EXACT_COUNT_SQL)
        }

        puts query_plan[3]
        time_ex =  time_calc(query_plan)
        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      return results
    end
  end

  def experiment_b
    i = 0
    n = 14
    results = {}
    begin
      while true && i < n do
        i += 1;
        query_plan = nil
        puts i

        CatBreed.make_experiment_b(n, i)

        Timeout::timeout(60) {
          query_plan = ActiveRecord::Base.connection.execute(EXACT_COUNT_SQL)
        }

        puts query_plan[3]
        time_ex =  time_calc(query_plan)
        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      return results
    end
    return results
  end

  def experiment_c
    i = 0
    n = 10
    results = {}
    begin
      while true && i < n do
        i += 1
        query_plan = nil
        puts i

        CatBreed.make_experiment_c(n, i)

        Timeout::timeout(60) {
          query_plan = ActiveRecord::Base.connection.execute(EXACT_COUNT_SQL)
        }

        puts query_plan[3]
        time_ex =  time_calc(query_plan)
        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      return results
    end
    return results
  end

  def experiment_d
    i = 0
    n = 8
    results = {}
    begin
      while true && i < n do
        i += 1
        query_plan = nil
        puts i

        CatBreed.make_experiment_d(n, i)

        Timeout::timeout(60) {
          query_plan = ActiveRecord::Base.connection.execute(HIST_COUNT_SQL)
        }

        puts query_plan[3]
        time_ex =  time_calc(query_plan)
        puts time_ex
        results[i] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      return results
    end
    return results
  end

  def experiment_e
    bins = 0
    n = 8
    number_of_random_variables = 6
    results = {}
    CatBreed.make(n, number_of_random_variables)
    begin
      while true && bins < n do
        bins += 1
        sql = "explain analyze select hist_count('select * from cat_breeds', #{bins});"
        query_plan = nil
        puts bins
        Timeout::timeout(60) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
        }

        puts query_plan[3]
        time_ex =  time_calc(query_plan)
        puts time_ex
        results[bins] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      return results
    end
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
        sql =  "explain(analyze, format json) select * from top_count('select * from cat_breeds;', #{k}) order by prob desc limit #{k}";
        query_plan = nil
        puts k
        Timeout::timeout(60) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
        }

        time_ex =  JSON(query_plan[0]['QUERY PLAN'])[0]["Execution Time"]
        puts time_ex
        results[k] = time_ex
      end
    rescue Timeout::Error => e
      puts 'timeout rescue'
      puts results
      return results
    end
    return results
  end
end
