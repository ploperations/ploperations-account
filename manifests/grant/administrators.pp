# Grant accounts Administrators access on Windows
#
# This takes all accounts in a specified group, and adds them to the
# Administrators group. For example, I might want to give all the sysadmins
# administrative access:
#
# ~~~ puppet
# account::grant::administrators { 'sysadmin': }
# ~~~
define account::grant::administrators (
  String[1] $to_group = $title,
) {
  account::grant::group { "Administrators>${to_group}": }
}
