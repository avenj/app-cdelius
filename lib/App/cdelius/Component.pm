package App::cdelius::Component;
use Defaults::Modern;

use App::cdelius::Backend;
use App::cdelius::UI;

method new_factory ($class: %params) { bless [], $class }

method build ($component, %params) {
  my $pkg = 'App::cdelius::'.$component;
  $pkg->new(%params)
}

1;
