# Centrally defined variables to be shared between specs
# When you don't need to write to Fedora - use FactoryGirl
# When you do, use this file and include it in the describe context
# e.g.
# include_context 'shared'
# before :each do
#   @instance = Instance.new(instance_params)
# end
RSpec.shared_context 'shared' do
  let (:instance_params) { { collection: 'Sample', activity: 'Default', copyright: 'cc' }}
end
