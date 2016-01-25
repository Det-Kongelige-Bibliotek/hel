# Class to centralise inteface with SnippetServer
class SnippetServer
  def self.render_snippet(id,opts={})
    a =id.split("#")
    uri  = "#{Rails.application.config_for(:snippet)["snippet_server_url"]}"
    uri += "#{Rails.application.config_for(:snippet)["get_snippet_script"]}"
    uri += "?doc=#{a[0]}.xml"
    uri += "&id=#{a[1]}" unless a.size < 2
    uri += "&op=#{opts[:op]}" if opts[:op].present?
    uri += "&c=#{opts[:c]}" if opts[:c].present?
    uri += "&prefix=#{opts[:prefix]}" if opts[:prefix].present?
    Rails.logger.debug("snippet url #{uri}")

    #res = Net::HTTP.get_response(URI(uri))
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

  def self.facsimile(id)
    SnippetServer.render_snippet(id, {op: 'facsimile', prefix: Rails.application.config_for(:adl)["image_server_prefix"]})
  end
end
