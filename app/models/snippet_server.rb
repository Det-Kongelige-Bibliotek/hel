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
    puts "get #{uri}"
    uri = URI.parse(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 20
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
    request["Content-Type"] = 'application/x-www-form-urlencoded;charset=UTF-8'
    request.basic_auth username, password unless username.nil?
    request.form_data={'content' => body}
    puts uri
    puts body
    res = http.request(request)
    raise "post: #{self.snippet_server_url} response code #{res.code}" unless res.code == "200"
    puts "RES"
    puts res.body
    res
  end


  def self.ingest_file(uri,path)

  end

  def self.render_snippet(id,opts={})
    if id.include? '/'
      a = id[id.rindex('/')+1, id.length].split("-")
    else
      a =id.split("-")
    end
    opts[:doc] = "#{a[0]}.xml"
    opts[:id] = a[1] if a.size>1
    base = snippet_server_url
    base += "#{opts[:project]}" if opts[:project].present?
    puts "base #{base} #{get_snippet_script} #{opts.inspect}"
    uri = SnippetServer.contruct_url(base,get_snippet_script,opts)
    Rails.logger.debug("snippet url #{uri}")
    self.get(uri)
  end

  def self.solrize(id,opts={})
    opts[:op] = 'solrize'
    opts[:status] = 'created' unless opts[:status].present?
    SnippetServer.render_snippet(id, opts)
  end

  def self.toc(id,opts={})
    opts[:op] = 'toc'
    SnippetServer.render_snippet(id, opts)
  end

  def self.toc_facsimile(id,opts={})
    opts[:op] = 'toc-facsimile'
    SnippetServer.render_snippet(id, opts)
  end

  def self.author_portrait_has_text(id)
    text = self.render_snippet(id,{c: 'authors'}).to_str
    has_text(text)
  end

  def self.doc_has_text(id)
    text = self.render_snippet(id).to_str
    has_text(text)
  end

  def self.has_text(text)
    text = ActionController::Base.helpers.strip_tags(text).delete("\n")
    # check text length excluding pb elements
    text = text.gsub(/[s|S]\. [\w\d]+/,'').delete(' ')
    text.present?
  end

  def self.has_facsimile(id)
    html = SnippetServer.facsimile(id)
    xml = Nokogiri::HTML(html)
    return !xml.css('img').empty?
  end

  # return all image links for use in facsimile pdf view
  def self.image_links(id)
    html = SnippetServer.facsimile(id)
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


  def self.facsimile(id, opts={})
    opts[:op] = 'facsimile'
    SnippetServer.render_snippet(id, opts)
  end

  def self.update_letter(doc,id,json,opts={})
    opts[:id] = id
    opts[:doc] = doc
    uri  = SnippetServer.contruct_url(snippet_server_url_with_admin,"save.xq",opts)
    puts "update letter uri #{uri}"
    self.post(uri,json)
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
