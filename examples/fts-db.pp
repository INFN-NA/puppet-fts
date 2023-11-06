# FTS DB

node 'db-ha-wp1.na.infn.it' {
# ---------------------------------------------------------------------------- #
#                                   Packages                                   #
# ---------------------------------------------------------------------------- #
  file {
    default:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      ;
    '/etc/grid-security':
      ;
  }
  file {
    default:
      owner   => 'root',
      group   => 'root',
      require => File['/etc/grid-security']
      ;
    '/etc/grid-security/hostcert.pem':
      ensure  => file,
      mode    => '0644',
      source  => 'file:///root/certificates/hostcert.pem',
      replace => false,
      ;
    '/etc/grid-security/hostkey.pem':
      ensure  => file,
      mode    => '0400',
      source  => 'file:///root/certificates/hostkey.pem',
      replace => false,
      ;
  }
  class { 'fts':
    fts_host           => 'fts-ha-wp1.na.infn.it',
    db_host            => 'db-ha-wp1.na.infn.it',
    db_root_password   => 'ftstestpassword',
    fts_db_user        => 'fts3',
    fts_db_type        => 'mysql',
    fts_server_alias   => 'fts3-server',
    admin_list         => ['/DC=org/DC=terena/DC=tcs/C=IT/O=Istituto Nazionale di Fisica Nucleare/CN=Michele Delli Veneri delliven@infn.it'],
    fts_db_threads_num => 24,
    configure_db       => true,
    configure_fts      => false,
    configure_firewall => true,
    configure_lsc      => true,
    vo_list            => ['cygno', 'datacloud', 'ops'],
  }
}
