# create a local group and define its members
define account::group (
  $ensure    = present,
  $members   = [],
  $gid       = undef,
  $exclusive = true,
) {

  $members.each |$member| {
    Account::User <| title == $member |> {
      ensure => $ensure
    }
  }

  group { $name:
    ensure  => $ensure,
    gid     => $gid,
    members => $members,
    tag     => 'posixgroup',
    require => Account::User[$members],
  }

  groupmembership { $name:
    exclusive => $exclusive,
    members   => $members,
  }
}
