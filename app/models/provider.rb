class Provider < ActiveFedora::Base
  property :copyright_date, predicate: ::RDF::Vocab::Bibframe.copyrightDate, multiple: false
  property :provider_date, predicate: ::RDF::Vocab::Bibframe.providerDate, multiple: false
  property :role, predicate: ::RDF::Vocab::Bibframe.providerRole, multiple: false
  belongs_to :agent, predicate: ::RDF::Vocab::Bibframe.providerName, class_name: 'Authority::Organization'
  belongs_to :place, predicate: ::RDF::Vocab::Bibframe.providerPlace, class_name: 'Authority::Place'

  validates_each :copyright_date, :provider_date do |record, attr, val|
    record.errors.add(attr, I18n.t('edtf.error_message')) if val.present? && EDTF.parse(val).nil?
  end
end