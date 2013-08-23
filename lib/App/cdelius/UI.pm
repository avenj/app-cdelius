package App::cdelius::UI;

use App::cdelius::Moops;

class Track :ro {

  has path => (
    isa       => PathTiny,
    required  => 1,
  );

  has name => (
    isa       => Str,
    lazy      => 1,
    default   => sub { shift->path->basename },
  );

}


class TrackList :ro {

  has _tracks => (
    isa     => ArrayObj,
    coerce  => 1,
    default => sub { [] },
    writer  => '_set_tracks',
  );

  method all {
    $self->_tracks->all
  }

  method get_track ($self:
    Int :$position
  ) {
    return $self->_tracks->get($position)
  }

  method add_track ($self:
    Object :$track,
    (Int|Undef) :$position = undef
  ) {
    unless (defined $position) {
      $self->_tracks->push( $track );
      return $self->_tracks->count - 1
    }
    $self->_tracks->splice( $position, 0, $track );
    return $position
  }

  method del_track ($self:
    Int $position
  ) {
    $self->_set_tracks(
      $self->_tracks->sliced( 
        0 .. ($position - 1), ($position + 1) .. ($self->_tracks->count - 1)
      )
    )
  }

  method move_track ($self:
    Int :$from_index,
    Int :$to_index
  ) {
    my $track = $self->del_track($from_index)
    # FIXME exception objs
      or die "No such track: $from_index";
    $self->add_track(track => $track, position => $to_index)
  }
}


class Cmd {

    # FIXME
}

1;
