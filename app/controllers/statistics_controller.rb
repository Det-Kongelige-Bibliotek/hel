# -*- encoding : utf-8 -*-
#Controller for dealing with statistics
class StatisticsController < ApplicationController

  SOLR_FL = 'format_*, original_filename_tesim, id, activity_tesim, collection_tesim, file_size_tesim,
                                  preservation_profile_tesim, embargo_tesim, instance_type_tesim, material_type_tesim,
                                  created_dtsim'
  SOLR_MAX = 10000000

  # Shows the statistics page, or sends CSV file back to the user.
  def show
    @params = params

    if(params[:commit] == "Extract as CSV")
      extract_cvs(params)
    else
      retrieve_group_from_solr(params)
    end
  end

  # Extracts all the
  # Sends the CSV results back to the user.
  #
  # @param params The parameters to be translated into SOLR search parameters.
  def extract_cvs(params)
    solr = RSolr.connect :url => CONFIG[:solr_url]
    q = extract_params(params)
    q << 'has_model_ssim:ContentFile'
    @q = q.join(' AND ')
    group = solr.get 'select', :params => {
                                  :q => @q,
                                  :fl => SOLR_FL,
                                  :rows => SOLR_MAX,
                                  :wt => 'csv'
                              }
    send_data group.gsub(',', ';'), {:filename => 'statistics.csv', :type => 'text/csv'}
  end

  # Retrieves grouped results from SOLR. Grouped around the pronom id.
  # Used for the viewing of results.
  #
  # @param params the parameters to be translated into SOLR parameters.
  def retrieve_group_from_solr(params)
    solr = RSolr.connect :url => CONFIG[:solr_url]
    q = extract_params(params)
    q << 'has_model_ssim:ContentFile'
    @q = q.join(' AND ')
    @group = solr.get 'select', :params => {
                                  :q => @q,
                                  :fl => SOLR_FL,
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
    res << "format_pronom_id_si:#{params[:format_pronom_id_si]}" unless params[:format_pronom_id_si].blank?
    res << "collection_tesim:\"#{params[:collection_tesim]}\"" unless params[:collection_tesim].blank?
    res << "activity_tesim:\"#{params[:activity_tesim]}\"" unless params[:activity_tesim].blank?
    res << "preservation_profile_tesim:\"#{params[:preservation_profile_tesim]}\"" unless params[:preservation_profile_tesim].blank?
    res << "embargo_tesim:#{params[:embargo_tesim]}" unless params[:embargo_tesim].blank?
    res << "instance_type_tesim:\"#{params[:instance_type_tesim]}\"" unless params[:instance_type_tesim].blank?
    res << "material_type_tesim:\"#{params[:material_type_tesim]}\"" unless params[:material_type_tesim].blank?
    unless @params[:created_dtsim].blank?
      min_date = extract_min_date
      max_date = extract_max_date
      res << "created_dtsim:[#{min_date.nil? ? '*' : min_date} TO #{max_date.nil? ? '*' : max_date}]" unless min_date.nil? && max_date.nil?
    end

    res
  end

  def extract_min_date
    return nil if @params[:created_dtsim]['min_time(1i)'].blank?
    "#{@params[:created_dtsim]['min_time(1i)']}-#{@params[:created_dtsim]['min_time(2i)']}-#{@params[:created_dtsim]['min_time(3i)']}T#{@params[:created_dtsim]['min_time(4i)']}:#{@params[:created_dtsim]['min_time(5i)']}:00Z "
  end

  def extract_max_date
    return nil if @params[:created_dtsim]['max_time(1i)'].blank?
    "#{@params[:created_dtsim]['max_time(1i)']}-#{@params[:created_dtsim]['max_time(2i)']}-#{@params[:created_dtsim]['max_time(3i)']}T#{@params[:created_dtsim]['max_time(4i)']}:#{@params[:created_dtsim]['max_time(5i)']}:00Z "
  end
end