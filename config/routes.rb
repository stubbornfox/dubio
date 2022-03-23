Rails.application.routes.draw do
  get 'home/index'
  get 'home/experiment'
  get 'home/exact_count'
  get 'home/histogram_count'
  get 'home/algorithm'
  get 'experiment/a'
  post 'dict/create'
  post 'cat_breed/create'
  root 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
