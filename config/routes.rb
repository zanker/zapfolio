Zapfolio::Application.routes.draw do
  resources :sessions, :only => :new
  controller :sessions, :path => :sessions, :as => :session do
    get "/logout" => :destroy, :as => :logout
    get "/:provider/callback" => :create
    get "/failure" => :failure
  end

  controller :demo_user, :path => :demo, :as => :demo_user do
    match "/create" => :create, :via => [:get, :post]
  end

  scope "/stripe/:webhook_key", :controller => :stripe do
    post "/event" => :event
  end

  namespace :usercp, :path => :admin, :as => nil do
    get "/" => redirect("/websites")
    get "/setup" => "dashboard#setup", :as => :setup

    controller :users, :path => :users, :as => :user do
      get "/unsubscribe/:user_id/:email_token" => :unsubscribe, :as => :unsubscribe
      post "/sync/status" => :job_status, :as => :job_status
      get "/sync" => :sync, :as => :sync
      put "/unflag/:flag" => :unflag, :as => :unflag
    end

    resource :users, :only => [:update, :edit]

    get "/subscription/checkout/:plan" => "billing#subscriptions", :as => :billing_subscription_checkout
    post "/subscription" => "billing#purchase"
    delete "/subscription" => "billing#cancel_subscription"
    get "/subscription" => "billing#subscriptions", :as => :billing_subscription
    put "/billing" => "billing#update"
    put "/billing/restart" => "billing#restart"
    get "/billing" => "billing#show", :as => :billing

    resource :websites, :only => [:create, :show, :update]
    scope :websites, :path => :websites, :as => :websites do
      get "/edit" => "websites#show", :as => :edit
      get "/layout" => "websites#show", :as => :layout
      get "/layout/css" => "websites#show", :as => :edit_css

      resources :pages, :only => [:create, :update, :destroy]
      get "/pages/type" => "websites#show", :as => :page_type
      get "/pages/new/:page_type" => "websites#show", :as => :add_page
      get "/pages/confirm/:page_id" => "websites#show", :as => :confirm_delete_page
      get "/pages/:page_id" => "websites#show", :as => :edit_page

      get "/menu/reorder" => "websites#show", :as => :reorder

      get "/menu/" => "websites#show", :as => :add_menu
      get "/menu/:menu_id" => "websites#show", :as => :menu

      get "/menu/:menu_id/sub" => "websites#show", :as => :add_sub_menu
      get "/menu/:menu_id/:sub_menu_id" => "websites#show", :as => :sub_menu
    end
  end

  # Temporary due to path rename
  get "/blogs" => redirect("/blog")

  namespace :blogs, :path => :blog, :as => :blog do
    get "/:slug" => :show, :as => :post
    get "/(tag/:tag)" => :index
  end

  get "/:website_id/not-setup" => "home#not_setup"
  get "/no-site" => "home#no_site"
  get "/subscriptions" => "subscriptions#show", :as => :subscription
  get "/privacy-policy" => "home#privacy_policy", :as => :privacy_policy
  get "/terms-of-service" => "home#terms_conditions", :as => :terms_conditions
  get "/" => "home#show", :as => :root
  get "/sitemap.xml" => "sitemap#index"

  unless Rails.env.production?
    match "/404" => "error#routing"
    match "/backend/*a" => "proxy_thin#proxy_pass"
  end
end
