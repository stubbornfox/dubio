class AlgorithmController < ApplicationController
  def index
    # e = Experiments.new
    # @result = e.experiment_a
    @result = {1=>"34.115", 2=>"2.194", 3=>"1.924", 4=>"3.614", 5=>"4.306", 6=>"8.445", 7=>"16.050", 8=>"46.088", 9=>"85.057", 10=>"230.955", 11=>"378.110", 12=>"950.369", 13=>"1685.272", 14=>"4450.967", 15=>"11802.865", 16=>"20770.593"}
  end

  def create
    begin
      te = TestingEnvironment.new(params[:algorithm_name], params[:code])
      a = te.create_count_func
      algo = Algorithm.find_or_initialize_by(name: params[:algorithm_name])
      algo.code = params[:code]
      algo.save
    rescue ActiveRecord::StatementInvalid => e
      @error = e.message
    end
  end

  def show
    @algorithm = Algorithm.find(params[:id])
  end
end
