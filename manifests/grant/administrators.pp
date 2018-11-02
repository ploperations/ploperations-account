# @summary Grant accounts Administrators access on Windows
#
# This takes all accounts in a specified group, and adds them to the
# Administrators group. On splatnix this does nothing.
#
# @example Give all the sysadmins administrative access
#   account::grant::administrators { 'sysadmin': }
#
# @param to_group
#   The group to give administrative access to. Generally, you should just use
#   the title.
define account::grant::administrators (
  String[1] $to_group = $title,
) {
  if $facts['os']['family'] == 'windows' {
    account::grant::group { "Administrators>${to_group}": }
  }
}
