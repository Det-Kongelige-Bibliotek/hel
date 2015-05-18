class LanguageCodeConverter
  def self.two_to_three(code)
    LANG_CODES[code]
  end

  def self.two_to_loc_ref(code)
    long_code = two_to_three(code)
    if long_code.present?
      three_to_loc_ref(long_code)
    else
      nil
    end
  end

  def self.tag_to_loc_ref(tag)
    code = tag.split('-').first
    if code.size == 2
      two_to_loc_ref(code)
    elsif code.size == 3
      three_to_loc_ref(code)
    else
      nil
    end
  end

  def self.three_to_loc_ref(code)
    "http://id.loc.gov/vocabulary/languages/#{code.downcase}"
  end
end