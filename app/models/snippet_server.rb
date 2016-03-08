# Class to centralise inteface with SnippetServer
class SnippetServer

  def self.snippet_server_url
    "#{Rails.application.config_for(:snippet)["snippet_server_url"]}"
  end

  def self.snippet_server_url_with_admin
    "#{Rails.application.config_for(:snippet)["snippet_server_url_with_admin"]}"
  end

  def self.get_snippet_script
    "#{Rails.application.config_for(:snippet)["get_snippet_script"]}"
  end

  def self.get(uri)
    Rails.logger.debug "SNIPPET SERVER GET #{uri}"
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 600
    begin
      res = http.start { |conn| conn.request_get(URI(uri)) }
      if res.code == "200"
        result = res.body
      else
        result ="<div class='alert alert-danger'>Unable to connect to data server</div>"
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "Could not connect to #{uri}"
      Rails.logger.error e
      result ="<div class='alert alert-danger'>Unable to connect to data server</div>"
    end

    result.html_safe.force_encoding('UTF-8')
  end

  def self.put(url,body)
    username = Rails.application.config_for(:snippet)["snippet_server_user"]
    password = Rails.application.config_for(:snippet)["snippet_server_password"]
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Put.new(uri.request_uri)
    request["Content-Type"] = 'text/xml;charset=UTF-8'
    request.basic_auth username, password unless username.nil?
    request.body = body
    res = http.request(request)
    raise "put : #{self.snippet_server_url} response code #{res.code}" unless res.code == "201"
    res
  end

  def self.post(url,body)
    username = Rails.application.config_for(:snippet)["snippet_server_user"]
    password = Rails.application.config_for(:snippet)["snippet_server_password"]
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = 'application/json;charset=UTF-8'
    request.basic_auth username, password unless username.nil?
    request.body = body
    res = http.request(request)
    raise "post: #{self.snippet_server_url} response code #{res.code}" unless res.code == "200"
    Rails.logger.debug "RES"
    Rails.logger.debug res.body
    res
  end

  def self.ingest_file(uri,path)

  end

  def self.render_snippet(opts={})
    base = snippet_server_url
    base += "#{opts[:project]}" if opts[:project].present?
    Rails.logger.debug "render snippet base #{base} #{get_snippet_script} #{opts.inspect}"
    uri = SnippetServer.contruct_url(base,get_snippet_script,opts)
    Rails.logger.debug("snippet url #{uri}")
    self.get(uri)
  end

  def self.solrize(opts={})
    opts[:op] = 'solrize'
    opts[:status] = 'created' unless opts[:status].present?
    SnippetServer.render_snippet(opts)
  end

  def self.doc_has_text(opts={})
    text = self.render_snippet(id).to_str
    has_text(text)
  end

  def self.has_text(text)
    text = ActionController::Base.helpers.strip_tags(text).delete("\n")
    # check text length excluding pb elements
    text = text.gsub(/[s|S]\. [\w\d]+/,'').delete(' ')
    text.present?
  end

  def self.has_facsimile(opts={})
    html = SnippetServer.facsimile(opts)
    xml = Nokogiri::HTML(html)
    return !xml.css('img').empty?
  end

  # return all image links for use in facsimile pdf view
  def self.image_links(opts={})
    html = SnippetServer.facsimile(opts)
    xml = Nokogiri::HTML(html)
    links = []
    xml.css('img').each do |img|
      links << img['data-src']
    end
    links
  end

 def self.preprocess_tei(xml_source)
   xslt = Nokogiri.XSLT(
          File.join(Rails.root,'app/export/transforms/preprocess.xsl'))
   doc = Nokogiri::XML.parse(xml_source) { |config| config.strict }
   rdoc = xslt.transform(doc)
   rdoc
  end


  def self.facsimile(opts={})
    opts[:op] = 'facsimile'
    opts[:prefix] = Rails.application.config_for(:snippet)["image_server_prefix"]
    SnippetServer.render_snippet(opts)
  end

  def self.update_letter(json,opts={})
    uri  = SnippetServer.contruct_url(snippet_server_url_with_admin,"save.xq",opts)
    Rails.logger.debug "update letter uri #{uri} data #{json}"
    self.post(uri,json)
  end

  # get doc and id arguments form a solr id
  def self.split_letter_id(id)
    if id.include? '/'
      a = id[id.rindex('/')+1, id.length].split("-")
    else
      a =id.split("-")
    end
    {doc: "#{a[0]}.xml", id: a[1]}
  end

  #get collection from a solr id
  def self.get_collection(id)
    "/db#{ id[0,id.rindex('/')] }"
  end

  private

  def self.contruct_url(base,script,opts={})
    uri = base
    uri += "/"+script
    uri += "?doc=#{opts[:doc]}" if opts[:doc].present?
    uri += "&id=#{URI.escape(opts[:id])}"  if opts[:id].present?
    uri += "&op=#{URI.escape(opts[:op])}" if opts[:op].present?
    uri += "&c=#{URI.escape(opts[:c])}" if opts[:c].present?
    uri += "&prefix=#{URI.escape(opts[:prefix])}" if opts[:prefix].present?
    uri += "&work_id=#{URI.escape(opts[:work_id])}" if opts[:work_id].present?
    uri += "&status=#{URI.escape(opts[:status])}" if opts[:status].present?
    uri
  end
end
