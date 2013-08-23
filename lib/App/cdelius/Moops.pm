package App::cdelius::Moops;
use strict; use warnings FATAL => 'all';

use parent 'MoopsX::ListObjects';
use Path::Tiny ();

sub import {
  push @{ $_[1] ||= [] }, (
    'Path::Tiny' => [ 'path' ],
    'App::cdelius::Types' => [ -all ],
  );
  goto \&MoopsX::ListObjects::import
}

1;
