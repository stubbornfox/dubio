class HomeController < ApplicationController
  def index
    @dict = Dict.my_dict
    @cat_breeds = CatBreed.all_with_prob
  end
end
