# jdk7::install7_aix
#
# On Linux low entropy can cause certain operations to be very slow.
# Encryption operations need entropy to ensure randomness. Entropy is
# generated by the OS when you use the keyboard, the mouse or the disk.
#
# If an encryption operation is missing entropy it will wait until
# enough is generated.
#
# three options
#  use rngd service (this class)
#  set java.security in JDK ( jre/lib/security )
#  set -Djava.security.egd=file:/dev/./urandom param
#
define jdk7::install7_aix (
  $version                   = '71',
  $fullVersion               = 'Java71',
  $javaHomes                 = '/usr/java',
  $x64                       = true,
  $downloadDir               = '/install',
  $sourcePath                = 'puppet:///modules/jdk7/',
) {

  if ( $x64 == true ) {
    $type = '64'
  } else {
    $type = 'i586'
  }

  case $::kernel {
    'Linux': {
      fail("Unrecognized operating system ${::kernel}, please use jdk7::install7 on this host")
    }
    'AIX': {
      $install_version   = 'AIX'
      $install_extension = '.tar'
      $path              = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'
      $user              = 'root'
      $group             = 'system'
    }
    default: {
      fail("Unrecognized operating system ${::kernel}, please use it on a Linux host")
    }
  }

  $sdk_file = "${fullVersion}_${type}.sdk${install_extension}"
  $jre_file = "${fullVersion}_${type}.jre${install_extension}"

  exec { "create ${$downloadDir} directory":
    command => "mkdir -p ${$downloadDir}",
    unless  => "test -d ${$downloadDir}",
    path    => $path,
    user    => $user,
  }

  # check install folder
  if !defined(File[$downloadDir]) {
    file { $downloadDir:
      ensure  => directory,
      require => Exec["create ${$downloadDir} directory"],
      replace => false,
      owner   => $user,
      group   => $group,
      mode    => '0777',
    }
  }

  # download jdk to client
  file { [ $sdk_file, $jre_file ]:
    ensure  => file,
    path    => "${downloadDir}/${title}",
    source  => "${sourcePath}/${title}",
    require => File[$downloadDir],
    replace => false,
    owner   => $user,
    group   => $group,
    mode    => '0777',
  }

  # install on client
  exec { "installp jre deps ${fullVersion} ${version}":
    command => "installp_r -a -Y -R ${javaHomes} -d ${downloadDir}/${jre_file} ${fullVersion}_${type}.jre",
    unless  => "test -d ${javaHomes}",
    path    => $path,
    user    => $user,
    group   => $group,
    require => File["${downloadDir}/${jre_file}"],
  }

  exec { "installp sdk deps ${fullVersion} ${version}":
    command => "installp_r -a -Y -R ${javaHomes} -d ${downloadDir}/${jre_file} ${fullVersion}_${type}.sdk",
    unless  => "test -d ${javaHomes}",
    path    => $path,
    user    => $user,
    group   => $group,
    require => [ File["${downloadDir}/${sdk_file}"], Exec["installp jre deps ${fullVersion} ${version}"], ],
  }
}
