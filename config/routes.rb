Rails.application.routes.draw do

  get 'view_file/show'
  post 'view_file/import_from_preservation'
  get 'statistics' => 'statistics#show'


  resources :instances do
    member do
      get 'preservation'
      get 'administration'
      patch 'update_administration'
    end
  end
  resources :works do
    resources :instances do
      get 'send_to_preservation', on: :member
      get  'validate_tei', on: :member
    end
    post 'aleph', on: :collection
  end

  resources :mixed_materials
  resources :letter_books

  get '/catalog/:id/facsimile' => 'catalog#facsimile', as: 'facsimile_catalog'

  resources :content_files, :except => [:new, :index, :delete, :create, :edit, :update, :destroy] do
    member do
      get 'show'
      get 'download'
      get 'upload'
      patch 'update'
      get 'initiate_import_from_preservation'
    end
  end
  root to: 'catalog#index'
  # namespace for managing system
  namespace :administration do
    resources :controlled_lists
    resources :activities
    resources :external_repositories, :only => [:show, :index] do
      get 'syncronise', on: :member
    end
  end

  blacklight_for :catalog
  devise_for :users
  mount Authority::Engine => "/authority"



  get 'resources/:id' => 'resources#show'

  get 'solrwrapper/search/:q', to: 'solr_wrapper#search'
  get 'solrwrapper/getobj/:id', to: 'solr_wrapper#get_obj'



  # The priority is based upon order of creation:
  # first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
