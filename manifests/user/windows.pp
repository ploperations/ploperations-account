# This is not intended to be used directly. Use account::user instead.
define account::user::windows (
  Enum['present', 'absent']                $ensure,
  Array[String[1]]                         $groups          = [],
  Optional[String[1]]                      $group           = undef,
  Optional[String]                         $comment         = undef,
  Optional[Sensitive]                      $password        = undef,
  Optional[Ssh::Key::String]               $key             = undef,
  Ssh::Key::Type                           $keytype         = 'ssh-rsa',
  Optional[Pattern[/^\d{4}-\d{2}-\d{2}$/]] $expire          = undef,
  Array[String[1]]                         $shared_accounts = [],
) {
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

  # Windows does not have deterministic profile paths, and you cannot create a
  # user's profile before the user has logged in for the first time. So, we
  # don't manage the user's profile on Windows.

  user { $title:
    ensure     => $_ensure,
    comment    => $comment,
    groups     => $combined_groups,
    password   => $password,
    managehome => false,
    membership => 'inclusive',
    expiry     => $expire,
  }

  ssh::windows::authorized_key { $title:
    ensure   => $_ensure,
    key      => $key,
    key_type => $keytype,
  }

  # In order to put people's SSH keys in the authorized_keys file of a
  # shared account, we iterate over a list of accounts they should
  # have access to. This is a pattern used for deploying, where a deploy
  # account is accessed by many users.

  if $_ensure == 'present' and $key {
    $shared_key_ensure = 'present'
  } else {
    $shared_key_ensure = 'absent'
  }

  # A profile should collect the ssh_authorized_key virtual resources
  $shared_accounts.each |String[1] $account_name| {
    @ssh_authorized_key { "${title} shared ${account_name} account::user":
      ensure => $shared_key_ensure,
      key    => $key,
      type   => $keytype,
      target => "${ssh::server::windows::authorized_keys_path}/${account_name}",
      tag    => "${account_name}-keys",
    }
  }
}
