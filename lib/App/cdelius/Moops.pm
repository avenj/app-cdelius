package App::cdelius::Moops;
use strictures 1;

use parent 'MoopsX::ListObjects';
use Path::Tiny ();

sub import {
  push @{ $_[1] ||= [] }, (
    'Path::Tiny'              => [ 'path' ],
    'App::cdelius::Types'     => [ -all ],
    'App::cdelius::Exception' => [ 'throw' ],
  );
  goto \&MoopsX::ListObjects::import
}

1;
