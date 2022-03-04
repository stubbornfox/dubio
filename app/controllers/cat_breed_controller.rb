class CatBreedController < ApplicationController
  def create
    number_of_records = params[:number_of_records].to_i
    number_of_random_variables = params[:number_of_random_variables].to_i
    number_of_alternatives = params[:number_of_alternatives].to_i
    arity_in_sentence = params[:arity_in_sentence].to_i

    CatBreed.make(number_of_records, number_of_random_variables, number_of_alternatives, arity_in_sentence)

    redirect_to home_index_path
  end
end
