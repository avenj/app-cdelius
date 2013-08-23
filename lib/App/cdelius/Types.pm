package App::cdelius::Types;
use strict; use warnings FATAL => 'all';

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

1;