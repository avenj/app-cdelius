package App::cdelius;
use App::cdelius::Moops;


class Config :ro {
  # FIXME just prototyped for now
  has ffmpeg_path => ();
  has ffmpeg_global_opts  => ( isa => ImmutableArray );
  has ffmpeg_infile_opts  => ( isa => ImmutableArray );
  has ffmpeg_outfile_opts => ( isa => ImmutableArray );

  has cdrecord_path => ();
  has cdrecord_opts => ();
}


class Decoder :ro {
  
  has ffmpeg => (
    isa       => PathTiny,
    required  => 1,
  );

  has _ffmpeg_cmd => (
    isa       => Object,
    lazy      => 1,
    default   => sub {
      my ($self) = @_;
      FFmpeg::Command->new( $self->ffmpeg )
    },
  );

  method decode_track( $self:
      PathTiny :$input, 
      PathTiny :$output,
      ArrayObj :$global_opts = array(),
      ArrayObj :$infile_opts = array(),
      ArrayObj :$outfile_opts = array(),
  ) {
    my $ffm = $self->_ffmpeg_cmd;
    my $cfg = $self->config;

    $ffm->global_options( $global_opts->all )   if $global_opts->has_any;
    $ffm->infile_options( $infile_opts->all )   if $infile_opts->has_any;
    $ffm->outfile_options( $outfile_opts->all ) if $outfile_opts->has_any;

    $ffm->input_file("$input");
    $ffm->output_file("$output");

    my $res = $ffm->exec;
    die $ffm->errstr unless $res;
  }

}


class Burner :ro {

  has cdrecord => (
    isa      => PathTiny,
    required => 1,
  );

  has cdrecord_opts => (
    isa      => ArrayObj,
    coerce   => 1,
    default  => sub {
      [qw/ -v -audio -pad speed=16 /],
    },
  );

  method burn_cd( $self:
    PathTiny :$wavdir
  ) {
    my $cdr  = $self->cdrecord;
    my @opts = $self->cdrecord_opts->all;
    # FIXME iterate $wavdir, find tracks
    system($cdr, @opts, @tracks) 
  }
  
}



1;
