package App::cdelius::Moops;
use strictures 1;

use parent 'MoopsX::ListObjects';

use Path::Tiny ();
use App::cdelius::Types ();
use App::cdelius::Exception ();
use PerlX::Maybe ();

sub import {
  push @{ $_[1] ||= [] }, (
    'Path::Tiny'              => [ 'path' ],
    'PerlX::Maybe'            => [ 'maybe', 'provided' ],

    'App::cdelius::Types'     => [ -all ],
    'App::cdelius::Exception' => [ 'report' ],
  );
  goto \&MoopsX::ListObjects::import
}

1;
