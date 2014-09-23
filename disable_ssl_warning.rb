# disable HTTPS verification and silence ruby warnings
warn_level = $VERBOSE
$VERBOSE = nil
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
$VERBOSE = warn_level
