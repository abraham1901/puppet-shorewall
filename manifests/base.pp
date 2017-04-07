# base things for shorewall
class shorewall::base {

  package { 'shorewall':
    ensure => $shorewall::ensure_version,
  }

  # This file has to be managed in place, so shorewall can find it
  file {
    '/etc/shorewall/shorewall.conf':
      require => Package['shorewall'],
      notify  => Exec['shorewall_check'],
      owner   => 'root',
      group   => 'root',
      mode    => '0644';
    '/etc/shorewall/puppet':
      ensure  => directory,
      require => Package['shorewall'],
      owner   => 'root',
      group   => 'root',
      mode    => '0644';
  }
  if $shorewall::with_shorewall6 {
    package{'shorewall6':
      ensure => 'installed'
    }
    file {
      '/etc/shorewall6/shorewall6.conf':
        require => Package['shorewall6'],
        notify  => Exec['shorewall6_check'],
        owner   => 'root',
        group   => 'root',
        mode    => '0644';
      '/etc/shorewall6/puppet':
        ensure  => directory,
        require => Package['shorewall6'],
        owner   => 'root',
        group   => 'root',
        mode    => '0644';
    }
  }

  if str2bool($shorewall::startup) {
    $startup_str = 'Yes'
  } else {
    $startup_str = 'No'
  }
  if $shorewall::conf_source {
    File['/etc/shorewall/shorewall.conf']{
      source => $shorewall::conf_source,
    }
  } else {
    shorewall::config_setting{
      'CONFIG_PATH':
        value => "\"\${CONFDIR}/shorewall/puppet:\${CONFDIR}/shorewall:\${SHAREDIR}/shorewall\"";
      'STARTUP_ENABLED':
        value => $startup_str;
    }
    $cfs =  keys($shorewall::merged_settings)
    shorewall::config_settings{
      $cfs:
        settings => $shorewall::merged_settings;
    }
  }
  exec{'shorewall_check':
    command     => 'shorewall check',
    refreshonly => true,
    notify      => Service['shorewall'],
  }
  service{'shorewall':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['shorewall'],
  }

  if $shorewall::with_shorewall6 {
    shorewall::config6_setting{
      'CONFIG_PATH':
        value => "\"\${CONFDIR}/shorewall6/puppet:\${CONFDIR}/shorewall6:/usr/share/shorewall6:\${SHAREDIR}/shorewall\"";
      'STARTUP_ENABLED':
        value => $startup_str;
    }
    $cfs6 =  keys($shorewall::settings6)
    shorewall::config6_settings{
      $cfs6:
        settings => $shorewall::settings6;
    }

    exec{'shorewall6_check':
      command     => 'shorewall6 check',
      refreshonly => true,
      notify      => Service['shorewall6'],
    }
    service{'shorewall6':
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      require    => Package['shorewall6'],
    }
  }

  file{'/etc/cron.daily/shorewall_check':}
  if $shorewall::daily_check {
    if $shorewall::with_shorewall6 {
      $shorewall6_check_str = ' && shorewall6 check'
    } else {
      $shorewall6_check_str = ''
    }
    File['/etc/cron.daily/shorewall_check']{
      content => "#!/bin/bash

output=\$(shorewall check${shorewall6_check_str} 2>&1)
if [ \$? -gt 0 ]; then
  echo 'Error while checking firewall!'
  echo \$output
  exit 1
fi
exit 0
",
      owner   => root,
      group   => 0,
      mode    => '0700',
      require => Service['shorewall'],
    }
    if $shorewall::with_shorewall6 {
      Service['shorewall6'] -> File['/etc/cron.daily/shorewall_check']
    }
  } else {
    File['/etc/cron.daily/shorewall_check']{
      ensure => absent,
    }
  }
}
