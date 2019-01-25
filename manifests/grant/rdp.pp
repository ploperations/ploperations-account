# @summary Grant accounts RDP access on Windows
#
# This takes all accounts in a specified group, and adds them to the Remote
# Desktop Users group. On splatnix this does nothing.
#
# @example Give all users RDP access
#   account::grant::rdp { 'Users': }
#
# @param to_group
#   The group to give RDP access to. Generally, you should just use the title.
define account::grant::rdp (
  String[1] $to_group = $title,
) {
  if $facts['os']['family'] == 'windows' {
    account::grant::group { "Remote Desktop Users>${to_group}": }
  }
}
