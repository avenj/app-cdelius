package App::cdelius::UI;

use App::cdelius::Moops;

class Track {

  has path => (
    isa      => PathTiny,
    required => 1,
  );

}

class TrackList {

  has tracks => (
    isa     => ArrayObj,
    coerce  => 1,
    default => sub { [] },
  );

}

class Cmd {

}

1;
