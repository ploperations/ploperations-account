# @summary Grant accounts access to a specific group
#
# This grants all accounts with access to one group, access to another group.
#
# @example Add all sysadmins to the adm group
#   account::grant::group { 'adm>sysadmin': }
#
# @example Another way to add all sysadmins to the adm group
#   account::grant::group { 'give sysadmins adm access':
#     new_group => 'adm',
#     to_group  => 'sysadmin',
#   }
#
# @param new_group
#   The new group. Generally, you should just use the title.
# @param to_group
#   The group that will get the new access. Generally, you should just use the
#   title.
define account::grant::group (
  String[1] $new_group = $title.split('>')[0],
  String[1] $to_group = $title.split('>')[1],
) {
  User <| groups == $to_group or gid == $to_group |> {
    groups +> [$new_group],
  }
}
