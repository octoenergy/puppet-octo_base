
class octo_base::amazon_ssm_agent {

    file {'Download SSM agent':
      path => '/tmp/amazon-ssm-agent.deb',
      # Note that even though the following URL references 'ec2-downloads-windows', this is the correct (global) URL for Linux operating systems.
      source  => 'https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb',
    }

    package { 'amazon-ssm-agent':
      ensure   => latest,
      provider => 'dpkg',
      source   => '/tmp/amazon-ssm-agent.deb',
      require => File['Download SSM agent'],
    }

    file {'/tmp/amazon-ssm-agent.deb':
      ensure  => absent,
      require => Package['amazon-ssm-agent'],
    }

    service { 'amazon-ssm-agent':
      ensure   => running,
      enable   => true,
      provider => 'systemd',
      require => File['/tmp/amazon-ssm-agent.deb']
    }
}

