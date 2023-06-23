# frozen_string_literal: true

Rails.application.routes.draw do
  get 'document/index'
  get 'document/new'
  get 'document/create'
  get 'document/destroy'
  root 'chat#index'

  resources :documents, only: %i[index new create destroy]
end
