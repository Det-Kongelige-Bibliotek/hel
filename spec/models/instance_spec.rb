require 'spec_helper'

# Since most Instance functionality is defined
# in Bibframe::Instance, most tests take place
# in the corresponding spec. Only test logic that
# is not encapsulated in Bibframe::Instance here,
# e.g. validations, relations etc.
describe Instance do
  it 'has many files' do
    i = Instance.new
    expect(i.content_files.size).to eql 0
  end
end
