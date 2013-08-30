package App::cdelius::Exception;
use strictures 1;

use Exporter 'import';
our @EXPORT = 'report';
sub report {
  __PACKAGE__->throw(@_)
}

use Moo;
extends 'Throwable::Error';

1;
