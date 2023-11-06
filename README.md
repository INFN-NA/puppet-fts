# fts

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with fts](#setup)
1. [Usage - Configuration options](#usage)
1. [Limitations - OS compatibility](#limitations)

## Description

A module to install and configure an FTS3 server and its MySQL database 
on a couple of Hosts. 

## Setup

```
puppet module install infn-na-fts
```

## Usage
The module can be used to configure both the database and fts server on the same machine, or on two different
machines. For the latter use case, to configure the fts server only, set `configure_db` to false, and to configure
the mysql database only, set `configure_fts` to false. 
```
# On the fts server 
fts {'creating-fts-server'
    fts_host           => 'fts3-server.example.org',
    db_host            => 'fts3-db.example.org',
    db_root_password   => 'ftstestpassword',
    fts_db_user        => 'fts3',
    fts_db_type        => 'mysql',
    fts_server_alias   => 'fts3-server',
    fts_db_threads_num => 24,
    configure_db       => false,
    configure_fts      => true,
    configure_firewall => true,
    configure_lsc      => true,
    vo_list            => ['alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 'escape', 'lhcb', 'ops', 'wlcg'],
}
# On the fts database
fts {'creating the database'
    fts_host           => 'fts3-server.example.org',
    db_host            => 'fts3-db.example.org',
    db_root_password   => 'ftstestpassword',
    fts_db_user        => 'fts3',
    fts_db_type        => 'mysql',
    fts_server_alias   => 'fts3-server',
    fts_db_threads_num => 24,
    configure_db       => true,
    configure_fts      => false,
    configure_firewall => true,
    configure_lsc      => true,
    vo_list            => ['alice', 'atlas', 'cms', 'cygno', 'datacloud', 'dteam', 'escape', 'lhcb', 'ops', 'wlcg'],
}
```

## Limitations

It works only on CentOS 7 distributions.
