# Class: account
#
# This class installs and manages local user accounts.
#
class account {

  file {'/usr/local/bin/setpass.rb':
    source => 'puppet:///modules/account/setpass.rb',
    owner  => 'root',
    group  => '0',
    mode   => '0755',
  }

  file { '/var/users':
    ensure => directory,
    owner  => 'root',
    group  => '0',
    mode   => '0700',
  }
}
