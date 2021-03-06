package App::cdelius::UI;
use Defaults::Modern;

package App::cdelius::JSONable {
  use Defaults::Modern;
  use Moo::Role;
  method TO_JSON {
    my ($self) = @_;
    # Lowu hash()es provide a TO_JSON:
    my $data = hash(%$self);
    for my $key ($data->keys->all) {
      # un-bless Path::Tiny objs
      my $val = $data->get($key);
      $data->set($key => "$val") if blessed $val;
    }
    $data
  }
}

package App::cdelius::UI::Track {
  use Defaults::Modern;
  use Moo;
  use MooX::late;
  with 'App::cdelius::JSONable';

  has trackpath => (
    is        => 'ro',
    isa       => Path,
    coerce    => 1,
    required  => 1,
  );

  has name => (
    is        => 'ro',
    isa       => Str,
    lazy      => 1,
    default   => sub { 
      my ($self) = @_;
      my $base = $self->trackpath->basename;
      $base =~ s/\.[^.]+$//r;
    },
  );

  ## FIXME can we use FFmpeg to validate / get length...?

  method BUILD {
    $self->trackpath->exists or croak "No such file: ".$self->trackpath
  }
}

package App::cdelius::UI::TrackList {
  use Defaults::Modern;
  use App::cdelius::Exception;
  use Moo;
  use MooX::late;
  with 'App::cdelius::JSONable';

  has listpath => (
    is        => 'ro',
    isa       => Path,
    lazy      => 1,
    writer    => 1,
    predicate => 1,
    coerce    => 1,
    default   => sub { '' },
  );

  has _tracks => (
    is        => 'ro',
    isa       => ImmutableArray,
    coerce    => 1,
    default   => sub { [] },
    writer    => '_set_tracks',
    init_arg  => 'init_tracks',
  );

  define INITIAL_TRACK = 1000;

  method new_track (
    (Str | Path) :$path
  ) {
    App::cdelius::UI::Track->new(
      trackpath => $path,
    )
  }

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
    Object        :$track,
    (Int | Undef) :$position = undef
  ) {
    my $tlist = array( $self->_tracks->all );

    unless (defined $position) {
      $tlist->push( $track );
      $self->_set_tracks(
        immarray( $tlist->all )
      );
      return $tlist->count - 1
    }

    report "Destination index $position cannot be negative"
      unless $position >= 0;

    my $last_pos = $self->_tracks->has_any ? $self->_tracks->count -1 : 0;
    report "Destination index $position beyond end of list"
      if $position > $last_pos;

    $tlist->splice( $position, 0, $track );

    $self->_set_tracks(
      immarray( $tlist->all ) 
    );

    $position
  }

  method del_track (Int :$position) {
    my $track = $self->get_track(position => $position)
      or report "No such track: $position";

    $self->_set_tracks(
      $self->_tracks->sliced( 
        0 .. ($position - 1), ($position + 1) .. ($self->_tracks->count - 1)
      )
    );

    $track
  }

  method move_track (Int :$from_index, Int :$to_index) {
    my $last_pos = $self->_tracks->has_any ? $self->_tracks->count - 1 : 0;
    report "Destination index $to_index beyond end of list"
      if $to_index > $last_pos;

    my $track = $self->del_track(position => $from_index);
    report "No track found at index $from_index"
      unless $track;

    $self->add_track(track => $track, position => $to_index)
  }

  method save (
    (Str | Undef) :$path = undef,
  ) {

    $path = 
      $path ? path($path)
      : $self->has_listpath ? $self->listpath
      : report "No 'path =>' specified and no '->listpath' attrib available";

    require JSON::Tiny;
    my $enc = JSON::Tiny->new;
    my $json;
    unless ($json = $enc->encode($self)) {
      report "JSON encoding failed; ".$enc->error
    }

    $path->spew_utf8($json);
  }

  method load ( $class:
    (Str | Path) :$path,
  ) {
    $path = path("$path") unless blessed $path;

    my $json = $path->slurp_utf8;

    require JSON::Tiny;
    my $enc = JSON::Tiny->new;
    my $data;
    unless ($data = $enc->decode($json)) {
      report "JSON decoding failed; ".$enc->error
    }
    
    my $tlist = delete $data->{_tracks};
    unless (is_ArrayRef $tlist) {
      report "Expected tracklist to be an ARRAY but got $tlist"
    }

    App::cdelius::UI::TrackList->new(
      init_tracks => $tlist,
      listpath    => "$path",
    )
  }

  method decode (
    Object         :$config,
    (Str | Path)   :$wav_dir = '',
    Bool           :$verbose = 0
  ) {

    my $decoder = App::cdelius::Component->build( 'Backend::Decoder' =>
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
    my $total_sz = 0;
    for my $track ($self->all) {
      ++$tnum;

      my $name    = $track->name;
      my $outfile = "${wav_dir}/${tnum}_${name}.wav";

      $total_sz += $decoder->decode_track(
        input  => path( $track->trackpath ),
        output => path( $outfile ),

        ( $config->ffmpeg_infile_opts ?
            ( infile_opts => array( split ' ', $config->ffmpeg_infile_opts ) )
            : ()
        ),

        ( $config->ffmpeg_outfile_opts ?
          ( outfile_opts => array( split ' ', $config->ffmpeg_outfile_opts ) )
          : ()
        ),
      );

    }

    my $decoded_ct = $tnum - INITIAL_TRACK;
    wantarray ? ($decoded_ct, $total_sz) : $total_sz
  }

  method burn (
    Object          :$config,
    (Str | Path)    :$wav_dir = '',
  ) {

    my $splitopts = array( split ' ', $config->cdrecord_opts );
    report "Missing cdrecord_opts" unless $splitopts->has_any;
    warn  "cdrecord_opts missing '-audio' flag"
      unless $splitopts->has_any(sub { $_ eq '-audio' });
    
    my $burner = App::cdelius::Component->build( 'Backend::Burner' =>
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
