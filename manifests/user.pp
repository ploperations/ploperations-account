# @summary Manage a user account
#
# @param ensure
#   Whether to ensure the user is present or absent on the node.
# @param group
#   Primary group for the user.
# @param groups
#   Secondary groups for the user. There is no distinction on Windows.
# @param comment
#   Comment field for the user. This is generally the user's name.
# @param shell
#   Full path to the user's preferred shell. This does nothing on Windows.
# @param home
#   Full path to the user's home directory. This does nothing on Windows.
# @param home_source_module
#   A module that contains files to put in the user's home directory, e.g.
#   .bashrc. By default, the home directory is just set up with a .README file
#   that explains how to use this parameter.
#
#   The module is expected to have a directory named after the user at the top
#   level that contains the user's files. For example, pass `profile/users`,
#   then create a `site/profile/files/luke/.bashrc` file.
#
#   This does nothing on Windows.
# @param uid
#   User id number for the user. This does nothing on Windows.
# @param usekey
#   Whether or not to manage SSH keys for the user. If this is false, then keys
#   will not be added or removed.
#
#   You can still set up keys externally if `$usekey` is false.
#
#   This doesn't do anything on Windows; it is effectively always true.
# @param key
#   SSH public key. This must not contain the type or the comment — it's just
#   the second part, after ssh-rsa or whatever your keytype is.
# @param keytype
#   The type of your SSH key.
# @param expire
#   When the user account expires in YYYY-MM-DD format.
# @param password
#   A password for the user. If this is left undefined, you will simply not be
#   able to use password authentication on splatnix (*nix: Linux, BSD, macOS,
#   and Solaris).
#
#   You may specify this in hiera under `account::user` parameter. See the
#   [Passwords section in README.md](https://github.com/ploperations/ploperations-account/blob/master/README.md#passwords).
#
#   Windows requires passwords. If it is not specified here or in hiera, this
#   will remove the user account.
# @param shared_accounts
#   An array of shared accounts to add the user's SSH key to. To activate,
#   collect the `Ssh::Authorized_key` virtual resources in a profile, e.g:
#
#   ~~~
#   Ssh::Authorized_key <| tag == "${shared_account}-keys" |>
#   ~~~
#
#   See the
#   [Shared accounts section in README.md](https://github.com/ploperations/ploperations-account/blob/master/README.md#shared-accounts).
define account::user (
  Enum['present', 'absent']  $ensure             = 'present',
  Optional[String[1]]        $group              = undef,
  Array[String[1]]           $groups             = [],
  Optional[String]           $comment            = undef,
  Stdlib::Unixpath           $shell              = '/bin/bash',
  Optional[String[1]]        $home               = undef,
  Optional[String[1]]        $home_source_module = undef,
  Optional[Integer[1]]       $uid                = undef,
  Boolean                    $usekey             = true,
  Optional[Ssh::Key::String] $key                = undef,
  Ssh::Key::Type             $keytype            = 'ssh-rsa',
  Optional[Account::Date]    $expire             = undef,
  Optional[Sensitive]        $password           = undef,
  Array[String[1]]           $shared_accounts    = [],
) {
  include account

  if $password {
    $_password = $password
  } else {
    $hiera_accounts = lookup({
      name          => 'account::user',
      value_type    => Hash[String[1], Hash],
      default_value => {},
    })

    $_password_raw = $facts['os']['family'] ? {
      'windows' => $hiera_accounts.dig($title, 'windows_password'),
      default   => $hiera_accounts.dig($title, 'crypted_password'),
    }

    $_password = $_password_raw ? {
      String  => Sensitive($_password_raw),
      default => $_password_raw,
    }
  }

  if $facts['os']['family'] == 'windows' {
    account::user::windows { $title:
      ensure   => $ensure,
      group    => $group,
      groups   => $groups,
      comment  => $comment,
      key      => $key,
      keytype  => $keytype,
      expire   => $expire,
      password => $_password,
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
    }
  }

  if $ensure == 'present' and $usekey and $key {
    # In order to put people's SSH keys in the authorized_keys file of a
    # shared account, we iterate over a list of accounts they should
    # have access to. This is a useful pattern used for deploying, where many
    # users might need access to a single account.

    $all_shared_accounts = $account::common_shared_accounts + $shared_accounts
    $all_shared_accounts.each |String[1] $shared_account| {
      @ssh::authorized_key { "${title}@${shared_account}":
        ensure => 'present',
        key    => $key,
        type   => $keytype,
        user   => $shared_account,
        tag    => "${shared_account}-keys",
      }
    }
  }
}
