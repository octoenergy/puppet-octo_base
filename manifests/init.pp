class octo_base (
  $awscli_version = '1.25.46',
  $aws_inspector = true,
) {
  # Validate params
  if !$awscli_version {
    fail('A valid AWSCLI version must be set')
  }

  # Update repos
  exec { 'update apt repositories':
    command   => 'time -p /usr/bin/apt-get update --fix-missing',
    # Use a longer timeout as the default of 300 seconds fails more often than
    # we would like.
    timeout   => 600,
    tries     => 3,
    logoutput => on_failure,
  }

  if $facts['os']['distro']['release']['full'] == '18.04' {
    # Remove unnecessary packages for Ubuntu 18:04 (see https://peteris.rocks/blog/can-you-kill-it/)
    $unnecessary_packages = [
      'snapd',
      'lvm2',
      'lxcfs',
      'accountsservice',
      'at',
      'policykit-1',
      'telnet',
    ]
  } else {
    $unnecessary_packages = [
      'lvm2',
      'lxcfs',
      'accountsservice',
      'at',
      'policykit-1',
      'telnet',
    ]
  } 

  package { $unnecessary_packages:
    ensure  => 'purged',
    require => Exec['update apt repositories'],
  }

  # Apply security patches for installed packages
  exec { 'upgrade installed packages':
    command   => 'time -p /usr/bin/apt-get -y dist-upgrade --fix-missing --fix-broken --autoremove',
    # Use a longer timeout as the default of 300 seconds fails more often than
    # we would like.
    timeout   => 600,
    tries     => 3,
    logoutput => on_failure,
    require   => Package[$unnecessary_packages],
  }

  # All servers should have NTP running
  class { 'ntp':
    require => Exec['update apt repositories'],
  }

  # Install AWSCLI.
  #
  # This is needed by Cloudwatch monitoring scripts and also for
  # initialisation code that runs in EC2 userdata. It's simpler to just have
  # it available on all EC2 machines.
  package { 'python3-pip':
    ensure  => installed,
    require => Exec['update apt repositories'],
  }
  exec { 'install awscli':
    command => "pip3 install 'awscli==${awscli_version}'",
    path    => ['/bin/', '/sbin/', '/usr/bin/', '/usr/bin/local/'],
    user    => 'root',
    group   => 'root',
    unless  => 'pip3 freeze | grep awscli',
    require => Package['python3-pip'],
  }

  # JQ is also used by monitoring scripts to extract data from JSON
  package { 'jq':
    ensure  => installed,
    require => Exec['upgrade installed packages'],
  }

  # Default EC2 monitoring - this requires an IAM role that allows putting new metrics
  class { 'octo_base::cloudwatch::system':
    require => Exec['install awscli'],
  }

  class { 'octo_base::cis_hardening::system':
    require => Exec['update apt repositories'],
  }

  # Don't install AWS specific features when running in Vagrant
  if String($facts['vagrant']) != '1' {
    if $aws_inspector == true {
      class { 'octo_base::inspector::system':
        require => Exec['update apt repositories'],
      }
    }

    include 'octo_base::amazon_ssm_agent'
  }

  # lint:ignore:140chars
  # Cron to lower (remove) the possibility of OOM Killer killing the SSM processes, which locks us out in high memory events
  cron { 'ssm_oom':
    command => 'echo \'-1000\' > /proc/$(pidof ssm-agent-worker)/oom_score_adj; echo \'-1000\' > /proc/$(pidof amazon-ssm-agent)/oom_score_adj; echo \'-1000\' > /proc/$(pidof ssm-session-worker)/oom_score_adj',
    user    => 'root',
    special => 'reboot',
  }
}
# lint:endignore
