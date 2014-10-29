# This controller provides a central location for any Valhal object
class ResourcesController < ApplicationController
  before_action :set_resource, only: [:show]

  # Redirect to the correct namespace
  # for the specific object type
  def show
    redirect_to @resource
  end

  private

  def set_resource
    @resource = ActiveFedora::Base.find(params[:id])
  end
end
