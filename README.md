# Manage user accounts

This module manages user accounts on Linux, FreeBSD, macOS, and Windows. It
supports managing overlapping groups of users across many nodes.

It can (optionally) use the [ploperations/ssh][] module to set up SSH keys for
each user. (The module must be installed, but it doesn't have to be used.)

#### Table of Contents

1. [Quick start](#quick-start)
2. [Usage](#usage)
    * [`uid` and `gid` gotchas](#uid-and-gid-gotchas)
    * [Passwords](#passwords)
    * [Predefining home directory files](#predefining-home-directory-files)
    * [Shared accounts](#shared-accounts)
    * [Cygwin](#cygwin)
    * [`account::grant` and friends](#accountgrant-and-friends)
3. [Reference][REFERENCE.md]

## Quick start

Create a centralized class (or classes) to define all of the users that might
be used on any node. Define each user as a [virtual][] `account::user` resource,
and each group as a virtual `group`:

~~~ puppet
@group {
  'users':  uid => 1000;
  'admins': uid => 1001;
  'puppet': uid => 1002;
}

@account::user { 'luke':
  uid     => 1000,
  group   => 'users'
  groups  => ['admins', 'puppet'],
  key     => 'AAAAB3NzaC...2RxOBG+CeNcUeiLWPUQ==',
  keytype => 'ssh-rsa',
}

@account::user { 'daniel':
  uid     => 1001,
  group   => 'users'
  groups  => ['puppet'],
  key     => 'AAAAC3NzaC1lZDI1NTE5AAAAII6GXwvVY2ncrtsmOmylMweuOtBSUNS7gZXyjWR37oEL',
  keytype => 'ssh-ed25519',
}
~~~

To realize users on a particular node, just use a collector in a profile:

~~~ puppet
class profile::base {
  Account::User <| groups == 'admins' |>
}
~~~

You can realize multiple overlapping groups:

~~~ puppet
class profile::access::puppet {
  Account::User <| groups == 'admins' |>
  Account::User <| groups == 'puppet' |>
}
~~~

Note that you do not need to realize the groups directly; `account::user` will
do that for you.

## Usage

### `uid` and `gid` gotchas

You may leave out the `uid` and `gid` parameters.

**Either always set `uid`, or never set `uid`.** If you set `uid`s for some
users but not for others, you will inevitably get uid conflicts when you make
changes. The same is true for groups.

Note that changing a user's `uid` will not update the `uid `on all of that
user's files. In order to do that, you will need to run something like the
following on each affected node:

~~~
# find / -user 1001 -print0 | xargs -0 chown 1034
~~~

(1001 is the old `uid` and 1034 is the new `uid`.)

`uid` and `gid` are ignored on Windows.

### Passwords

# TODO

### Predefining home directory files

Some users may have custom configuration they always want in their home
directory. You can use the `home_source_module` parameter to accomplish that.
For example, you could add a custom `.bashrc` for `luke` by 1) adding the
`home_source_module` parameter:

~~~ puppet
home_source_module => 'profile/users`
~~~

Then, 2) create a `luke` directory with his `.bashrc` under the `profile::users`
class, e.g. `site/profile/files/users/luke/.bashrc`.

`home_source_module` does nothing on Windows.

### Shared accounts

`account::user` provides for creating shared accounts, e.g. a `deploy` account
that multiple users can SSH to.

~~~ puppet
class profile::users {
  @account::user { 'gene':
    uid             => 1002,
    group           => 'users'
    groups          => ['admins', 'puppet'],
    key             => 'AAAAC3NzaC1lZDI1NTE5AAAAIEWkzdlEVmGoAcboiwE16uCuN5dg8xy5mcCPfVnsXMTq',
    keytype         => 'ssh-ed25519',
    shared_accounts => ['deploy'],
  }

  @group { 'deploy': gid => 2000 }

  @account::user { 'deploy':
    uid   => 2000,
    group => 'deploy',
  }
}

class profile::deploy {
  realize Account::User['deploy']
  Ssh::Authorized_key <| tag == "deploy-keys" |>
}
~~~

You may specify shared accounts for all users in hiera. These cannot be
overidden per user.

~~~ yaml
account::common_shared_accounts:
  - 'shared'
~~~

### Cygwin

If you're using Cygwin, you must specify `cygwin::enable: true` in hiera.

### `account::grant` and friends

# TODO

## Reference

See [REFERENCE.md][]. That file is generated with:

~~~
pdk bundle exec puppet strings generate --format markdown
~~~

[ploperations/ssh]: https://github.com/ploperations/ploperations-ssh
[REFERENCE.md]: https://github.com/ploperations/ploperations-account/blob/master/REFERENCE.md
[virtual]: https://puppet.com/docs/puppet/latest/lang_virtual.html
