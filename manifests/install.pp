# osquery::install - installation class
class osquery::install {

  # Installation methods vary for OS type and family 
  case $::kernel {
    'Linux': {
      # repo install [optional]
      if $::osquery::repo_install {
        case $::osfamily {
          'Debian': {
            # add the osquery APT repo
            apt::source { 'osquery_repo':
              location     => $::osquery::repo_url,
              architecture => $::architecture,
              release      => 'deb',
              repos        => 'main',
              key          => {
                'id'     => $::osquery::repo_key_id,
                'server' => $::osquery::repo_key_server,
              },
            }

            # install the osquery package after an apt-get update is run
            package { $::osquery::package_name:
              ensure  => $::osquery::package_ver,
            }

            package { 'apt-transport-https':
              ensure => present,
              notify => Class['apt::update'],
            }

            # explicitly set ordering for installation of package, repo and package
            Package['apt-transport-https'] -> Apt::Source['osquery_repo'] -> Package[$::osquery::package_name]
          }
          'RedHat': {
            # add the osquery yum repo package
            yumrepo { 'osquery-s3-rpm-repo' :
              ensure   => 'present',
              descr    => 'osquery RPM repository - $basearch',
              baseurl  => 'https://s3.amazonaws.com/osquery-packages/rpm/$basearch/',
              gpgkey   => 'https://pkg.osquery.io/rpm/GPG',
              enabled  => '1',
              gpgcheck => '1',
              target   => '/etc/yum.repos.d/osquery-s3-rpm.repo',
            }
            package { $::osquery::repo_name:
              ensure   => absent,
            }
            # install the osquery package, requiring the yum repo package
            package { $::osquery::package_name:
              ensure  => $::osquery::package_ver,
              require => Yumrepo['osquery-s3-rpm-repo'],
            }
            # explicitly set ordering for installation of repo and package
            Yumrepo['osquery-s3-rpm-repo'] -> Package[$::osquery::package_name]
          }
          default: {
            fail("${::osfamily} not supported")
          }
        } # end case $::osfamily
      } # end if $::osquery::repo_install
      else {
        # if not installing the repo, install the osquery package from existing repos
        package { $::osquery::package_name:
          ensure  => $::osquery::package_ver,
        }
      }
    }
    'windows': {
      package{ 'osquery':
        ensure          => present,
        provider        => chocolatey,
        install_options => ['-params','"','/InstallService','"'],
      }
    }
    default: {
      fail("${::kernel} not supported")
    }
  } # end case $::kernel
}
