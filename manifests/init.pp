# @summary
#   This class installs the FTS3 server and configures it to run as a service.
#   It can also install the MySQL server and create the FTS3 database.
#   The class can be used to configure only the FTS3 server, only the MySQL server, or both.
# @example
#   class { 'fts':
#     fts_host           => 'fts3-server.example.org',
#     db_host            => 'fts3-db.example.org',
#     db_root_password   => 'roottestpassword',
#      fts_db_password   => 'ftstestpassword',
#     fts_db_user        => 'fts3',
#     fts_db_type        => 'mysql',
#     fts_server_alias   => 'fts3-server',
#     admin_list         => ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
#     fts_db_threads_num => 24,
#     configure_db       => true,
#     configure_fts      => true,
#     configure_firewall => true,
#     configure_lsc      => true,
#     build_database     => true,
#     vo_list            => ['alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 'escape', 'lhcb', 'ops', 'wlcg'],
#   }
# 
# @param fts_host
#   (required) The hostname of the FTS3 server.
#   Defaults to the value of $::fqdn.
#   The value of this parameter is used to set the FTS3 server hostname in the
#   MySQL database.
#
# @param db_host
#   (required) The hostname of the FTS3 database.
#   Defaults to the value of $::fqdn.
#   The value of this parameter is used to set the FTS3 database hostname in the FTS3 
#   configuration file.
#
# @param db_name
#   (required) The name of the FTS3 database.
#   Defaults to 'fts'.
#
# @param db_root_password
#   (required) The password of the MySQL root user.
#
# @param fts_db_user
#   (optional) The username of the FTS3 database.
#   Defaults to 'fts3'.
#
# @param fts_db_password
#   (optional) The password of the FTS3 database.
#   Defaults to 'ftstestpassword'.
#
# @param fts_db_type
#   (optional) The type of the FTS3 database.
#   Defaults to 'mysql'.
#
# @param fts_server_alias
#   (optional) The alias of the FTS3 server.
#   Defaults to 'fts3-server'.
#
# @param admin_list
#   (optional) List of DNs of the FTS3 administrators.
#   Defaults to ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri]
#
# @param fts_db_threads_num
#   (optional) The number of threads to use for the FTS3 database.
#   Defaults to 24.
#
# @param configure_fts
#   (optional) Whether to configure the FTS3 server.
#
# @param configure_db
#   (optional) Whether to configure the FTS3 database.
#   Defaults to true.
#
# @param configure_firewall
#   (optional) Whether to configure the firewall.
#   Defaults to true.
#
# @param configure_lsc
#   (optional) Whether to install and configure the servers as VOMS clients.
#   Defaults to true.
# 
# @param build_database
#   (optional) Whether to build the FTS3 database.
#
# @param vo_list
#   (optional) List of VOs to configure. Add the VOs to the list.
#   Possible values are 'alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 
#     'escape', 'lhcb', 'ops', 'wlcg'
#   Defaults to [None].
#
class fts (
  String  $fts_host           = 'fts3-server.infn.it',
  String  $db_host            = 'fts3-db.infn.it',
  String  $db_name            = 'fts',
  String  $db_root_password   = 'dbrootpassword',
  String  $fts_db_user        = 'fts3',
  String  $fts_db_password    = 'ftstestpassword',
  String  $fts_db_type        = 'mysql',
  String  $fts_server_alias   = 'fts3-server',
  Array   $admin_list         = ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
  Integer $fts_db_threads_num = 24,
  Boolean $configure_db       = true,
  Boolean $configure_fts      = true,
  Boolean $configure_firewall = true,
  Boolean $configure_lsc      = true,
  Boolean $build_database     = true,
  Array   $vo_list            = ['cycgno', 'datacloud'],
) {
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
      owner => 'root',
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
      ensure   => present,
      provider => yum,
      require  => [File['/etc/yum.repos.d/fts3-depend-el7.repo'], File['/etc/yum.repos.d/EGI-trustanchors.repo']],
      ;

    # CentOS SCLo SIG software
    # fts-rest-server requires rh-python36-mod_wsgi
    ['centos-release-scl','centos-release-scl-rh']:
      ;

    # Gfal2 and dependencies
    ['CGSI-gSOAP', 'davix', 'gfal2-all', 'srm-ifce']:
      ;

    # Certificate management
    ['fetch-crl', 'ca-policy-egi-core', 'voms-clients-java']:
      ;
    # utilities
    ['vim', 'net-tools',  'yum-cron']:
      ;
  }
  # Configure the VOMS VOs
  if $configure_lsc {
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
              }
            ]
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
              }
            ]
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
          warning("Unknown VO: ${vo}")
        }
      }
    }
  }

  if $configure_fts {
    # Install the FTS3 server
    class { 'fts::server':
      fts_user           => $fts_db_user,
      fts_db_type        => $fts_db_type,
      db_host            => $db_host,
      fts_db_username    => $fts_db_user,
      fts_db_password    => $fts_db_password,
      fts_db_threads_num => $fts_db_threads_num,
      fts_server_alias   => $fts_server_alias,
      configure_firewall => $configure_firewall,
    }
  }

  # Install the MySQL server and configure the FTS3 database
  if $configure_db {
    class { 'fts::database':
      db_password        => $db_root_password,
      db_name            => $db_name,
      fts_host           => $fts_host,
      fts_db_user        => $fts_db_user,
      admin_list         => $admin_list,
      configure_firewall => $configure_firewall,
      build_database     => $build_database,
    }
  }
}
