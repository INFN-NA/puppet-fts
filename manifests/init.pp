# @summary
#   This class installs the FTS3 server and configures it to run as a service.
#   It can also install the MySQL server and create the FTS3 database.
#   The class can be used to configure only the FTS3 server, only the MySQL server, or both.
# @example
#   class { 'fts':
#     fts_host           => 'fts3-server.example.org',
#     db_host            => 'fts3-db.example.org',
#     db_name            => 'fts',
#     db_root_user       => 'root',
#     db_root_password   => 'roottestpassword',
#     fts_db_password    => 'ftstestpassword',
#     fts_db_user        => 'fts3',
#     fts_db_type        => 'mysql',
#     fts_server_alias   => 'fts3-server',
#     admin_list         => ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
#     fts_db_threads_num => 24,
#     configure_db       => true,
#     configure_fts      => true,
#     configure_firewall => true,
#     configure_selinux  => true,
#     build_mysql_server => true,
#     build_fts_tables   => true,
#     grant_privileges   => true,
#     configure_admins   => true,
#     configure_lsc      => true,
#     vo_list            => ['alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 'escape', 'lhcb', 'ops', 'wlcg'],
#   }
# 
# @param fts_host
#   (required) The hostname of the FTS3 server.
#   defaults to fts-server.infn.it
#   The value of this parameter is used to set the FTS3 
#   server hostname in the MySQL database.
#
# @param db_host
#   (required) The hostname of the FTS3 database.
#   Defaults to fts-db.infn.it
#   The value of this parameter is used to set the 
#   FTS database hostname in the FTS configuration file.
#
# @param db_name
#   (optional) the name of the fts database user. 
#   defaults to fts3. The user will be created if it does not exist.
# 
# @param db_root_user
#   (optional) The username of the MySQL root user.
#   defaults to 'root'. If the mysql server is not built, 
#   or grants to the root and fts users must not be given 
#   becouse the database alredy exists, this parameter is ignored.
#
# @param db_root_password
#   (optional) the root password for the mysql server. 
#   Defaults to roottestpassword. If the mysql server is not built,
#   or grants to the root and fts users must not be given 
#   becouse the database alredy exists, this parameter is ignored.
#
# @param fts_db_password
#   (optional) the password of the fts database user. 
#   defaults to ftstestpassword. Please change this parameter to a secure password.
#
# @param fts_db_type
#   (optional) The type of database backend to use.
#   defaults to mysql which is the only supported backend.
#
# @param fts_server_alias
#   (optional) The alias to use for the FTS server
#   defaults to fts3-server.
#
# @param admin_list
#   (required) the list of the admin users for the fts database. 
#   defaults to ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri]
#   In order for the fts server to work, at least one admin user must be configured. 
#   The admin user must be in the form of a DN.
#   Admins will be created if they do not exist only if the FTS database has been populated with tables
#   through the build_fts_tables parameter.
#
# @param fts_db_threads_num
# (optional) The number of threads to use for the FTS3 database.
# defaults to 24.
#
# @param configure_fts
#   (optional) Whether to configure the FTS3 server. 
#   defaults to true. If this parameter is set to True, the FTS3 server will be configured, i.e. the 
#   class fts::server will be included and used to install needed dependencies and configure the FTS3 service.
#   For further information about the parameters of the fts::server class, please refer to the documentation of the class.
#
# @param configure_db
#   (optional) Whether to configure the FTS3 MySQL database.
#   defaults to true. If this parameter is set to True, the FTS3 database will be configured, i.e. the
#   class fts::database will be included and used to install needed dependencies and configure the MySQL FTS3 database.
#   For further information about the parameters of the fts::database class, please refer to the documentation of the class.
#
# @param configure_firewall
#   (optional) Whether to configure the firewall.
#   defaults to true. If configure_fts is set to true, 
#   the firewallthe firewall module opens the following ports:
#   8446 for the REST API, 8449 for the web monitoring.
#   If configure_db is set to true, the firewall module opens the following ports:
#   3306 for the MySQL server. All remaining ports are closed.
#
# @param configure_admins
#   (required) Whether to configure the FTS3 administrators.
#   defaults to true. If set to true, the list of admins is taken from the admin_list parameter, 
#   and the admins are created if they do not exist.
#
# @param configure_lsc
#   (optional) Whether to install and configure the servers as VOMS clients.
#   defaults to true. If set to false, VOMS must be already configured on the server. LSC setup for at least 
#   one VO (and one admin for that VO) is required for the FTS3 server to work.
#
# @param configure_selinux
#   (optional) Whether to configure SELinux.
#   defaults to true. Selinux is set to enforcing on the FTS server, and to permissive on the MySQL server.
# 
# @param build_mysql_server
#   (optional) whether to build the mysql server or not. 
#   defaults to true. if the mysql server is not built, the script assumes that 
#   a mysql server is already running on the machine and that the root user and password are valid.
#
# @param vo_list
#   (optional) List of VOs to configure. Add the VOs to the list.
#   Possible values are 'alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 
#   'escape', 'lhcb', 'ops', 'wlcg'
#   defaults to [None].
#
# @param build_fts_tables
#   (optional) Whether to build the FTS tables or not.
#   defaults to true. The script in either case will create and/or check the presente of the 
#   fts database and the user. If the parameter is set to true, the fts database will be populated
#   with the tables needed for the fts server to work. If the parameter is set to false, the script will
#   only check the presence of the fts database and the user. The tables can be build both from the fts server through an 
#   automatic SQL query on the MySQL database (in case the MySQL is CentOS 7),
#   or directly on the mySQL server by combining this flag with configure_db = true. 
#  
# @param grant_privileges
#   (optional) Whether to grant privileges to the FTS and root user on the database. 
#   defaults to true. In order to grant privileges, the MySQL database, the FTS Tables, 
#   and user must already exist and the MySQL root user and password must be provided. 
#   Correct privileges to the fts database for, at least, the fts user are neeed for the fts server 
#   to work. So, if the parameter is set to false, make sure to grant privilegs manually. 
#
class fts (
  String  $fts_host           = 'fts3-server.infn.it',
  String  $db_host            = 'fts3-db.infn.it',
  String  $db_name            = 'fts',
  String  $db_root_user       = 'root',
  String  $db_root_password   = 'dbrootpassword',
  String  $fts_db_user        = 'fts3',
  String  $fts_db_password    = 'ftstestpassword',
  String  $fts_db_type        = 'mysql',
  String  $fts_server_alias   = 'fts3-server',
  String  $fts_broker_host    = 'fts-broker.infn.it',
  String  $fts_broker_user    = 'ftsuser',
  Array   $admin_list         = ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
  Integer $fts_db_threads_num = 24,
  Boolean $configure_db       = true,
  Boolean $configure_fts      = true,
  Boolean $configure_firewall = true,
  Boolean $configure_selinux  = true,
  Boolean $configure_lsc      = true,
  Boolean $build_mysql_server = true,
  Boolean $build_fts_tables   = true,
  Boolean $grant_privileges   = true,
  Boolean $configure_admins   = true,
  Array   $vo_list            = ['cycgno', 'datacloud'],
) {
  case $facts['os']['name'] {
    'AlmaLinux': {
      case $facts['os']['release']['major'] {
        '9': {
          # Ensure DNF config-manager is installed
          package { 'dnf-plugins-core':
            ensure   => present,
            provider => dnf,
            before   => Package['epel-release'],
          }
          # Enable CRB if not already enabled
          exec { 'enable-crb':
            command => 'dnf config-manager --set-enabled crb',
            path    => '/usr/bin',
            unless  => 'grep crb <(dnf repolist) 2>/dev/null',
            require => Package['dnf-plugins-core'],
            before  => Package['epel-release'],
          }
          # EPEL
          package { 'epel-release':
            ensure => present,
          }
          # CERN FTS Repositories
          file {
            default:
              group => 'root',
              ;

            # DMC EL9
            '/etc/yum.repos.d/dmc-el9.repo':
              source => 'https://dmc-repo.web.cern.ch/dmc-repo/dmc-el9.repo',
              ;
            # EGI Trust Anchors
            '/etc/yum.repos.d/egi-trustanchors.repo':
              source => 'https://repository.egi.eu/sw/production/cas/1/current/repo-files/egi-trustanchors.repo',
              ;
            # FTS Production EL9
            '/etc/yum.repos.d/fts3-el9.repo':
              source => 'https://fts-repo.web.cern.ch/fts-repo/fts3-el9.repo',
              ;

            # FTS Depend EL9
            '/etc/yum.repos.d/fts3-depend.repo':
              source => 'https://fts-repo.web.cern.ch/fts-repo/fts3-depend.repo',
              ;
          }
          package {
            default:
              ensure          => present,
              provider        => yum,
              require         => [File['/etc/yum.repos.d/fts3-el9.repo'], File['/etc/yum.repos.d/dmc-el9.repo']],
              install_options => ['--enablerepo=dmc-el9']
              ;
            # Gfal2 and dependencies
            ['CGSI-gSOAP', 'davix', 'srm-ifce']:
              ;
          }
          package {
            default:
              ensure   => present,
              provider => dnf,
              require  => File['/etc/yum.repos.d/egi-trustanchors.repo'],
              ;
            ['fetch-crl', 'ca-policy-egi-core', 'ca-certificates']:
              ;
          }
        }
        default: {
          # Actions to take for any OS release not explicitly mentioned
          notify { 'This OS release is not specifically handled': } # Example notification
        }
      }
    }
    'CentOS': {
      case $facts['os']['release']['major'] {
        '7': {
          notify { 'Configuring Repositories and Dependencies': }
          # Install the EPEL repository
          package {
            default:
              ensure   => present,
              provider => yum,
              ;
            'epel-release':
              ;
          }
          # Install the FTS3 repository and dependencies plus some usefull packages
          file {
            default:
              group => 'root',
              ;

            # DMC EL7
            '/etc/yum.repos.d/dmc-el7.repo':
              source => 'https://dmc-repo.web.cern.ch/dmc-repo/dmc-el7.repo',
              ;

            # FTS Production EL7
            '/etc/yum.repos.d/fts3-el7.repo':
              source => 'https://fts-repo.web.cern.ch/fts-repo/fts3-el7.repo',
              ;

            # FTS Depend EL7
            '/etc/yum.repos.d/fts3-depend-el7.repo':
              source => 'https://fts-repo.web.cern.ch/fts-repo/fts3-depend-el7.repo',
              ;
          }
          # EGI Trust Anchor repository
          file { '/etc/yum.repos.d/EGI-trustanchors.repo':
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/fts/EGI-trustanchors.repo',
          }
          include yum
          package {
            default:
              ensure          => present,
              provider        => yum,
              require         => [File['/etc/yum.repos.d/fts3-el7.repo'], File['/etc/yum.repos.d/dmc-el7.repo']],
              install_options => ['--enablerepo=dmc-el7']
              ;
            # Gfal2 and dependencies
            ['CGSI-gSOAP', 'davix', 'gfal2-all', 'srm-ifce']:
              ;
          }

          package {
            default:
              ensure   => present,
              provider => yum,
              require  => [File['/etc/yum.repos.d/fts3-depend-el7.repo'], File['/etc/yum.repos.d/EGI-trustanchors.repo']],
              ;

            # CentOS SCLo SIG software
            # fts-rest-server requires rh-python36-mod_wsgi
            ['centos-release-scl','centos-release-scl-rh']:
              ;
            # Certificate management
            ['fetch-crl', 'ca-policy-egi-core', 'voms-clients-java']:
              ;
            # utilities
            ['vim', 'net-tools',  'yum-cron']:
              ;
          }
        }
        default: {
          notify { "Unsupported Release: ${facts['os']['release']['major']}, skipping FTS Repositories and Dependencies": }
        }
      }
    }
    default: {
      notify { "Unsupported OS: ${facts['os']['name']}, skipping FTS Repositories and Dependencies": }
    }
  }
  # Configure the VOMS VOs
  if $configure_lsc {
    notify { "Configuring VOMS VOs: ${vo_list}": }
    case $facts['os']['name'] {
      'AlmaLinux': {
        case $facts['os']['release']['major'] {
          '9': {
            $vo_list.each |$vo| {
              case $vo {
                'alice': {
                  include voms::alice
                }
                'atlas': {
                  include voms::atlas
                }
                'cms': {
                  include voms::cms
                }
                'cygno': {
                  voms::vo { 'cygno.vo':
                    servers => [
                      {
                        server => 'voms-cygno.cloud.cnaf.infn.it',
                        port   => 15006,
                        dn     => '/DC=org/DC=terena/DC=tcs/C=IT/ST=Roma/O=Istituto Nazionale di Fisica Nucleare/CN=voms-cygno.cloud.cnaf.infn.it',
                        ca_dn  => '/C=NL/O=GEANT Vereniging/CN=GEANT eScience SSL CA 4',
                      },
                    ],
                  }
                }
                'datacloud': {
                  voms::vo { 'datacloud.vo':
                    servers => [
                      {
                        server => 'iam-aa.wp6.cloud.infn.it',
                        port   => 15000,
                        dn     => '/DC=org/DC=terena/DC=tcs/C=IT/ST=Roma/O=Istituto Nazionale di Fisica Nucleare/CN=iam-aa.wp6.cloud.infn.it',
                        ca_dn  => '/C=NL/O=GEANT Vereniging/CN=GEANT eScience SSL CA 4',
                      },
                    ],
                  }
                }
                'dteam': {
                  include voms::dteam
                }
                'escape': {
                  include voms::escape
                }
                'lhcb': {
                  include voms::lhcb
                }
                'ops': {
                  include voms::ops
                }
                'wlcg': {
                  include voms::wlcg
                }
                default: {
                  notify { "Unknown VO: ${vo}": }
                }
              }
            }
          }
          default: {
            notify { "Unsupported Release: ${facts['os']['release']['major']}, skipping LSC Configuration": }
          }
        }
      }
      default: {
        notify { "Unsupported OS: ${facts['os']['name']}, skipping LSC Configuration": }
      }
    }
  }
  if $configure_fts {
    notify { 'Configuring FTS3 Server': }
    case $facts['os']['name'] {
      'AlmaLinux': {
        case $facts['os']['release']['major'] {
          '9': {
            # Install the FTS3 server
            class { 'fts::server':
              fts_user           => $fts_db_user,
              fts_db_type        => $fts_db_type,
              db_host            => $db_host,
              fts_db_name        => $db_name,
              fts_db_password    => $fts_db_password,
              fts_db_threads_num => $fts_db_threads_num,
              fts_server_alias   => $fts_server_alias,
              fts_broker_host    => $fts_broker_host,
              fts_broker_user    => $fts_broker_user,
              configure_firewall => $configure_firewall,
              configure_selinux  => $configure_selinux,
              build_fts_tables   => $build_fts_tables,
            }
          }
          default: {
            notify { "Unsupported Release: ${facts['os']['release']['major']}, skipping FTS Configuration": }
          }
        }
      }
      default: {
        notify { "Unsupported OS: ${facts['os']['name']}, skipping FTS Configuration": }
      }
    }
  }
  # Install the MySQL server and configure the FTS3 database
  if $configure_db {
    notify { 'Configuring Database': }
    class { 'fts::database':
      db_root_user       => $db_root_user,
      db_root_password   => $db_root_password,
      db_name            => $db_name,
      fts_host           => $fts_host,
      fts_db_user        => $fts_db_user,
      fts_db_password    => $fts_db_password,
      admin_list         => $admin_list,
      configure_firewall => $configure_firewall,
      configure_selinux  => $configure_selinux,
      build_mysql_server => $build_mysql_server,
      build_fts_tables   => $build_fts_tables,
      grant_privileges   => $grant_privileges,
      configure_admins   => $configure_admins,
    }
  }
}
