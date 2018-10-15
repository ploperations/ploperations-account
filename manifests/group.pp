define account::group (
  $ensure    = present,
  $members   = [],
  $gid       = undef,
  $exclusive = true,
) {

  $members.each |$m| {
    Account::User <| title == $m |> {
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
