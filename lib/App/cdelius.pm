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
    # FIXME
  }
);

has decoder => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['App::cdelius::Backend::Decoder'],
  default   => sub {
    # FIXME
  },
);

has burner => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['App::cdelius::Backend::Burner'],
  default   => sub {
    # FIXME
  },
);


1;
