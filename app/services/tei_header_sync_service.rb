require 'open3'

# Responsible for keeping the teiHeader in sync with the hydra chronos metadata

class TeiHeaderSyncService

  def self.perform(sheet,tei_file,inst)

    # sheet    is for the actual editing fo the tei header
    # tei_file is the complete path and name of the file to be updated
    # inst     is the instance corresponding to the file

    # because of nokogiri and/or ruby we have to pass the parameters in a less
    # capable form

    parameters = {}

    # authors is assigned to the work
    work = inst.work.first
    author = work.authors.first

    # we loop through the authors. As of writing this, the sheet only supports
    # three authors, which is more than enough for a novel in ADL but
    # insufficient for a paper in the journal Nature

    work.authors.each_with_index do |a,i|
      aut = a.authorized_personal_names.values.first
      parameters["first#{i}"] = aut[:given]
      parameters["last#{i}"]  = aut[:family]
    end

    #
    # This didn't work very well. Leave it here as a memo for the time being
    #
    #   myfuncs = Class.new do
    #      def family
    #        @alist.first[:family]
    #        "mongrel"
    #      end
    #      def given
    #        @alist.first[:given]
    #      end
    #    end
    #    
    #    Nokogiri::XSLT.register "http://example.com/functions", myfuncs
    #

    # here we do the same for the titles. should rethink this if we find sub
    # titles in ADL (which we will do if we look for them)

    work.titles.each_with_index do |tit,i|
      parameters["title#{i}"]          = tit.value
      parameters["title_lang#{i}"]     = tit.lang
      parameters["sub_title_lang#{i}"] = tit.subtitle
    end

    #
    # The remaining instance data
    #
    parameters[:publisher] = inst.publisher_name
    parameters[:pub_place] = inst.published_place
    parameters[:date]      = inst.published_date

    xslt = Nokogiri::XSLT(File.read(sheet))
    doc = Nokogiri::XML.parse(File.read(tei_file)) { |config| config.strict }
    rdoc = xslt.transform(doc,Nokogiri::XSLT.quote_params(parameters))
    File.open(tei_file, 'w') { |f| f.print(rdoc.to_xml) }

  end
  
end
