class octo_base::inspector::system {

  # Install system packages

  # Ensure the appropriate version of libssl is installed.
  if $operatingsystemrelease == '18.04' {
    $system_packages = [
      "gnupg",
      "libcurl4",
      "libgcc1",
      "libc6",
      "libstdc++6",
      "libpcap0.8",
      "libssl1.0.0",
    ]
  } elsif $operatingsystemrelease == '20.04' {
    $system_packages = [
      "gnupg",
      "libcurl4",
      "libgcc1",
      "libc6",
      "libstdc++6",
      "libpcap0.8",
      "libssl1.1",
    ]
  } elsif $operatingsystemrelease == '22.04' {
    $system_packages = [
      "gnupg",
      "libcurl4",
      "libgcc1",
      "libc6",
      "libstdc++6",
      "libpcap0.8",
      "libssl3",
    ]
  }

  package { $system_packages:
    ensure => "installed",
  }

  $base = "/tmp/"

  file { "AWS inspector gpg key":
    path   => "$base/inspector.key",
    source => "puppet:///modules/octo_base/inspector/inspector.key",
  }

  file { "AWS inspector install script":
    path   => "$base/install",
    source => "https://inspector-agent.amazonaws.com/linux/latest/install",
    mode   => "u+x",
  }

  file { "AWS inspector gpg signature":
    path   => "$base/install.sig",
    source => "https://inspector-agent.amazonaws.com/linux/latest/install.sig",
  }

  exec { "Add inspector GPG key to keychain":
    cwd       => $base,
    command   => "/usr/bin/gpg --import inspector.key",
    subscribe => File["AWS inspector gpg key"],
    require   => Package["gnupg"],
  }

  exec { "Check AWS Inspector install script integrity":
    cwd       => $base,
    command   => "/usr/bin/gpg --verify ./install.sig",
    subscribe => [
      Exec["Add inspector GPG key to keychain"],
      File["AWS inspector gpg signature"],
    ],
  }

  exec { "Install AWS Inspector":
    cwd       => $base,
    command   => "./install",
    subscribe => [
      Exec["Check AWS Inspector install script integrity"],
      File["AWS inspector install script"],
    ],
  }
}
