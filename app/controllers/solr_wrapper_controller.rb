class SolrWrapperController < ApplicationController
  def search
      result = map_result(Finder.all_people(params[:q])+ Finder.all_organizations(params[:q]))
      render json:  result
  end

  def get_obj
      result = map_result(Finder.obj(URI.unescape(params[:id])))
      render json: result[0] unless result.blank?
  end
  
  def search_by_same_as_uri
      result = map_result(Finder.search_by_same_as_uri(params[:uri]))
      if result.blank?
        render :nothing => true, :status => '404'
      else
        render json: result[0]
      end
  end

  private

  def map_result(result)
    result = result.map {|doc| { :val => doc['display_value_ssm'].try(:first),:id => doc['id'] } }
  end

end