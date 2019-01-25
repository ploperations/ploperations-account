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

    context "on #{os}" do
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_user('jdoe') }
    end
  end
end
