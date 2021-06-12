Rails.application.routes.draw do
  devise_for :users
  devise_scope :user do
    get "/users/service", to: "users#service"
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  api_version(:module => "V1", :path => { :value => "v1" }) do
    get "/dd/:id", to: "displays#show"
    get "/actuals/delete", to: "actuals#delete"
    get "/profiles/search", to: "profiles#search"
    put "/profiles", to: "profiles#update"
    get "/profiles/my", to: "profiles#my"
    post "/profiles/add_experties/:id", to: "profiles#add_experties"
    post "/profiles/remove_experties/:id", to: "profiles#remove_experties"

    get "/posts/search", to: "posts#search"
    get "/posts/delete", to: "posts#destroy"

    get "/channels/search", to: "channels#search"
    get "/channels/my", to: "channels#my"

    post "/roles/abilities", to: "roles#abilities"
    get "/roles/abilities/delete", to: "roles#remove_ability"

    get "/privacy/:id", to: "privacies#show"
    post "/privacy", to: "privacies#update"

    get "/comments/delete", to: "comments#destroy"
    get "/notifications", to: "notifications#my"
    post "/notifications", to: "notifications#seen"

    get "/bookmarks", to: "bookmarks#my"

    post "/notification_settings/add", to: "notification_settings#add"
    post "/notification_settings/remove", to: "notification_settings#remove"

    get "/users/role", to: "users#role"
    post "/users/change_role", to: "users#change_role"

    get "/download/:uuid", to: "uploads#download"
    get "/uploads/:uuid", to: "uploads#show"
    get "/uploads", to: "uploads#index"
    get "/uploads/recent/:id", to: "uploads#recent"

    get "/rooms/last/:id", to: "rooms#last"

    resources :profiles
    resources :channels
    resources :posts
    resources :roles
    resources :shares
    resources :uploads
    resources :auxiliary_tables
    resources :auxiliary_records
    resources :interactions
    resources :users
    resources :comments
    resources :metas
    resources :actuals
    resources :friendships
    resources :settings
    resources :ratings
    resources :notification_settings
    resources :devices
    resources :rooms
    resources :participations

    post "/users/assignments", to: "users#assignments"
    get "/users/assignments/delete", to: "users#delete_assignment"
    post "/users/login", to: "users#login"
    post "/users/verify", to: "users#verify"
    post "/users/sign_up", to: "users#sign_up"
    post "/users/validate_token", to: "users#validate_token"
  end

  #get "/", to: redirect("/ui/")

  #get '/', :to => redirect("app.html?rnd=#{SecureRandom.hex(10)}/#!/posts/")
  #get 'index.html', :to => redirect("/?rnd=#{SecureRandom.hex(10)}")
end
