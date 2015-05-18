class LanguageCodeConverter
  def self.two_to_three(code)
    LANG_CODES[code]
  end

  def self.two_to_loc_ref(code)
    long_code = two_to_three(code)
    if long_code.present?
      "http://id.loc.gov/vocabulary/languages/#{long_code}"
    else
      nil
    end
  end
end