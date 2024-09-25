# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :pets, only: [:create, :show, :index] do
        collection do
          get 'count'
        end
      end
    end
  end
end
