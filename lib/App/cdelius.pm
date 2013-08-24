package App::cdelius;
use strictures 1;

#use Function::Parameters;
use Types::Standard -types;

use App::cdelius::Component;

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
    # FIXME config load (use ::Component)
  }
);

has tracklist => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['App::cdelius::UI::TrackList'],
  default   => sub {
    # FIXME spawn tracklist (use ::Component)
  },
);


1;
