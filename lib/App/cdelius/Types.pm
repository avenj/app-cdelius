package App::cdelius::Types;
use strictures 1;

use Type::Library -base;
use Type::Utils   -all;
use Types::Standard -types;
use List::Objects::Types -all;

use Path::Tiny 'path';

declare PathTiny =>
  as Object,
  where { $_->isa('Path::Tiny') };

coerce PathTiny =>
  from Str,
  via { path($_) };

declare ConfigObj =>
  as Object,
  where { $_->isa('App::cdelius::Backend::Config') };

declare TrackObj =>
  as Object,
  where { $_->isa('App::cdelius::UI::Track') };
1;
