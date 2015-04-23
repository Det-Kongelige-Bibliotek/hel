module Datastreams
  module Bibframe
    # present easy accessors for title attributes
    class Title
        attr_reader :type, :value, :subtitle, :lang

        # Create new object from a Nokogiri::XML::Element
        def initialize(xml=nil)
          if xml.nil?
            return
          end
          @type = xml.css('bf|titleType').text
          @subtitle = xml.css('bf|subtitle').text
          val_node = xml.css('bf|titleValue')
          @value = val_node.text
          @lang = val_node.attr('lang').present? ? val_node.attr('lang').text : nil
        end

        def blank?
          @type.blank? && @value.blank? && @subtitle.blank? && @lang.blank?
        end

        def present?
          @type.present? || @value.present? || @subtitle.present? || @lang.present?
        end
    end
  end
end
