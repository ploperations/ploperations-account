# This is not intended to be used directly. Use account::user instead.
# @api private
define account::user::windows (
  Enum['present', 'absent']  $ensure,
  Array[String[1]]           $groups   = [],
  Optional[String[1]]        $group    = undef,
  Optional[String]           $comment  = undef,
  Optional[Sensitive]        $password = undef,
  Optional[Ssh::Key::String] $key      = undef,
  Ssh::Key::Type             $keytype  = 'ssh-rsa',
  Optional[Account::Date]    $expire   = undef,
) {
  include account

  $combined_groups = delete_undef_values($groups + [$group])
  $combined_groups.each |$g| {
    Group <| title == $g |> {
      gid => undef,
    }
  }

  if ! $password {
    # Windows can't create a user without a password. Furthermore, recreating an
    # absent user without a password will result in the user having its original
    # password.
    $_ensure = 'absent'
  } else {
    $_ensure = $ensure
  }

  # You cannot create a user's profile before the user has logged in for the
  # first time. So, we don't manage the user's profile on Windows.

  user { $title:
    ensure     => $_ensure,
    comment    => $comment,
    groups     => $combined_groups,
    password   => $password,
    managehome => false,
    membership => 'inclusive',
    expiry     => $expire,
  }

  ssh::authorized_key::file { $title:
    ensure => $_ensure,
  }

  if $_ensure == 'present' {
    ssh::authorized_key { $title:
      ensure => 'present',
      key    => $key,
      type   => $keytype,
    }

    if $account::cygwin {
      # We can create the Cygwin user directory before the user has logged in.
      file {
        default:
          ensure => 'directory',
          owner  => $title,
        ;
        cygwin::windows_path("/home/${title}"):;
        cygwin::windows_path("/home/${title}/.ssh"):;
      }

      acl { cygwin::windows_path("/home/${title}"):
        purge                      => true,
        inherit_parent_permissions => false,
        permissions                => [
          {'identity' => 'NT AUTHORITY\SYSTEM', 'rights' => ['full']},
          {'identity' => 'Administrators', 'rights' => ['full']},
          {'identity' => $title, 'rights' => ['full']},
          {'identity' => 'Everyone', 'rights' => ['read']},
        ],
      }

      acl { cygwin::windows_path("/home/${title}/.ssh"):
        purge                      => true,
        inherit_parent_permissions => false,
        permissions                => [
          {'identity' => 'NT AUTHORITY\SYSTEM', 'rights' => ['full']},
          {'identity' => 'Administrators', 'rights' => ['full']},
          {'identity' => $title, 'rights' => ['full']},
        ],
      }
    }
  }
}
