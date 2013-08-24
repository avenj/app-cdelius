package App::cdelius::UI;

use App::cdelius::Moops;
use App::cdelius::Backend;

class Track :ro {

  has path => (
    isa       => PathTiny,
    required  => 1,
  );

  has name => (
    isa       => Str,
    lazy      => 1,
    default   => sub { 
      my ($self) = @_;
      my $base = $self->path->basename;
      $base =~ s/\.[^.]+$//r;
    },
  );

}


class TrackList :ro {

  has _tracks => (
    isa       => ArrayObj,
    coerce    => 1,
    default   => sub { [] },
    writer    => '_set_tracks',
    init_arg  => 'init_tracks',
  );

  define INITIAL_TRACK = 1000;

  method all { $self->_tracks->all }

  method shuffled {
    blessed($self)->new(
      init_tracks => [ $self->_tracks->shuffle->all ]
    )
  }

  method get_track ($self:
    Int :$position
  ) {
    return $self->_tracks->get($position)
  }

  method add_track ($self:
    TrackObj :$track,
    (Int | Undef) :$position = undef
  ) {
    unless (defined $position) {
      $self->_tracks->push( $track );
      return $self->_tracks->count - 1
    }
    $self->_tracks->splice( $position, 0, $track );
    return $position
  }

  method del_track ($self:
    Int :$position
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
    my $track = $self->del_track(position => $from_index)
      or throw "No such track: $from_index";
    $self->add_track(track => $track, position => $to_index)
  }

  method decode ($self:
    ConfigObj        :$config,
    (Str | PathTiny) :$wav_dir = '',
    Bool             :$verbose = 0
  ) {

    my $decoder = App::cdelius::Backend::Decoder->new(
      ffmpeg  => $config->ffmpeg_path,
      verbose => $verbose,
      ( $config->ffmpeg_global_opts ?
          ( global_opts => [ split ' ', $config->ffmpeg_global_opts ] )
          : ()
      ),
    );

    $wav_dir = $wav_dir ?
      path("$wav_dir") : path( $config->wav_dir );

    $wav_dir->mkpath unless $wav_dir->exists;

    my $tnum = INITIAL_TRACK;
    for my $track ($self->all) {
      ++$tnum;

      my $name    = $track->name;
      my $outfile = "${wav_dir}/${tnum}_${name}.wav";

      $decoder->decode_track(
        input  => path( $track->path ),
        output => path( $outfile ),

        ( $config->ffmpeg_infile_opts ?
            ( infile_opts => [ split ' ', $config->ffmpeg_infile_opts ] )
            : ()
        ),

        ( $config->ffmpeg_outfile_opts ?
          ( outfile_opts => [ split ' ', $config->ffmpeg_outfile_opts ] )
          : ()
        ),
      );

    }

    return $tnum - INITIAL_TRACK
  }

}


class Session :ro {

  has path      => (
    isa       => PathTiny,
    coerce    => 1,
    required  => 1,
  );

  has name      => (
    isa       => Str,
    required  => 1,
  );

  has tracklist => (
    isa       => Object,
    is        => 'rwp',
    lazy      => 1
  );

  has _fh => (
    isa       => FileHandle,
    lazy      => 1,
    writer    => '_set_fh',
    clearer   => '_clear_fh',
    predicate => '_has_fh',
  );

  method lock_session {
    # FIXME open, flock, _set_fh
  }

  method unlock_session {
    # FIXME unlock, close, _clear_fh
  }

  method save_session {
    # FIXME serialize out session to save path
    #  use $self->_fh if we have one
  }

  method load_session ($self:
    (Str | PathTiny) :$path,
  ) {
    # FIXME YAML::Tiny deserializer
    $path = path("$path") unless is_PathTiny $path;

    my %params; # FIXME
    blessed($self) ? 
      blessed($self)->new(%params)
      : $self->new(%params)
    # FIXME return blessed($self)->new if blessed
  }
}


1;
