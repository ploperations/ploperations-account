# @summary Parameters needed by defined types in this module
#
# There's no need to instantiate this class; it does nothing. It's used for
# setting parameters in hiera that account::user and friends can access.
#
# @param common_shared_accounts
#   An array of shared accounts to which all users will have their keys added.
# @param cygwin
#   Whether or not to use Cygwin on Windows. This defaults to the value of
#   `cygwin::enable` in hiera, which is where you should set it. (It, in turn,
#   defaults to `false`.)
class account (
  Array[String[1]] $common_shared_accounts = [],
  Boolean          $cygwin                 = lookup('cygwin::enable', Boolean, undef, false),
) {
}
