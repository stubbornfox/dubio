require 'timeout'

class ExperimentSetup
  attr_accessor :k, :algorithm

  def explain_query
    "explain(analyze, format json) #{query}"
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
    Dict.mydict.clear
  end

end
