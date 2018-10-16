require 'spec_helper'

describe 'account::user' do
  let(:title) do
    'jdoe'
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(classification: {
                      'stage' => nil,
                    })
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_user('jdoe') }
    end
    next unless facts[:os]['family'].eql? 'Solaris'
    context "on sun4v Solaris #{facts[:os]['release']['major']}" do
      let(:facts) do
        facts.merge(classification: {
                      'stage' => nil,
                    },
                    os: {
                      'architecture' => 'sun4v',
                      'hardware' => 'sun4v',
                    })
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_user('jdoe') }
    end
  end
end
