package App::cdelius::Exception;

use Moo;
extends 'Throwable::Error';

use Exporter 'import';
our @EXPORT = 'exception';

sub exception {
  __PACKAGE__->throw(@_)
}

1;
