class octo_base::cloudwatch::logs (
    $log_files,
    $region
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
    $setup_script = "/opt/awslogs-agent-setup.py"
    $config_file = "/etc/awslogs.conf"

    # Combine passed in log files with standard log files for Ubuntu hosts.
    $core_log_files = [
        {
            "log_group_name" => "system.auth",
            "path" => "/var/log/auth.log",
            # Eg Mar 15 15:03:43
            "datetime_format" => "%b %d %H:%M:%S",
        },
        {
            "log_group_name" => "system.syslog",
            "path" => "/var/log/syslog",
            # Eg Mar 15 15:03:43
            "datetime_format" => "%b %d %H:%M:%S",
        },
        {
            "log_group_name" => "system.kern",
            "path" => "/var/log/kern.log",
            # Eg Mar 15 15:03:43
            "datetime_format" => "%b %d %H:%M:%S",
        },
        {
            "log_group_name" => "system.apt",
            "path" => "/var/log/apt/history.log",
            # Eg 2021-03-17 15:53:34
            "datetime_format" => "%Y-%m-%d %H:%M:%S"
        },
    ]
    $all_log_files = concat($core_log_files, $log_files)

    # Create the bootstrapping config file (the $aws_logs var is iterated over in the template)
    file { "AWS cloudwatch config":
        path => $config_file,
        content => template("octo_base/cloudwatch/awslogs.conf"),
        mode => "0600",
        notify => Exec["Install AWS cloudwatch agent"],
    }

    # Fetch the set-up script from AWS
    wget::fetch { "Download AWS cloudwatch script":
        source => "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py",
        destination => $setup_script,
        unless => "test -f $setup_script",
    }

    # Ensure we have Python 2.7
    package { "python":
      ensure => "installed"
    }

    # Install the agent using the bootstrap config file above (only works with Python 2.6-3.5)
    exec { "Install AWS cloudwatch agent":
        command => "/usr/bin/python $setup_script --region $region --non-interactive --configfile=$config_file",
        # Only run when the config file content changes.
        refreshonly => true,
        require => [
          Wget::Fetch["Download AWS cloudwatch script"],
          File["AWS cloudwatch config"],
          Package["python"]
        ]
    }
}

