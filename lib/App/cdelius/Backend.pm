package App::cdelius::Backend;
use App::cdelius::Moops;

class Config :ro {

  has wav_dir => (
    isa       => Str,
    default   => sub { '/tmp/cdelius' },
  );

  has ffmpeg_path => (
    isa       => Str,
    default   => sub { '/usr/bin/ffmpeg' },
  );

  has ffmpeg_global_opts => ( 
    isa     => Str,
    default => sub { '' },
  );

  has ffmpeg_infile_opts => (
    isa     => Str,
    default => sub { '' },
  );

  has ffmpeg_outfile_opts => (
    isa     => Str,
    default => sub { '' },
  );

  has cdrecord_path => (
    isa      => Str,
    default  => sub { '/usr/bin/cdrecord' },
  );

  has cdrecord_opts => (
    isa      => Str,
    default  => sub { '-vv -audio -pad speed=16' },
  );

  method from_yaml ($class: 
    :$path
  ) {
    require YAML::Tiny;

    $path = path($path) unless is_PathTiny($path);
    throw "No such file $path" unless $path->exists;

    my $yml = YAML::Tiny->new->read("$path");

    $class->new( %{ $yml->[0] } )
  }

  method to_yaml ($self:
    :$path,
    :$data = undef
  ) {
    require YAML::Tiny;
    my $yml = YAML::Tiny->new;

    $yml->[0] = $data ? $data : +{ %$self };

    $yml->write("$path")
  }

  method write_new_config($self:
    :$path,
    :$force = 0
  ) {
    $path = path($path) unless is_PathTiny($path);
    throw "File already exists at $path" if $path->exists and !$force;
    my $class = blessed($self) || $self;
    my $new = $class->new; 
    $new->to_yaml(path => $path)
  }

}


class Decoder :ro {
  
  has ffmpeg => (
    isa       => PathTiny,
    coerce    => 1,
    required  => 1,
  );

  has verbose => (
    isa     => Bool,
    default => sub { 0 },
  );

  has global_opts => (
    isa     => ArrayObj,
    coerce  => 1,
    default => sub { [] },
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
      ArrayObj :$infile_opts = array(),
      ArrayObj :$outfile_opts = array()
  ) {
    my $ffm = $self->_ffmpeg_cmd;
    my $cfg = $self->config;
    my $global_opts = $self->global_opts;

    $ffm->global_options( $global_opts->all )   if $global_opts->has_any;
    $ffm->infile_options( $infile_opts->all )   if $infile_opts->has_any;
    $ffm->outfile_options( $outfile_opts->all ) if $outfile_opts->has_any;

    $ffm->input_file("$input");
    $ffm->output_file("$output");

    my $res = $ffm->exec;
    throw $ffm->errstr unless $res;
    say $ffm->stdout if $self->verbose;
  }

}


class Burner :ro {

  has cdrecord => (
    isa      => PathTiny,
    coerce   => 1,
    required => 1,
  );

  has cdrecord_opts => (
    isa      => Str,
    required => 1,
  );

  method burn_cd( $self:
    PathTiny :$wav_dir
  ) {
    my $cdr  = $self->cdrecord;
    my @opts = split ' ', $self->cdrecord_opts;

    throw "No such directory $wav_dir"
      unless $wav_dir->exists;

    my @tracks;
    for my $chld ($wav_dir->children) {
      push @tracks, $chld if $chld =~ /\.wav$/;
    }

    throw "No files present under $wav_dir"
      unless @tracks;

    system($cdr, @opts, @tracks) 
  }
  
}

1;
