require 'timeout'

class Experiments
  def time_calc(query_plan)
    query_plan[3].values[0].scan(/(\d+\.\d+)/)[0][0]
  end

  def experiment_a
    i = 0
    sql = "explain analyze select exact_count('select count(*) from cat_breeds');"
    results = {}
    begin
      while true && i <=1000 do
        i += 1;
        query_plan = nil
        puts i

        CatBreed.make(i)

        # Timeout::timeout(30) {
        #   query_plan = ActiveRecord::Base.connection.execute(sql)
        # }

        # puts query_plan[3]
        # time_ex =  time_calc(query_plan)
        # puts time_ex
        # results[i] = time_ex
      end
    rescue Timeout::Error => e
      return results
    end
  end

  def experiment_b
    i = 0
    n = 14
    sql = "explain analyze select exact_count('select count(*) from cat_breeds');"
    results = {}
    begin
      while true && i < n do
        i += 1;
        query_plan = nil
        puts i

        CatBreed.make_experiment_b(n, i)

        Timeout::timeout(60) {
          query_plan = ActiveRecord::Base.connection.execute(sql)
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
end
