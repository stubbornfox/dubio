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
        x.result.each{ |key,str| x.result[key] = str }
        x.result = x.result.sort{|a,b| a[0].to_i<=>b[0].to_i}[0..-1].to_h
        { name: algoname[x.algorithm.name.to_sym] || x.algorithm.name, data: x.result }
      end.uniq { |s| s[:name].upcase}
      result = result.sort{|a,b| a[:name]<=>b[:name]}

      @results[experiment_name][:result] = result
      @results[experiment_name][:x_title] = chart_desc[experiment_name][:x_title]
      @chart_desc = chart_desc
      @colors = colors
    end
  end

  def chart_desc
    {
      experiment_a: {title: 'Experiment A investigates varying number of tuples', 'x_title': '# Records'},
      experiment_b: {title: 'Experiment B explores the effects of varying number of distinct variables (15 tuples)', 'x_title': '#vars'},
      experiment_c: {title: 'Experiment C investigates the effects of varying number of alternatives(5 tuples, 5 rv)', 'x_title': '#alternatives'},
      experiment_d: {title: 'Experiment D  studies the effects of varying complexity of the sentence (15 tuples)', 'x_title': 'n of arity'},
      experiment_e: {title: 'Experiment E varying the number of bins B in hist count (15 tuples)', 'x_title': 'n bins'},
      experiment_f: {title: 'Experiment F varying the number of top k in top count(15 tuples)', 'x_title': 'k'},
    }
  end

  def algoname
    {
      top_count: 'Top 5',
      comb_count: 'Combination',
      possible_world_count: 'Possible World',
    }
  end

  def colors

    c = ["#e60049", "#0bb4ff", "#50e991", "#e6d800", "#9b19f5", "#ffa300", "#dc0ab4", "#b3d4ff", "#00bfa0"]

  end
end
