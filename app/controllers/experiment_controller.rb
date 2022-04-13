class ExperimentController < ApplicationController
  before_action :query_data
  def index
  end

  def show
  end

  private

  def query_data
    experiment_name = params[:commit]&.parameterize&.underscore&.to_sym || :experiment_a
    algorithm_ids = params[:algorithm_ids] || [Algorithm.first.id]
    ep = Experiment.where(algorithm_id: algorithm_ids, name: experiment_name).includes(:algorithm)

    @result = ep.map do |x|
      { name: x.algorithm.name, data: x.result }
    end.uniq { |s| s[:name]}

    @title = chart_desc[experiment_name][:title]
    @x_title = chart_desc[experiment_name][:x_title]
    @colors = colors
  end

  def chart_desc
    {
      experiment_a: {title: 'Experiment A investigates varying number of tuples', 'x_title': 'n tuples'},
      experiment_b: {title: 'Experiment B explores the effects of varying number of distinct variables (14 records)', 'x_title': 'n random variables'},
      experiment_c: {title: 'Experiment C investigates the effects of varying number of alternatives(10 records, 3 rv)', 'x_title': 'n alternatives per random variables'},
      experiment_d: {title: 'Experiment D  studies the effects of varying complexity of the sentence(8 records, 8 rv)', 'x_title': 'n of arity'},
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
