package App::cdelius;
use Defaults::Modern;

use App::cdelius::Component;

use Types::Standard -types;
use Moo;

has factory => (
  is        => 'ro',
  isa       => InstanceOf['App::cdelius::Component'],
  default   => sub { App::cdelius::Component->new },
);

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
    my ($self) = @_;
    $self->factory->build('Backend::Config')->from_yaml(
      path => $self->config_file_path
    )
  }
);

has tracklist => (
  lazy      => 1,
  is        => 'ro',
  isa       => InstanceOf['App::cdelius::UI::TrackList'],
  default   => sub {
    my ($self) = @_;
    $self->factory->build( 'UI::TrackList' )
  },
);


1;
