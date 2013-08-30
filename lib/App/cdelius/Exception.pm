package App::cdelius::Exception;
use strict; use warnings FATAL => 'all';

use Exporter 'import';
our @EXPORT = 'report';
sub report {
  __PACKAGE__->throw(@_)
}

use Moo;
extends 'Throwable::Error';

1;
