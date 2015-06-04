# -*- encoding : utf-8 -*-
#Controller for dealing with statistics
class StatisticsController < ApplicationController
  # Shows the statistics page.
  def show
    @params = params

    solr = RSolr.connect :url => CONFIG[:solr_url]
    q = extract_params(params)
    q << 'has_model_ssim:ContentFile'
    @q = q.join(' AND ')
#    @response = solr.get 'select', :params => {:q => 'has_model_ssim:ContentFile'}
    @group = solr.get 'select', :params => {
                          :q => @q,
                          :fl => 'format_*, original_filename_tesim, id',
                          :group => true,
                          :'group.field' => 'format_pronom_id_si',
                          :'group.limit' => 5
                              }
  end

  def extract_params(params)
    res = []
    res << "format_name_tesim:\"#{params[:format_name_tesim]}\"" unless params[:format_name_tesim].blank?
    res << "format_version_tesim:#{params[:format_version_tesim]}" unless params[:format_version_tesim].blank?
    res << "format_mimetype_tesim:\"#{params[:format_mimetype_tesim]}\"" unless params[:format_mimetype_tesim].blank?
    res << "format_pronom_id_si:\"#{params[:format_pronom_id_si]}\"" unless params[:format_pronom_id_si].blank?
    res
  end
end