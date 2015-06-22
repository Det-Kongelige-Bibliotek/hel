# -*- encoding : utf-8 -*-
#Controller for dealing with statistics
class StatisticsController < ApplicationController

  SOLR_FL_ADMINISTRATIVE = ['activity_tesim',
             'collection_tesim',
             'material_type_tesim',
             'embargo_tesim',
             'embargo_date_tesim',
             'work_id_tesim',
             'instance_id_tesim',
             'instance_type_tesim']
  SOLR_FL_COMMON = ['preservation_profile_tesim',
             'format_mimetype_tesim',
             'created_dtsim',
             'file_size_isim',
             'original_filename_tesim',
             'id']
  SOLR_FL_TECHNICAL = ['format_name_tesim',
             'format_version_tesim',
             'format_pronom_id_si',
             'creating_application_tesim']
  SOLR_FL_ALL = SOLR_FL_ADMINISTRATIVE + SOLR_FL_COMMON + SOLR_FL_TECHNICAL
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
    q = extract_search_query(params)
    q << 'has_model_ssim:ContentFile'
    @q = q.join(' AND ')
    @fl = extract_field_list(params).join(',')
    group = solr.get 'select', :params => {
                                  :q => @q,
                                  :fl => @fl,
                                  :rows => SOLR_MAX,
                                  :wt => 'csv'
                              }
    @csv = create_cvs_prefix(params)

    send_data "#{@csv}\n\n#{group.gsub(',', ';')}", {:filename => 'statistics.csv', :type => 'text/csv'}
  end

  # Retrieves grouped results from SOLR. Grouped around the pronom id.
  # Used for the viewing of results.
  #
  # @param params the parameters to be translated into SOLR parameters.
  def retrieve_group_from_solr(params)
    solr = RSolr.connect :url => CONFIG[:solr_url]
    q = extract_search_query(params)
    q << 'has_model_ssim:ContentFile'
    @q = q.join(' AND ')
    @fl = extract_field_list(params).join(',')
    @group = solr.get 'select', :params => {
                                  :q => @q,
                                  :fl => @fl,
                                  :group => true,
                                  :'group.field' => 'format_pronom_id_si',
                                  :'group.limit' => 5
                              }
  end

  # Extract the list of fields to query SOLR.
  def extract_field_list(params)
    if params[:field_list]
      if params[:field_list] == 'SOLR_FL_ADMINISTRATIVE'
        return SOLR_FL_ADMINISTRATIVE + SOLR_FL_COMMON
      end
      if params[:field_list] == 'SOLR_FL_TECHNICAL'
        return SOLR_FL_TECHNICAL + SOLR_FL_COMMON
      end
    end
    SOLR_FL_ALL
  end

  def extract_search_query(params)
    res = []
    res << "activity_tesim:\"#{params[:activity_tesim]}\"" unless params[:activity_tesim].blank?
    res << "collection_tesim:\"#{params[:collection_tesim]}\"" unless params[:collection_tesim].blank?
    res << "material_type_tesim:\"#{params[:material_type_tesim]}\"" unless params[:material_type_tesim].blank?
    res << "embargo_tesim:#{params[:embargo_tesim]}" unless params[:embargo_tesim].blank?
    res << "embargo_date_tesim:#{params[:embargo_date_tesim]}" unless params[:embargo_date_tesim].blank? # TODO fix name
    res << "work_id_tesim:\"#{params[:work_id_tesim]}\"" unless params[:work_id_tesim].blank?
    res << "instance_id_tesim:\"#{params[:instance_id_tesim]}\"" unless params[:instance_id_tesim].blank?
    res << "instance_type_tesim:\"#{params[:instance_type_tesim]}\"" unless params[:instance_type_tesim].blank?

    res << "preservation_profile_tesim:\"#{params[:preservation_profile_tesim]}\"" unless params[:preservation_profile_tesim].blank?
    res << "format_mimetype_tesim:\"#{params[:format_mimetype_tesim]}\"" unless params[:format_mimetype_tesim].blank?
    unless params[:created_dtsim].blank?
      min_date = extract_min_date
      max_date = extract_max_date
      res << "created_dtsim:[#{min_date.nil? ? '*' : min_date} TO #{max_date.nil? ? '*' : max_date}]" unless min_date.nil? && max_date.nil?
    end
    unless params[:file_size_isim].blank? || params[:file_size_type].blank?
      if params[:file_size_type] == '>'
        res << "file_size_isim:[#{params[:file_size_isim]} TO *]"
      else
        res << "file_size_isim:[0 TO #{params[:file_size_isim]}]"
      end
    end

    res << "format_name_tesim:\"#{params[:format_name_tesim]}\"" unless params[:format_name_tesim].blank?
    res << "format_version_tesim:#{params[:format_version_tesim]}" unless params[:format_version_tesim].blank?
    res << "format_pronom_id_si:#{params[:format_pronom_id_si]}" unless params[:format_pronom_id_si].blank?
    res << "creating_application_tesim:#{params[:creating_application_tesim]}" unless params[:creating_application_tesim].blank?

    res
  end

  # Extracts the minimum created date in the format 'YYYY-MM-DDThh:mm:ssZ'
  def extract_min_date
    return nil if @params[:created_dtsim]['min_time(1i)'].blank?
    res = "#{@params[:created_dtsim]['min_time(1i)']}"
    res += "-"
    res += @params[:created_dtsim]['min_time(2i)'].blank? ? "00" : "#{@params[:created_dtsim]['min_time(2i)']}"
    res += "-"
    res += @params[:created_dtsim]['min_time(3i)'].blank? ? "00" : "#{@params[:created_dtsim]['min_time(3i)']}"
    res += "T"
    res += @params[:created_dtsim]['min_time(4i)'].blank? ? "00" : "#{@params[:created_dtsim]['min_time(4i)']}"
    res += ":"
    res += @params[:created_dtsim]['min_time(5i)'].blank? ? "00" : "#{@params[:created_dtsim]['min_time(5i)']}"
    res + ":00Z "
  end

  # Extracts the maximum created date in the format 'YYYY-MM-DDThh:mm:ssZ'
  def extract_max_date
    return nil if @params[:created_dtsim]['max_time(1i)'].blank?
    res = "#{@params[:created_dtsim]['max_time(1i)']}"
    res += "-"
    res += @params[:created_dtsim]['max_time(2i)'].blank? ? "00" : "#{@params[:created_dtsim]['max_time(2i)']}"
    res += "-"
    res += @params[:created_dtsim]['max_time(3i)'].blank? ? "00" : "#{@params[:created_dtsim]['max_time(3i)']}"
    res += "T"
    res += @params[:created_dtsim]['max_time(4i)'].blank? ? "00" : "#{@params[:created_dtsim]['max_time(4i)']}"
    res += ":"
    res += @params[:created_dtsim]['max_time(5i)'].blank? ? "00" : "#{@params[:created_dtsim]['max_time(5i)']}"
    res + ":00Z "
  end


  def create_cvs_prefix(params, query=nil)
    res = ""
    SOLR_FL_ALL.each do |p|
      # Show hash values as comma separated, and only if they contain values.
      if params[p].is_a?(Hash)
        res += "#{p};#{params[p].values.join(';') unless params[p].values.join.blank?}\n"
      else
        res += "#{p};#{params[p]}\n"
      end
    end
    res
  end
end