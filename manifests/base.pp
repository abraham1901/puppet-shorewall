class shorewall::base {

    package { 'shorewall':
        ensure => $shorewall::ensure_version,
    }

    # This file has to be managed in place, so shorewall can find it
    file {
      '/etc/shorewall/shorewall.conf':
        require => Package[shorewall],
        notify => Service[shorewall],
        owner => root, group => 0, mode => 0644;
      '/etc/shorewall/puppet':
        ensure => directory,
        require => Package[shorewall],
        owner => root, group => 0, mode => 0644;
    }

    augeas { 'shorewall_module_config_path':
      changes => 'set /files/etc/shorewall/shorewall.conf/CONFIG_PATH \'"/etc/shorewall/puppet:/etc/shorewall:/usr/share/shorewall"\'',
      lens    => 'Shellvars.lns',
      incl    => '/etc/shorewall/shorewall.conf',
      notify  => Service[shorewall];
    }

    service{shorewall:
        ensure  => running,
        enable  => true,
        hasstatus => true,
        hasrestart => true,
        require => Package[shorewall],
    }
}
