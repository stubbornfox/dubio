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

  def histogram_count
    @cat_count = CatBreed.exact_count
  end

  def algorithm
  end
end
