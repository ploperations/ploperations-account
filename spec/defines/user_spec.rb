require 'spec_helper'

describe 'account::user' do
  let(:title) do
    'jdoe'
  end

  on_supported_os.each do |os, facts|
    let(:facts) do
      facts.merge(classification: {
                    'stage' => nil,
                  })
    end

    let(:pre_condition) do
      'function node_encrypt::secret ($foo) { $foo }'
    end

    context "on #{os}" do
      context 'without a password' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_user('jdoe') }
      end

      context 'with plain text password' do
        let(:params) do
          { 'password' => RSpec::Puppet::RawString.new("Sensitive('myPassword')") }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_user('jdoe') }
      end
    end
  end
end
