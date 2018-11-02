# Grant accounts access to a specific group
#
# This grants all accounts with access to one group, access to another group.
# For example, I might want to grant everybody in the sysadmin group access to
# adm group:
#
# ~~~ puppet
# account::grant::group { 'adm>sysadmin': }
# ~~~
#
# Another way of doing the same thing:
#
# ~~~ puppet
# account::grant::group { 'give sysadmins adm access':
#   new_group => 'adm',
#   to_group  => 'sysadmin',
# }
# ~~~
define account::grant::group (
  String[1] $new_group = $title.split('>')[0],
  String[1] $to_group = $title.split('>')[1],
) {
  User <| groups == $to_group or gid == $to_group |> {
    groups +> [$new_group],
  }
}
