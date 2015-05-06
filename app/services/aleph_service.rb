require "#{Rails.root}/app/services/http_service"

class AlephService

  def initialize
    @aleph_url    = YAML.load_file("#{Rails.root}/config/services.yml")[Rails.env]['aleph']['aleph_base_url']
    @http_service = HttpService.new
  end

  #
  # kgl01 nr / isbn (wrd works)
  #

  # Query Aleph X service to get the set data for a given Aleph search. This
  # is the first POST in the 2 POST process of getting Aleph DanMARC metadata
  # for an eBook.  @param search_string e.g. "wbh=edod" @return
  # {aleph_set_number, num_entries} Hash
  #

  def find_set(search_string)
    begin
      response    = search_aleph(search_string)
      set_num     = Nokogiri::XML.parse(response).xpath('/find/set_number/text()').to_s
      num_entries = Nokogiri::XML.parse(response).xpath('/find/no_entries/text()').to_s
      { set_num: set_num, num_entries: num_entries }
    rescue => e
      puts "find_set filed #{search_string}"
      puts e.backtrace.join("\n")
      nil
    end
  end

  # Find the first record matching the query
  def find_first(field, value)
    set = find_set("#{field}=#{value}")
    if set[:set_num].empty? || set[:num_entries].empty?
      Rails.logger.debug "No entries with field #{field} and value #{value} found"
      Rails.logger.debug set
      return nil
    end
    get_record(set[:set_num], '1')
  end


  # Query Aleph X Service for the Aleph DanMARC record for the corresponding
  # set number.  This is the second transaction in the two pass process of
  # getting Aleph DanMARC metadata for a book.  @param aleph_set_number the
  # set_number returned by Aleph for the book barcode which is then used to
  # get the DanMARC record for the eBook.  @return

  def get_record(set_number, entry_num)
    begin
      @http_service.do_post(@aleph_url, params = {
          :op        => "present",
          :set_no    => set_number,
          :set_entry => entry_num,
          :format    => "marc"})
    rescue => e
      logger.error e
    end
  end

  # Given a sysnum return the record
  # Convenience method
  # @param sysnum String
  # @return record String
  def find_by_sysnum(sysnum)
    set = find_set("sys=#{sysnum}")
    return nil if set.nil?
    get_record(set[:set_num], '1')
  end

  # Given an Aleph search string
  # retrieve set_data xml for the
  # corresponding result set.
  # @param search_string String e.g. "wbh=edod"
  def search_aleph(search_string)
    begin
      #logger.debug "Searching Aleph"
      @http_service.do_post(@aleph_url, params = {
                              :op      => 'find',
                              :base    => 'kgl01',
                              :code    => '',
                              :request => search_string })
    rescue => e
    
    end
  end
end
