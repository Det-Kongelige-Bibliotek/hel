class SolrWrapperController < ApplicationController
  def search
      result = Finder.all_people(params[:q])+ Finder.all_organizations(params[:q])
      result = result.map {|doc| { :val => doc['display_value_ssm'].try(:first),:id => doc['id'] } }
      render json:  result
  end
end