# -*- encoding : utf-8 -*-
#Controller for dealing with statistics
class StatisticsController < ApplicationController
  # Shows the statistics page.
  def show
    solr = RSolr.connect :url => CONFIG[:solr_url]

    @response = solr.get 'select', :params => {:q => 'has_model_ssim:ContentFile'}
    @group = solr.get 'select', :params => {
                          :q => 'has_model_ssim:ContentFile',
                          :fl => 'format_*',
                          :group => true,
                          :'group.field' => 'format_pronom_id_si'
                              }
  end
end