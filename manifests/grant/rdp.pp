# Grant accounts RDP access on Windows
#
# This takes all accounts in a specified group, and adds them to the Remote
# Desktop Users group. For example, I might want to give all users RDP access:
#
# ~~~ puppet
# account::grant::rdp { 'Users': }
# ~~~
define account::grant::rdp (
  String[1] $to_group = $title,
) {
  account::grant::group { "Remote Desktop Users>${to_group}": }
}
