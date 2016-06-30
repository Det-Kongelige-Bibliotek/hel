# -*- encoding : utf-8 -*-
require "net/http"

class HttpService
  def do_post(uri_string, params)

    begin
      uri       = URI.parse(uri_string)
      uri.query = URI.encode_www_form(params)
      Rails.logger.debug "HTTPService:: Querying #{uri}"
      res       = Net::HTTP.get_response(uri)
    rescue Exception  => e
      puts "request failed #{uri_string}: #{e.message}"
      puts e.backtrace.join("\n")
    end
    # perhaps one should test res.is_a?(Net::HTTPSuccess)
    # rather than just catching the exception.
    res.body
  end
end
