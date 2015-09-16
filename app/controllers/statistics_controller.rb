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
  SOLR_FL_COMMON = ['preservation_collection_tesim',
             'format_mimetype_tesim',
             'created_dtsim',
             'file_size_isim',
             'original_filename_tesim',
             'id']
  SOLR_FL_TECHNICAL = ['format_name_tesim',
             'format_version_tesim',
             'format_pronom_id_si',
             'characterization_tools_tesim',
             'creating_application_tesim']
  SOLR_FL_ALL = SOLR_FL_ADMINISTRATIVE + SOLR_FL_COMMON + SOLR_FL_TECHNICAL
  SOLR_MAX = 10000000

  SOLR_PARAMS_FILE_SIZE_SUM = {
      :'stats' => 'true',
      :'stats.field' => 'file_size_isim'
  }
  SOLR_PARAMS_SOLR_GROUP = {
      :group => true,
      :'group.field' => 'format_pronom_id_si',
      :'group.limit' => 5
  }
  SOLR_PARAMS_AS_CSV = {:wt => 'csv'}
  SOLR_PARAMS_MAX_RESULTS = {:rows => SOLR_MAX}

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
    p = create_query(params)
    p.merge!(SOLR_PARAMS_MAX_RESULTS)
    p.merge!(SOLR_PARAMS_AS_CSV)
    #p.merge!(SOLR_PARAMS_FILE_SIZE_SUM) if params['file_size_sum'] && params['file_size_sum'] == '1'
    group = solr.get 'select', :params => p

    csv_prefix = create_cvs_prefix(params)
    # Extract number of results (number of lines - 1 for the header line)
    line_count = group.lines.count-1

    ## TODO might be a performance issue, if amount of results are too large (the 'gsub' might contain all SOLR data in memory).
    send_data "#{csv_prefix }\nNumber of results;#{line_count}\n\n#{group.gsub(',', ';')}", {:filename => 'statistics.csv', :type => 'text/csv'}
  end

  # Retrieves grouped results from SOLR. Grouped around the pronom id.
  # Used for the viewing of results.
  #
  # @param params the parameters to be translated into SOLR parameters.
  def retrieve_group_from_solr(params)
    solr = RSolr.connect :url => CONFIG[:solr_url]
    p = create_query(params)
    p.merge!(SOLR_PARAMS_SOLR_GROUP)
    p.merge!(SOLR_PARAMS_FILE_SIZE_SUM) if (params['file_size_sum'] && params['file_size_sum'] == '1')
    @group = solr.get 'select', :params => p
  end

  def create_query(params)
    q = extract_search_query(params)
    q << 'has_model_ssim:ContentFile'
    @q = q.join(' AND ')
    @fl = extract_field_list(params).join(',')
    return {
        :q => @q,
        :fl => @fl
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

    res << "preservation_collection_tesim:\"#{params[:preservation_collection_tesim]}\"" unless params[:preservation_collection_tesim].blank?
    res << "format_mimetype_tesim:\"#{params[:format_mimetype_tesim]}\"" unless params[:format_mimetype_tesim].blank?
    unless params[:created_dtsim].blank?
      @min_date = extract_min_date
      @max_date = extract_max_date
      res << "created_dtsim:[#{@min_date.nil? ? '*' : @min_date.strftime('%FT%TZ')} TO #{@max_date.nil? ? '*' : @max_date.strftime('%FT%TZ')}]" unless @min_date.nil? && @max_date.nil?
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

    DateTime.new(@params[:created_dtsim]['min_time(1i)'].to_i,
                 @params[:created_dtsim]['min_time(2i)'].to_i,
                 @params[:created_dtsim]['min_time(3i)'].to_i,
                 @params[:created_dtsim]['min_time(4i)'].to_i,
                 @params[:created_dtsim]['min_time(5i)'].to_i)
  end

  # Extracts the maximum created date in the format 'YYYY-MM-DDThh:mm:ssZ'
  def extract_max_date
    return nil if @params[:created_dtsim]['max_time(1i)'].blank?

    DateTime.new(@params[:created_dtsim]['max_time(1i)'].to_i,
                      @params[:created_dtsim]['max_time(2i)'].to_i,
                      @params[:created_dtsim]['max_time(3i)'].to_i,
                      @params[:created_dtsim]['max_time(4i)'].to_i,
                      @params[:created_dtsim]['max_time(5i)'].to_i)
  end


  def create_cvs_prefix(params, query=nil)
    res = ""
    # Show search terms in hash values as comma separated, and only if they contain values.
    SOLR_FL_ALL.each do |p|
      if params[p].is_a?(Hash)
        res += "#{p};#{params[p].values.join(';') unless params[p].values.join.blank?}\n"
      else
        res += "#{p};#{params[p]}\n"
      end
    end
    res
  end
end