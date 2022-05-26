class octo_base::cloudwatch::system {

    # Install system packages
    $system_packages = [ "lockfile-progs", "bc" ]
    package { $system_packages:
        ensure => "installed",
    }
}
