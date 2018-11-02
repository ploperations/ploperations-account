# This is needed to test puppetlabs/acl on OSs other than Windows
RSpec.configure do |c|
  c.mock_with :rspec do |mocks|
    # Necessary to use allow_any_instance_of
    mocks.syntax = [:expect, :should]
  end

  c.before :each do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(
      Puppet::Type.type(:acl).provider(:windows),
    ).to(receive(:validate))
    # rubocop:enable RSpec/AnyInstance
  end
end
