Rails.application.routes.draw do
  get 'home/index'
  get 'home/experiment'
  get 'home/exact_count'
  get 'home/histogram_count'
  get 'home/algorithm'
  get 'algorithm/index'
  post 'algorithm/create'
  get 'algorithm/show'
  get 'experiment/a'
  get 'experiment/b'
  get 'experiment/c'
  get 'experiment/d'
  get 'experiment/e'
  get 'experiment/f'
  post 'dict/create'
  post 'cat_breed/create'
  root 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
