class ExperimentController < ApplicationController
  before_action :query_data, except: [:new,:create]
  def index
  end

  def show
  end

  def create
    Experiment.create(
      algorithm_id: params["algorithm_id"],
      result: JSON.parse(params["results"].gsub('\"', '"')),
      name: params["name"],
    )
  end

  private

  def query_data
    @results = {};
    algorithm_ids = params[:algorithm_ids] || [Algorithm.first.id]

    EXPERIMENTS.each do |experiment_name|
      @results[experiment_name] = {}
      ep = Experiment.where(algorithm_id: algorithm_ids, name: experiment_name).includes(:algorithm)

      result = ep.map do |x|
        { name: x.algorithm.name, data: x.result }
      end.uniq { |s| s[:name]}

      @results[experiment_name][:result] = result
      @results[experiment_name][:x_title] = chart_desc[experiment_name][:x_title]
    end
  end

  def chart_desc
    {
      experiment_a: {title: 'Experiment A investigates varying number of tuples', 'x_title': 'n tuples'},
      experiment_b: {title: 'Experiment B explores the effects of varying number of distinct variables (15 tuples)', 'x_title': 'n random variables'},
      experiment_c: {title: 'Experiment C investigates the effects of varying number of alternatives(5 tuples, 5 rv)', 'x_title': 'n alternatives per random variables'},
      experiment_d: {title: 'Experiment D  studies the effects of varying complexity of the sentence (15 tuples)', 'x_title': 'n of arity'},
      experiment_e: {title: 'Experiment E varying the number of bins B in hist count (15 tuples)', 'x_title': 'n bins'},
      experiment_f: {title: 'Experiment F varying the number of top k in top count(15 tuples)', 'x_title': 'top k'},
    }
  end

  def colors
    c = []
    @result.each do |r|
      if r[:name].include?('top_count')
        c << '#198754'
      elsif r[:name].include?('exact_count')
        c << '#337198'
      else r[:name].include?('hist_count')
        c << '#dc3545'
      end
    end
    return c
  end
end
