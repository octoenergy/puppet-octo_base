class octo_base::cloudwatch::logs (
    $log_files,
    $region = "eu-west-1"
) {
    # Manifest to install the AWS logs agent
    # See http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/CWL_GettingStarted.html
    #
    # The $log_files arg should be a list of hashes, eg:
    #
    #   [
    #       {
    #           "log_group_name" => "nginx",
    #           "path" => "/var/log/nginx/access.log",
    #           "datetime_format" => "%d/%b/%Y:%H:%M:%S",
    #       },
    #   ]

    # Temporary files
    $setup_script = "/tmp/awslogs-agent-setup.py"
    $config_file = "/tmp/awslogs.conf"

    # Fetch the set-up script from AWS
    wget::fetch { "Download AWS cloudwatch script":
        source => "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py",
        destination => $setup_script,
        unless => "test -f /var/awslogs/bin/awslogs-nanny.sh",
    }

    # Create the bootstrapping config file (the $aws_logs var is iterated over in the template)
    file { "AWS cloudwatch config":
        path => $config_file,
        content => template("octo_base/cloudwatch/awslogs.conf"),
        mode => "0600",
        require => Wget::Fetch["Download AWS cloudwatch script"],
        notify => Exec["Install AWS cloudwatch agent"],
    }

    # Ensure we have Python 2.7
    package { "python":
      ensure => "installed"
    }

    # Install the agent using the bootstrap config file above (only works with Python 2.6-3.5)
    exec { "Install AWS cloudwatch agent":
        command => "/usr/bin/python $setup_script --region $region --non-interactive --configfile=$config_file",
        creates => "/var/awslogs/etc/awslogs.conf",
        require => [
          File["AWS cloudwatch config"],
          Package["python"]
        ]
    }
}

