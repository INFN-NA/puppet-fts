# @summary This class isntall the FTS client
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
