# This controller provides a central location for any Valhal object
class ResourcesController < ApplicationController
  before_action :set_resource, only: [:show]

  # Redirect to the correct namespace
  # for the specific object type
  def show
    respond_to do |format|
      format.rdf { render rdf: @resource  }
      format.html { redirect_to @resource }
    end
  end

  private

  def set_resource
    @resource = ActiveFedora::Base.find(URI.unescape(params[:id]))
  end
end
