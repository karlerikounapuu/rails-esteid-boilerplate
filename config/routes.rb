require 'sidekiq/web'

Rails.application.routes.draw do
  resources :documents
  root to: 'home#index'
  mount Sidekiq::Web => '/sidekiq'
  mount ActionCable.server => '/cable'

  post 'authentication/handshake' => 'authentications#wait_for_handshake', as: :wait_for_handshake
  get 'authentication/forward/:id' => 'authentications#authorize_by_session', as: :authorize_eid_session
  resources :authentications, only: [:show]

  authenticated :user do
    root 'documents#index', as: :authenticated_root
  end

  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
