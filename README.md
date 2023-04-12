# Manage user accounts

![](https://img.shields.io/puppetforge/pdk-version/ploperations/account.svg?style=popout)
![](https://img.shields.io/puppetforge/v/ploperations/account.svg?style=popout)
![](https://img.shields.io/puppetforge/dt/ploperations/account.svg?style=popout)
[![Build Status](https://github.com/ploperations/ploperations-account/actions/workflows/pr_test.yml/badge.svg?branch=main)](https://github.com/ploperations/ploperations-account/actions/workflows/pr_test.yml)

This module manages user accounts on Linux, FreeBSD, macOS, and Windows. It
supports managing overlapping groups of users across many nodes.

It can (optionally) use the [ploperations/ssh][] module to set up SSH keys for
each user. (The module must be installed, but it doesn't have to be used.)

#### Table of Contents

- [Quick start](#quick-start)
- [Usage](#usage)
  - [`uid` and `gid` gotchas](#uid-and-gid-gotchas)
  - [Passwords](#passwords)
  - [Predefining home directory files](#predefining-home-directory-files)
  - [Shared accounts](#shared-accounts)
  - [Cygwin](#cygwin)
  - [`account::grant` and friends](#accountgrant-and-friends)
- [Reference](#reference)

## Quick start

Create a centralized class (or classes) to define all of the users that might
be used on any node. Define each user as a [virtual][] `account::user` resource,
and each group as a virtual `group`:

```puppet
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
```

To realize users on a particular node, just use a collector in a profile:

```puppet
class profile::base {
  Account::User <| groups == 'admins' |>
}
```

You can realize multiple overlapping groups:

```puppet
class profile::access::puppet {
  Account::User <| groups == 'admins' |>
  Account::User <| groups == 'puppet' |>
}
```

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

```
# find / -user 1001 -print0 | xargs -0 chown 1034
```

(1001 is the old `uid` and 1034 is the new `uid`.)

`uid` and `gid` are ignored on Windows.

### Passwords

Passwords are handled differently on splatnix (Linux, BSD, etc.) and Windows.
On splatnix, the password must be in `crypt` format, and on Windows, the
password must be plain text.

For those reasons it's better to put the passwords in hiera rather than pass
them directly to the `account::user` resource. Here's an example of a user that
has the password “hunter2” on both Windows an Linux.

```yaml
account::user:
  adam:
    windows_password: 'hunter2'
    crypted_password: '$1$QQ8nAVHM$QvthrGVnY2BNu1bJmi7u90'
```

It's better yet to encrypt those values with [Hiera eyaml][]. Using eyaml would
result in something like the following:

```yaml
account::user:
  adam:
    windows_password: ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIBajCCAWYCA...ghP+fdY1Wd]
    crypted_password: ENC[PKCS7,MIIBmQYJKoZIhvcNAQcDoIIBijCCAYYCA...SqktJ8Sk8=]
```

Note the accounts must have passwords on Windows. Defining `account::user`
without a password on Windows will cause that user to be removed.

Passwords come into `account::user` with the [Sensitive][] type. From there
`node_encrypt::secret()` takes over. The string is encrypted on the master,
and then decrypted on the agent during catalog application. The `node_encrypt`
module takes advantage of Deferred functions to do the decryption. You can
read more about this at https://forge.puppet.com/binford2k/node_encrypt

### Predefining home directory files

Some users may have custom configuration they always want in their home
directory. You can use the `home_source_module` parameter to accomplish that.
For example, you could add a custom `.bashrc` for `luke` by 1) adding the
`home_source_module` parameter:

```puppet
home_source_module => 'profile/users`
```

Then, 2) create a `luke` directory with his `.bashrc` under the `profile::users`
class, e.g. `site/profile/files/users/luke/.bashrc`.

`home_source_module` does nothing on Windows.

### Shared accounts

`account::user` provides for creating shared accounts, e.g. a `deploy` account
that multiple users can SSH into.

In order for this to work, you have to realize the `Ssh::Authorized_key`s, for
the shared account. Those resources are created with the tag
`${shared_account}-keys`. For example, the shared `deploy` account would have
keys with the tag `deploy-keys`.

```puppet
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
```

You may specify shared accounts for all users in hiera. These cannot be
overidden per user.

```yaml
account::common_shared_accounts:
  - 'shared'
```

### Cygwin

If you're using Cygwin, you must specify `cygwin::enable: true` in hiera.

### `account::grant` and friends

`account::grant` is used to add users to groups conditionally. Somewhat
confusingly, it selects the users to add based on group as well. An example
will probably help.

Suppose you have a `sysadmin` group that should have administrative access on
all nodes. You might want to give them access to the `adm` group as well. You
can do like this:

```puppet
account::grant::group { 'adm>sysadmin': }
```

This is particularly useful to grant certain users Administrators access on
only a few Windows nodes. For convenience, you can use
`account::grant::administrators`. For example:

```puppet
@group { ['Administrators', 'puppet-agent-team']: }
account::grant::administrators { 'puppet-agent-team': }
```

## Reference

There are more examples and specific documentation for individual parameters in
[REFERENCE.md][]. That file is generated with:

```
pdk bundle exec puppet strings generate --format markdown
```

[Hiera eyaml]: https://github.com/voxpupuli/hiera-eyaml
[Sensitive]: https://puppet.com/docs/puppet/latest/lang_data_sensitive.html
[ploperations/ssh]: https://github.com/ploperations/ploperations-ssh
[REFERENCE.md]: https://github.com/ploperations/ploperations-account/blob/master/REFERENCE.md
[virtual]: https://puppet.com/docs/puppet/latest/lang_virtual.html
