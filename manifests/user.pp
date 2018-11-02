# Manage a user account
#
# $usekey indicates whether we should manage SSH authorized keys with this
# defined type, not whether or not SSH keys are used at all.
define account::user (
  Enum['present', 'absent']                $ensure             = 'present',
  Optional[String[1]]                      $group              = undef,
  Array[String[1]]                         $groups             = [],
  Optional[String]                         $comment            = undef,
  Enum[
    '/bin/bash',
    '/bin/sh',
    '/bin/zsh',
    '/bin/false',
    '/usr/sbin/nologin',
    '/usr/bin/git-shell'
  ]                                        $shell              = '/bin/bash',
  Optional[String[1]]                      $home               = undef,
  Optional[String[1]]                      $home_source_module = undef,
  Optional[Integer[1]]                     $uid                = undef,
  Boolean                                  $usekey             = true,
  Optional[Ssh::Key::String]               $key                = undef,
  Ssh::Key::Type                           $keytype            = 'ssh-rsa',
  Optional[Pattern[/^\d{4}-\d{2}-\d{2}$/]] $expire             = undef,
  Optional[Sensitive]                      $password           = undef,
  Array[String[1]]                         $shared_accounts    = [],
) {
  include account
  $all_shared_accounts = $account::common_shared_accounts + $shared_accounts

  if $password {
    $_password = $password
  } else {
    $hiera_accounts = lookup({
      name          => 'account::user',
      value_type    => Hash[String[1], Variant[String[1], Sensitive, Hash]],
      default_value => {},
    })

    $maybe_password = $hiera_accounts[$title]
    $_password = $maybe_password ? {
      Hash      => Sensitive($maybe_password['password']),
      String    => Sensitive($maybe_password),
      Sensitive => $maybe_password,
      undef     => undef,
    }
  }

  if $facts['kernel'] == 'windows' {
    account::user::windows { $title:
      ensure          => $ensure,
      group           => $group,
      groups          => $groups,
      comment         => $comment,
      key             => $key,
      keytype         => $keytype,
      expire          => $expire,
      password        => $_password,
      shared_accounts => $all_shared_accounts,
    }
  } else {
    account::user::splatnix { $title:
      ensure             => $ensure,
      group              => $group,
      groups             => $groups,
      comment            => $comment,
      shell              => $shell,
      home               => $home,
      home_source_module => $home_source_module,
      uid                => $uid,
      usekey             => $usekey,
      key                => $key,
      keytype            => $keytype,
      expire             => $expire,
      password           => $_password,
      shared_accounts    => $all_shared_accounts,
    }
  }
}
