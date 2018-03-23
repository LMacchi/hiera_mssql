require 'spec_helper'

describe 'hiera_mssql' do
  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      describe 'when called with no parameters' do
        it do
          is_expected.to contain_package('jdbc-sqlserver').with(
            'ensure'   => 'present',
            'provider' => 'puppetserver_gem',
          )
          is_expected.to contain_package('java').with(
            'ensure'   => 'present',
            'provider' => 'puppetserver_gem',
          )
          is_expected.to contain_package('tiny_tds').with(
            'ensure'   => 'present',
            'provider' => 'puppet_gem',
          )
        end
      end
    end
  end
end
