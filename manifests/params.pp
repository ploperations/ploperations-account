# Class: account::params
#
# This class contains the parameters for the account module
#
class account::params {

  case $facts['os']['name'] {
    'ubuntu': {
      $mkpasswd = 'mkpasswd'
    }
    'centos': {
      $mkpasswd = 'expect'
    }
    default: {
      $mkpasswd = 'mkpasswd'
    }
  }
}
