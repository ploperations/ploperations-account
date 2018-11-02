# This is not intended to be used directly. Use account::user instead.
# @api private
define account::user::splatnix (
  Enum[present, absent]      $ensure,
  Optional[String]           $comment            = undef,
  Optional[String[1]]        $group              = undef,
  Array[String[1]]           $groups             = [],
  Stdlib::Unixpath           $shell              = '/bin/bash',
  Optional[Stdlib::Unixpath] $home               = undef,
  Optional[String[1]]        $home_source_module = undef,
  Optional[Integer[1]]       $uid                = undef,
  Boolean                    $usekey             = true,
  Optional[Ssh::Key::String] $key                = undef,
  Ssh::Key::Type             $keytype            = 'ssh-rsa',
  Optional[Account::Date]    $expire             = undef,
  Optional[Sensitive]        $password           = undef,
) {
  if $home {
    $user_home = $home
  } else {
    $user_home = $facts['kernel'] ? {
      'Darwin' => "/Users/${title}",
      default  => "/home/${title}",
    }
  }

  if $ensure == 'present' {
    case $facts['kernel'] {
      'Linux', 'SunOS': {
        include zsh
        Class['zsh'] -> User[$title]

        include bash
        Class['bash'] -> User[$title]
      }
      default: {}
    }

    $combined_groups = delete_undef_values($groups + [$group])
    realize(Group[$combined_groups])

    if $home_source_module {
      $home_source = "puppet:///modules/${home_source_module}/${name}"
    } else {
      $home_source = 'puppet:///modules/account/userdir_default'
    }

    if $facts['kernel'] == 'SunOS' {
      # The home directory in the user is not the same as the path to the
      # home directory on disk.
      $fs_home = "/export${user_home}"
    } else {
      $fs_home = $user_home
    }

    file { $fs_home:
      ensure  => directory,
      owner   => $title,
      group   => $group,
      recurse => remote,
      source  => $home_source,
    }

    if $usekey {
      $key_ensure = $key ? {
        String[1] => 'present',
        default   => 'absent',
      }

      ssh::authorized_key { "${name}@${group}":
        ensure  => $key_ensure,
        key     => $key,
        type    => $keytype,
        user    => $title,
        require => File[$fs_home],
      }

      if ! $key {
        # FIXME: why do we manage these only in this case? Need to audit internal
        # code so we can make this consistent.
        file { "${fs_home}/.ssh":
          ensure => directory,
          mode   => '0700',
        }

        file { "${fs_home}/.ssh/authorized_keys":
          ensure => file,
          mode   => '0600',
        }
      }
    }
  }

  $purge_ssh_keys = $ensure ? {
    'present' => $usekey,
    'absent'  => undef,
  }

  user { $title:
    ensure         => $ensure,
    comment        => $comment,
    gid            => $group,
    uid            => $uid,
    home           => $user_home,
    groups         => $groups,
    managehome     => false,
    password       => $password,
    shell          => $shell,
    expiry         => $expire,
    purge_ssh_keys => $purge_ssh_keys,
  }
}
