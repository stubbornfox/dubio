class DictController < ApplicationController
  def create
    number_of_random_variables = params[:number_of_random_variables].to_i
    number_of_alternatives = params[:number_of_alternatives].to_i

    Dict.my_dict.create_rva(number_of_random_variables, number_of_alternatives)

    redirect_to home_index_path
  end
end
