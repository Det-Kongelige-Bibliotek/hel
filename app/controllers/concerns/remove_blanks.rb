module Concerns
  module RemoveBlanks
    extend ActiveSupport::Concern
    included do
      # Remove any blank attribute values, including those found in Arrays and Hashes
      # to prevent AF being updated with empty values.
      def remove_blanks(param_hash)
        param_hash.each do |k, v|
          if v.is_a? String
            #  param_hash.delete(k) unless v.present?
          elsif v.is_a? Array
            param_hash[k] = v.reject(&:blank?)
          elsif v.is_a? Hash
            param_hash[k] = clean_hash(v)
            param_hash.delete(k) unless param_hash[k].present?
          end
        end
        param_hash
      end

      def clean_hash(value_hash)
        value_hash.each do |k, v|
          if v.is_a? String
            value_hash.delete(k) unless v.present?
          elsif v.is_a? Hash
            value_hash[k] = clean_hash(v)
            value_hash.delete(k) unless value_hash[k].present?
          elsif v.is_a? Array
            value_hash[k] = v.reject {|n| n.blank?}
          end
        end
        value_hash
      end
    end
  end
end