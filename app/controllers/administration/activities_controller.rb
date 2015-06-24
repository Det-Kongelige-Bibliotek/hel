module Administration
  class ActivitiesController < ApplicationController
    before_action :set_activity, only: [:show, :edit, :update, :destroy]
    authorize_resource

    def index
      @activities = Administration::Activity.all
    end

    def show
    end

    def new
      @activity = Administration::Activity.new
    end

    def edit
    end

    def create
      @activity = Administration::Activity.new(activity_params)
      if @activity.save
        redirect_to administration_activity_path(@activity), notice: t('administration.activities.flashmessage.created')
      else
        render action: :new
      end
    end

    def update
      if @activity.update(activity_params)
        redirect_to @activity, notice: t('administration.activities.flashmessage.updated')
      else
        render action: 'edit'
      end
    end

    def destroy
      @activity.destroy
      redirect_to administration_activities_url, notice: t('administration.activities.flashmessage.destroyed')
    end

    private
    def set_activity
      @activity = Administration::Activity.find(URI.unescape(params[:id]))
    end

    def activity_params
      params.require(:administration_activity).permit( :activity,
                                                       :access_condition,
                                                       :availability,
                                                       :collection, 
                                                       :embargo,
                                                       :embargo_condition,
                                                       :preservation_profile,
                                                       :copyright,
                                                       :ophavsret,
                                                       activity_permissions:[:instance=>[:group=>[:discover=>[],:read=>[],:edit=>[]]] ,:file=>[:group=>[:discover=>[],:read=>[],:edit=>[]]]]
      )
    end
  end
end
