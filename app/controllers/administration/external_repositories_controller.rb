module Administration
  class ExternalRepositoriesController < ApplicationController
    before_action :set_external_repository, only: [:show, :syncronise]


    def index
      @external_repositories = Administration::ExternalRepository.all
    end

    def show
    end

    def syncronise
      @external_repository = ExternalRepository[params[:id]]
      @external_repository.sync_status = 'REQUESTED' unless @external_repository.sync_status == 'NEW'
      @external_repository.sync_date = DateTime.now.to_s
      @external_repository.save
      Resque.enqueue("SyncExtRepo#{@external_repository.sync_method}".constantize,@external_repository.id)
      render action: 'show'
    end

    def set_external_repository
      @external_repository = ExternalRepository[params[:id]]
    end
  end
end
