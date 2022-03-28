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
      #{algo_code}
   SQL
   ActiveRecord::Base.connection.execute(queries)
  end
end
