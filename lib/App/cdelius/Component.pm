package App::cdelius::Component;
use strictures 1;

# Object factory.

use App::cdelius::Backend;
use App::cdelius::UI;

use Function::Parameters;

method new { bless [], shift }

method build ($component, %params) {
  my $pkg = 'App::cdelius::'.$component;
  $pkg->new(%params)
}

1;
