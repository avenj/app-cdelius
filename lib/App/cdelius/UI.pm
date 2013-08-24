package App::cdelius::UI;

use App::cdelius::Moops;
use App::cdelius::Backend;

role JSON {
  method TO_JSON {
    my ($self) = @_;

    # Lowu hash()es provide a TO_JSON:
    my $data = hash(%$self);
    for my $key ($data->keys->all) {
      # un-bless Path::Tiny objs
      my $val = $data->get($key);
      $data->set($key => "$val") if is_PathTiny $val;
    }

    $data
  }
}

class Track with JSON :ro {

  has path => (
    isa       => PathTiny,
    coerce    => 1,
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


class TrackList with JSON :ro {

  has path => (
    isa       => PathTiny,
    coerce    => 1,
    lazy      => 1,
    writer    => 'set_path',
    predicate => 'has_path',
    default   => sub { '' },
  );

  has _tracks => (
    isa       => ImmutableArray,
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

  method get_track (Int :$position) { 
    $self->_tracks->get($position)
  }

  method add_track (
    TrackObj      :$track,
    (Int | Undef) :$position = undef
  ) {
    my $tlist = array( $self->_tracks->all );
    unless (defined $position) {
      $tlist->push( $track );
      return $tlist->count - 1
    }
    $tlist->splice( $position, 0, $track );
    $self->_set_tracks(
      immarray( $tlist->all ) 
    );
    return $position
  }

  method del_track (Int :$position) {
    $self->_set_tracks(
      $self->_tracks->sliced( 
        0 .. ($position - 1), ($position + 1) .. ($self->_tracks->count - 1)
      )
    )
  }

  method move_track (Int :$from_index, Int :$to_index) {
    my $track = $self->del_track(position => $from_index)
      or throw "No such track: $from_index";
    $self->add_track(track => $track, position => $to_index)
  }

  method save (
    (Str | Undef) :$path = undef,
  ) {

    $path = 
      $path ? path($path)
      : $self->has_path ? $self->path
      : throw "No 'path =>' specified and no '->path' attrib available";

    require JSON::Tiny;
    my $enc = JSON::Tiny->new;
    my $json;
    unless ($json = $enc->encode($self)) {
      throw "JSON encoding failed; ".$enc->error
    }

    $path->spew_utf8($json);
  }

  method load ( $class:
    (Str | PathTiny) :$path,
  ) {
    $path = path("$path") unless is_PathTiny $path;

    my $json = $path->slurp_utf8;

    require JSON::Tiny;
    my $enc = JSON::Tiny->new;
    my $data;
    unless ($data = $enc->decode($json)) {
      throw "JSON decoding failed; ".$enc->error
    }
    
    my $tlist = delete $data->{_tracks};
    unless (is_ArrayRef $tlist) {
      throw "Expected tracklist to be an ARRAY but got $tlist"
    }

    App::cdelius::UI::TrackList->new(
      init_tracks => $tlist,
      path        => "$path",
    )
  }

  method decode (
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

    $tnum - INITIAL_TRACK
  }

  method burn (
    ConfigObj         :$config,
    (Str | PathTiny)  :$wav_dir = '',
  ) {

    my $splitopts = array( split ' ', $config->cdrecord_opts );
    throw "Missing cdrecord_opts" unless $splitopts->has_any;
    warn  "cdrecord_opts missing '-audio' flag"
      unless $splitopts->has_any(sub { $_ eq '-audio' });
    
    my $burner = App::cdelius::Backend::Burner->new(
      cdrecord      => $config->cdrecord_path,
      cdrecord_opts => $splitopts,
    );

    $wav_dir = $wav_dir ?
      path("$wav_dir") : path( $config->wav_dir );

    $burner->burn_cd(
      wav_dir => $wav_dir,
    )
  }

}


1;
