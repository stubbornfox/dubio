class AlgorithmController < ApplicationController
  def index
  end

  def new
  end

  def create
    begin
      te = TestingEnvironment.new(params[:algorithm_name], params[:code])
      a = te.create_count_func
      algo = Algorithm.find_or_initialize_by(name: params[:algorithm_name])
      algo.code = params[:code]
      algo.type_of_count = params[:algorithm_type]
      algo.save
    rescue ActiveRecord::StatementInvalid => e
      @error = e.message
    end
  end

  def show
    @algorithm = Algorithm.find(params[:id])
  end
end
