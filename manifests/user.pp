# Manage a user account
#
# $usekey indicates whether we should manage SSH authorized keys with this
# defined type, not whether or not SSH keys are used at all.
define account::user (
  Enum['present', 'absent']     $ensure             = 'present',
  Enum[
    '/bin/bash',
    '/bin/sh',
    '/bin/zsh',
    '/bin/false',
    '/usr/sbin/nologin',
    '/usr/bin/git-shell'
  ]                             $shell              = '/bin/bash',
  Optional[String[1]]           $home               = undef,
  Optional[String[1]]           $group              = undef,
  Optional[Array[String]]       $groups             = undef,
  Optional[Variant[Integer, Pattern[/^\d*$/]]] $uid = undef,
  Boolean                       $usekey             = true,
  Optional[String[1]]           $key                = undef,
  Enum['ssh-rsa', 'ssh-dsa', 'ssh-dss', 'rsa'] $keytype = 'ssh-rsa',
  Optional[String]              $email              = '',
  Optional[Pattern[/^\d{4}-\d{2}-\d{2}$/]] $expire  = undef,
  Optional[String[1]]           $comment            = undef,
  Boolean                       $hushlogin          = false,
  Optional[String[1]]           $password           = undef,
  Array[String[1]]              $shared_accounts    = [],
  Optional[String[1]]           $home_source_module = undef,
) {
  include account

  case $facts['kernel'] {
    'Linux','SunOS': {
      include zsh
      include bash

      $require_shells = [
        Class['bash'],
        Class['zsh'],
      ]
    }
    default: {
      $require_shells = []
    }
  }

  if $group {
    realize(Group[$group])
  }

  if $groups {
    realize(Group[$groups])
  }

  # Test if we are managing home directories
  if $home { # Set home
    $homedir = $home
  } else {
    $homedir = $facts['kernel'] ? {
      'Darwin' => "/Users/${name}",
      default  => "/home/${name}",
    }
  }

  if $hushlogin {
    $hushlogin = "${homedir}/.hushlogin"
    file { $hushlogin:
      ensure  => present,
      content => ' ',
    }
  }

  if $uid {
    $userid = $uid
  } else {
    $userid = undef
  }

  $user_purge_ssh_keys = $ensure ? {
    'present' => $usekey,
    'absent'  => undef,
  }

  user { $name:
    ensure         => $ensure,
    gid            => $group,
    uid            => $userid,
    home           => $homedir,
    groups         => $groups,
    comment        => $comment,
    managehome     => false,
    password       => $password,
    shell          => $shell,
    expiry         => $expire,
    purge_ssh_keys => $user_purge_ssh_keys,
    require        => $require_shells
  }

  # Only if we are ensuring a user is present
  if $ensure == 'present' {
    File {
      owner => $name,
      group => $group,
    }

    if $facts['kernel'] == 'SunOS' {
      if $home {
        $real_homedir = $home
      } else {
        $real_homedir = "/export${homedir}"
      }
    } else {
      $real_homedir = $homedir
    }

    if $home_source_module {
      $home_source = "puppet:///modules/${home_source_module}/${name}"
    } else {
      $home_source = 'puppet:///modules/account/userdir_default'
    }

    file { $real_homedir:
      ensure  => directory,
      recurse => remote,
      source  => $home_source,
    }

    # Only if we are using key auth
    if $usekey {
      if $key {
        ssh_authorized_key { "${name}@${group}":
          ensure  => present,
          key     => $key,
          type    => $keytype,
          user    => $name,
          require => File[$real_homedir],
        }

        # in order to put people's SSH keys in the authorized_keys file of a
        # shared account, we iterate over a list of accounts they should
        # have access to. This is a pattern used for deploying, where a deploy
        # account is accessed by many users.
        # a profile should collect the ssh_authorized_key virtual resources

        # grandfather in all users having access to gitmirror
        $all_shared_accounts = $shared_accounts + ['gitmirror', 'git']
        $all_shared_accounts.each |String[1] $account_name| {
          @ssh_authorized_key { "${name}@${account_name}":
            ensure  => present,
            key     => $key,
            type    => $keytype,
            user    => $account_name,
            tag     => "${account_name}-keys",
            require => File[$real_homedir],
          }
        }
      } else {
        file { "${real_homedir}/.ssh":
          ensure => directory,
          mode   => '0700',
        }

        file { "${real_homedir}/.ssh/authorized_keys":
          mode    => '0600',
        }
      }
    }
  }
}
