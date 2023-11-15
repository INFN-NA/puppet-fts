# @summary: this class can create and configures the mysql fts database. Depending on the parameter choices,
#   it can create an mysql server, create and configure the fts
#   database and the user, populate it with tables, add admins,  
#   and configure the firewall and selinux.
#
# @example Configure the fts database
#   class { 'fts::database':
#     db_root => 'root',
#     db_root_password => 'ftstestpassword',
#     db_name     => 'fts',
#     fts_host    => 'fts-server.infn.it',
#     fts_db_user => 'fts3',
#     fts_db_password => 'ftstestpassword',
#     admin_list  => ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri, 
#                       '/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Massimo Sgaravatto sgaravat@infn.it'],
#     configure_firewall => true,
#     configure_selinux  => true,
#     build_mysql_server => true,
#     build_fts_tables   => true,
#     grant_privileges   => true,
#   }
#
# @param db_root_user
#   (optional) the root user for the mysql server,
#   defaults to root. If the mysql server is not built, 
#   or grants to the root and fts users must not be given 
#   becouse the database alredy exists, this parameter is ignored.
#
# @param db_root_password
#   (optional) the root password for the mysql server. 
#   Defaults to roottestpassword. If the mysql server is not built,
#   or grants to the root and fts users must not be given 
#   becouse the database alredy exists, this parameter is ignored.
#
# @param db_name
#   (required) the name of the fts database. 
#   defaults to fts. The database will be created if it does not exist.
#
# @param fts_host
#   (required) the hostname of the fts server. This can be the FQDN or 
#   the IP address of the machine hosting the mysql db. 
#
# @param fts_db_user
#   (required) The user that will run the FTS server.
#   defaults to fts3.
#
# @param fts_db_password
#   (optional) the password of the fts database user. 
#   defaults to ftstestpassword. Please change this parameter to a secure password.
#
# @param admin_list
#   (required) the list of the admin users for the fts database. In order for the fts server to work,
#   at least one admin user must be configured. The admin user must be in the form of a DN.
#   Admins will be created if they do not exist only if the FTS database has been populated with tables
#   through the build_fts_tables parameter.
#
# @param configure_firewall
#   (optional) whether to configure the firewall or not. 
#   defaults to true. The firewall will be configured to allow access only to the mysql server.
#
# @param configure_selinux
#   (optional) whether to configure selinux or not.
#   defaults to true. Selinux will be configured to permissive mode.
#
# @param build_mysql_server
#   (optional) whether to build the mysql server or not. 
#   defaults to true. if the mysql server is not built, the script assumes that 
#   a mysql server is already running on the machine and that the root user and password are valid.
#
# @param build_fts_tables
#   (optional) Whether to build the FTS tables or not. d
#   defaults to true. The script in either case will create and/or check the presente of the 
#   fts database and the user. If the parameter is set to true, the fts database will be populated
#   with the tables needed for the fts server to work. If the parameter is set to false, the script will
#   only check the presence of the fts database and the user.
#  
# @param grant_privileges
#   (optional) Whether to grant privileges to the FTS and root user on the database. 
#   defaults to true. In order to grant privileges, the MySQL database, the FTS Tables, 
#   and user must already exist and the MySQL root user and password must be provided. 
#   Correct privileges to the fts database for, at least, the fts user are neeed for the fts server 
#   to work. So, if the parameter is set to false, make sure to grant privilegs manually. 
#
# @param configure_admins
#   (optional) Whether to configure the FTS admins or not. 
#   defaults to true. In order to configure the admins, the MySQL database, 
#   the FTS Tables, and user must already exist.
#
class fts::database (
  String  $db_root_user       = 'root',
  String  $db_root_password   = 'roottestpassword',
  String  $db_name            = 'fts',
  String  $fts_host           = 'fts-server.infn.it',
  String  $fts_db_user        = 'fts3',
  String  $fts_db_password    = 'ftstestpassword',
  Array   $admin_list         = ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
  Boolean $configure_firewall = true,
  Boolean $configure_selinux  = true,
  Boolean $build_mysql_server = true,
  Boolean $build_fts_tables   = true,
  Boolean $grant_privileges   = true,
  Boolean $configure_admins   = true,
) {
  # ------------------------------- SELinux ------------------------------- #
  if $configure_selinux {
    notify { 'Configuring Selinux': }
    case $facts['os']['name'] {
      'CentOS': {
        class { 'selinux':
          mode => 'permissive',
        }
      }
      default: {
        notify { "Unsupported OS: ${facts['os']['name']}, skipping Selinux Configuration": }
      }
    }
  }

  # instantiate the mysql server
  if $build_mysql_server {
    notify { 'Building MySQL Server': }
    class { 'mysql::server':
      root_password    => $db_root_password,
      override_options => {
        'mysqld' => {
          'bind-address' => $::ipaddress,
        },
      },
    }
  }
  # ------------------------------ MariaDB / MySQL ----------------------------- #
  # create the fts database and user  
  # ------------------------------- Dependencies ------------------------------- #
  if $build_fts_tables {
    notify { 'Checking FTS Database and populating FTS Tables': }
    case $facts['os']['name'] {
      'CentOS': {
        case $facts['os']['release']['major'] {
          '7': {
            package { 'fts-mysql':
              ensure  => present,
            }
            mysql::db { $db_name:
              ensure   => 'present',
              user     => $fts_db_user,
              grant    => ['ALL', 'SUPER'],
              password => $fts_db_password,
              name     => $db_name,
              host     => $::ipaddress,
              sql      => ['/usr/share/fts-mysql/fts-schema-8.0.1.sql'],
            }
          }
          default: {
            notify { "Unsupported Release: ${facts['os']['release']['major']}, database created AND using sql schema 8.0.1 from puppet": }
            file {
              default:
                ensure => directory,
                ;
              'etc/share':
                ;
              '/etc/share/fts-mysql':
                ;
            }
            file { '/usr/share/fts-mysql/fts-schema-8.0.1.sql':
              ensure  => file,
              source  => 'puppet:///modules/fts/fts-schema-8.0.1.sql',
              require => File['/etc/share/fts-mysql'],
            }
            mysql::db { $db_name:
              ensure   => 'present',
              user     => $fts_db_user,
              grant    => ['ALL', 'SUPER'],
              password => $fts_db_password,
              name     => $db_name,
              host     => $::ipaddress,
              sql      => ['/usr/share/fts-mysql/fts-schema-8.0.1.sql']
            }
          }
        }
      }
      default: {
        notify { "Unsupported OS: ${facts['os']['name']}, database created but skipping FTS Tables Creation": }
        file {
          default:
            ensure => directory,
            ;
          'etc/share':
            ;
          '/etc/share/fts-mysql':
            ;
        }
        file { '/usr/share/fts-mysql/fts-schema-8.0.1.sql':
          ensure  => file,
          source  => 'puppet:///modules/fts/fts-schema-8.0.1.sql',
          require => File['/etc/share/fts-mysql'],
        }
        mysql::db { $db_name:
          ensure   => 'present',
          user     => $fts_db_user,
          grant    => ['ALL', 'SUPER'],
          password => $fts_db_password,
          name     => $db_name,
          host     => $::ipaddress,
        }
      }
    }
  }
  else {
    notify { 'Checking / Creating FTS Database': }
    mysql::db { $db_name:
      ensure   => 'present',
      user     => $fts_db_user,
      grant    => ['ALL', 'SUPER'],
      password => $fts_db_password,
      name     => $db_name,
      host     => $::ipaddress,
    }
  }
  # ------------------------------ Admins and Privileges ----------------------------- #

  if $configure_admins {
    notify { 'Configuring FTS Admins': }
    $admin_list.each |$admin| {
      exec { "fts-admins-'${admin}'":
        command => "/usr/bin/mysql --user='${fts_db_user}' --password='${fts_db_password}' --database='${db_name}' --host='${::ipaddress}' --execute \"INSERT INTO t_authz_dn  (dn, operation) VALUES ('${admin}', 'config')\"",
        unless  => "/usr/bin/mysql --user='${fts_db_user}' --password='${fts_db_password}' --database='${db_name}' --host='${::ipaddress}' --execute \"SELECT * FROM t_authz_dn WHERE dn='${admin}' AND operation='config'\" | grep '${admin}'",
        require => Mysql::Db['fts'],
      }
    }
  }
  if $grant_privileges {
    notify { 'Granting privileges': }
    exec { 'fts-grant':
      command => "/usr/bin/mysql --user='${db_root_user}' --password='${db_root_password}' --database='${db_name}'  --execute \"GRANT ALL ON *.* TO '${fts_db_user}'@'${fts_host}' IDENTIFIED BY '${fts_db_password}'\"",
      unless  => "/usr/bin/mysql --user='${db_root_user}' --password='${db_root_password}' --database='${db_name}'  --execute \"SELECT * FROM mysql.user WHERE user='${fts_db_user}'@'${fts_host}'\" | grep fts@'${fts_host}'",
      require => Mysql::Db['fts'],
    }

    exec { 'fts-super':
      command => "/usr/bin/mysql --user='${db_root_user}' --password='${db_root_password}' --database='${db_name}'  --execute \"GRANT SUPER ON *.* TO '${fts_db_user}'@'${fts_host}' IDENTIFIED BY '${fts_db_password}'\"",
      require => Exec['fts-grant']
    }

    exec { 'root-grant':
      command => "/usr/bin/mysql --user='${db_root_user}' --password='${db_root_password}' --database='${db_name}'  --execute \"GRANT ALL ON *.* TO root@'${fts_host}' IDENTIFIED BY '${db_root_password}'\"",
      unless  => "/usr/bin/mysql --user='${db_root_user}' --password='${db_root_password}' --database='${db_name}'  --execute \"SELECT * FROM mysql.user WHERE user=root@'${fts_host}'\" | grep root@'${fts_host}'",
      require => Mysql::Db['fts'],
    }

    exec { 'flush privileges':
      command => "/usr/bin/mysql --user='${db_root_user}' --password='${db_root_password}' --database='${db_name}'  --execute \"FLUSH PRIVILEGES\"",
      require => [Exec['fts-grant'], Exec['root-grant']],
    }
  }
  # ------------------------------ Firewall ----------------------------- #
  if $configure_firewall {
    notify { 'Configuring Firewall': }
    include firewall
    firewall {
      '00000 accept all icmp':
        proto => 'icmp',
        jump  => 'accept',
        ;
      '00001 accept all to lo interface':
        proto   => 'all',
        iniface => 'lo',
        jump    => 'accept',
        ;
      '00002 reject local traffic not on loopback interface':
        iniface     => '! lo',
        proto       => 'all',
        destination => '127.0.0.1/8',
        jump        => 'reject',
        ;
      '00003 accept related established rules':
        proto => 'all',
        state => ['RELATED', 'ESTABLISHED'],
        jump  => 'accept',
        ;
    }

    firewall {
      '03306 MariaDB':
        dport => 3306,
        proto => 'tcp',
        jump  => 'accept',
    }
    firewall { '99999 drop all':
      proto  => 'all',
      jump   => 'drop',
      before => undef,
    }
  }
  notify { 'FTS Database Configuration Complete': }
}
