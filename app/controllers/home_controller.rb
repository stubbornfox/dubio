class HomeController < ApplicationController
  def index
    puts "---------------"
    puts ENV['RAILS_ENV']
    puts "---------------"
    @dict = Dict.my_dict
    @cat_breeds = CatBreed.all
  end
end
