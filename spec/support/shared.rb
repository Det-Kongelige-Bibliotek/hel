# Centrally defined variables to be shared between specs
# When you don't need to write to Fedora - use FactoryGirl
# When you do, use this file and include it in the describe context
# e.g.
# include_context 'shared'
# before :each do
#   instance = Instance.new(instance_params)
# end
RSpec.shared_context 'shared' do
  let (:instance_params) { { collection: 'Sample', activity: Administration::Activity.create(activity: 'test').id, copyright: 'cc' }}
  let (:valid_trykforlaeg) { instance_params.merge(isbn13: '9780521169004', published_date: '2004')}
  before do
    agent = Authority::Person.create(
        'authorized_personal_name' => { 'given'=> 'Proinsias', 'family' => 'De Rossa', 'scheme' => 'KB', 'date' => '1932/2009' }
    )
    @valid_work = Work.new
    @valid_work.add_title({'value'=> 'A title'})
    @valid_work.add_author(agent)
    @valid_work.save # for these tests to work. Object has to be persisted. Otherwise relations cannot be updated
    rel = Work.new
    rel.add_title({'value'=> 'A title'})
    rel.add_author(agent)
    rel.save # for
    @valid_work
  end
end
