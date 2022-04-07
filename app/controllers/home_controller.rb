class HomeController < ApplicationController
  def index
    @dict = Dict.my_dict
    @cat_breeds = CatBreed.all_with_prob
  end

  def experiment
  end

  def exact_count
    @cat_count = CatBreed.exact_count
  end

  def hist_count
    bin = params[:bin].presence || 2
    @cat_count = CatBreed.hist_count(bin)
  end

  def top_count
    k = params[:k].presence || 1
    @cat_count = CatBreed.top_count(k)
  end
end
