package App::cdelius;
use strictures 1;

use App::cdelius::Backend;
use App::cdelius::UI;

use Function::Parameters;

use Types::Standard -types;

use Moo;

has config_file_path => (
  required  => 1,
  is        => 'ro',
  isa       => Str,
);

has config => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['App::cdelius::Backend::Config'],
  default   => sub {
    # FIXME config load
  }
);

## FIXME factory method(s) to glue everything together?

1;
