Rails.application.routes.draw do
  get 'home/index'
  post 'dict/create'
  post 'cat_breed/create'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
