# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include fts::client
class fts::client {
  package {
    default:
      ensure   => present,
      provider => yum,
      ;

    # Base packages
    ['fts-rest-client']:
      ;
  }
}
