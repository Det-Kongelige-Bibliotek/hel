# Centrally defined variables to be shared between specs
# When you don't need to write to Fedora - use FactoryGirl
# When you do, use this file and include it in the describe context
# e.g.
# include_context 'shared'
# before :each do
#   @instance = Instance.new(instance_params)
# end
RSpec.shared_context 'shared' do
  let (:instance_params) { { collection: 'Sample', activity: Administration::Activity.create(activity: 'test', preservation_profile: 'Undefined').id, copyright: 'cc' }}
  let (:valid_trykforlaeg) { instance_params.merge(isbn13: '9780521169004', type: 'trykforlæg')} #, published_date: '2004')}
  let (:title) { Title.new(value: 'Dubliners')}
  let(:person) { Authority::Person.new(given_name: 'James', family_name: 'Joyce')}
  let (:work_params) { {titles: [ title ] } }
  let (:org_params) {  { same_as: 'http://viaf.org/viaf/127954890', _name: 'Gyldendalske boghandel, Nordisk forlag', founding_date: '1770' }}
end
