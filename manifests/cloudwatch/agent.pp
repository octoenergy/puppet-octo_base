class octo_base::cloudwatch::agent (
  $log_files,
  $instance_name
) {
  $install_download_link = 'https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb'
  $signature_download_link = 'https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb.sig'
  $public_key_download_link = 'https://s3.amazonaws.com/amazoncloudwatch-agent/assets/amazon-cloudwatch-agent.gpg'

  $package = '/opt/amazon-cloudwatch-agent.deb'
  $signature = '/tmp/amazon-cloudwatch-agent.deb.sig'
  $public_key = '/tmp/amazon-cloudwatch-agent.gpg'

  # Combine passed in log files with standard log files for Ubuntu hosts.
  $core_log_files = [
    {
      'log_group_name' => 'system.auth',
      'path' => '/var/log/auth.log',
      # Eg Mar 15 15:03:43
      'datetime_format' => '%b %d %H:%M:%S',
    },
    {
      'log_group_name' => 'system.syslog',
      'path' => '/var/log/syslog',
      # Eg Mar 15 15:03:43
      'datetime_format' => '%b %d %H:%M:%S',
    },
    {
      'log_group_name' => 'system.kern',
      'path' => '/var/log/kern.log',
      # Eg Mar 15 15:03:43
      'datetime_format' => '%b %d %H:%M:%S',
    },
    {
      'log_group_name' => 'system.dpkg',
      'path' => '/var/log/dpkg.log',
      # Eg 2021-03-17 15:53:34
      'datetime_format' => '%Y-%m-%d %H:%M:%S'
    },
  ]
  $all_log_files = concat($core_log_files, $log_files)
  $number_of_log_files = length($all_log_files)
  $instance = $instance_name

  $config_file = '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json'

  # cwagent user and group
  # ----------------------

  # Create a group and user for cwagent
  group { 'cwagent':
    ensure => present,
  }
  user { 'cwagent':
    ensure => present,
    groups => ['cwagent', 'adm', 'www-data'],
  }

  # Create the directory structure for the CloudWatch Agent config file
  file { ['/opt/aws',
      '/opt/aws/amazon-cloudwatch-agent',
    '/opt/aws/amazon-cloudwatch-agent/etc']:
      ensure  => 'directory',
      recurse => true,
      owner   => 'cwagent',
      group   => 'cwagent',
      mode    => '0755',
  }

  # Create the base config file for the CloudWatch Agent
  file { 'AWS CloudWatch Agent config':
    path    => $config_file,
    content => template('octo_base/cloudwatch/amazon-cloudwatch-agent.json.erb'),
    mode    => '0644',
    notify  => Package['amazon-cloudwatch-agent'],
  }

  # Fetch the installation package from AWS
  file { 'Download AWS CloudWatch Agent package':
    source  => $install_download_link,
    path    => $package,
    replace => true,
  }

  # Fetch the AWS CloudWatch Agent public key
  file { 'Download the AWS CloudWatch Agent public key':
    source  => $public_key_download_link,
    path    => $public_key,
    replace => true,
  }

  # Fetch the AWS CloudWatch Agent signature
  file { 'Download the AWS CloudWatch Agent package signature':
    source  => $signature_download_link,
    path    => $signature,
    replace => true,
  }

  # Import the AWS CloudWatch Agent public key
  exec { 'Import the public GPG key for signature verification':
    command => 'gpg --import $public_key',
    onlyif  => 'test $(gpg --list-keys --keyid-format LONG | grep "Amazon CloudWatch Agent" | wc -l) = 1',
    require => [
      File['Download the AWS CloudWatch Agent public key']
    ],
  }

  # Verify the installation package signature
  exec { 'Verify the installation package signature':
    command => 'gpg --verify $signature $package',
    onlyif  => 'test $(dpkg -s amazon-cloudwatch-agent) = 1',
    require => [
      File['Download the AWS CloudWatch Agent package signature'],
      File['Download AWS CloudWatch Agent package'],
      Exec['Import the public GPG key for signature verification']
    ],
  }

  # Install the AWS CloudWatch Agent package
  package { 'amazon-cloudwatch-agent':
    ensure   => installed,
    name     => 'amazon-cloudwatch-agent',
    source   => $package,
    provider => 'dpkg',
    require  => [
      File['Download AWS CloudWatch Agent package'],
      Exec['Verify the installation package signature'],
      File['AWS CloudWatch Agent config']
    ],
  }

  # Enable the amazon-cloudwatch-agent service is running
  service { 'amazon-cloudwatch-agent':
    ensure   => running,
    enable   => true,
    provider => 'systemd',
    require  => Package['amazon-cloudwatch-agent'],
  }

  # Ensure the awslogs service is now disabled
  service { 'awslogs':
    enable   => false,
    provider => 'systemd',
  }
}
