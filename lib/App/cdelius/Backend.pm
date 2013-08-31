package App::cdelius::Backend;
use Defaults::Modern;

package App::cdelius::Backend::Config {
  use Defaults::Modern;
  use App::cdelius::Exception;
  use Moo; 
  use MooX::late;

  has wav_dir => (
    is        => 'ro',
    isa       => Str,
    default   => sub { '/tmp/cdelius' },
  );

  has ffmpeg_path => (
    is        => 'ro',
    isa       => Str,
    default   => sub { '/usr/bin/ffmpeg' },
  );

  has ffmpeg_global_opts => ( 
    is      => 'ro',
    isa     => Str,
    default => sub { '' },
  );

  has ffmpeg_infile_opts => (
    is      => 'ro',
    isa     => Str,
    default => sub { '' },
  );

  has ffmpeg_outfile_opts => (
    is      => 'ro',
    isa     => Str,
    default => sub { '' },
  );

  has cdrecord_path => (
    is       => 'ro',
    isa      => Str,
    default  => sub { '/usr/bin/cdrecord' },
  );

  has cdrecord_opts => (
    is      => 'ro',
    isa      => Str,
    default  => sub { '-vv -audio -pad speed=16' },
  );

  method from_yaml (
    (Str | Path) :$path
  ) {
    require YAML::Tiny;

    $path = path("$path") unless blessed $path;
    report "No such file $path" unless $path->exists;

    my $yml = YAML::Tiny->new->read("$path");

    my $class = blessed($self) || $self;
    $class->new( %{ $yml->[0] } )
  }

  method to_yaml (
    (Str | Path)    :$path,
    (Ref | Undef)   :$data = undef
  ) {
    require YAML::Tiny;
    my $yml = YAML::Tiny->new;

    $yml->[0] = $data ? $data : +{ %$self };

    $yml->write("$path")
  }

  method write_new_config(
    (Str | Path)    :$path,
    Bool            :$force = 0
  ) {
    $path = path($path) unless blessed $path;
    report "File already exists at $path" if $path->exists and !$force;
    my $class = blessed($self) || $self;
    my $new = $class->new; 
    $new->to_yaml(path => $path)
  }

}

package App::cdelius::Backend::Decoder {
  use Defaults::Modern;
  use App::cdelius::Exception;
  use FFmpeg::Command;
  use Moo; use MooX::late;

  has ffmpeg => (
    is        => 'ro',
    isa       => Path,
    coerce    => 1,
    required  => 1,
  );

  has verbose => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 0 },
  );

  has global_opts => (
    is      => 'ro',
    isa     => ArrayObj,
    coerce  => 1,
    default => sub { [] },
  );

  has _ffmpeg_cmd => (
    is        => 'ro',
    isa       => Object,
    lazy      => 1,
    default   => sub {
      my ($self) = @_;
      FFmpeg::Command->new( $self->ffmpeg )
    },
  );

  method decode_track(
      Path     :$input,
      Path     :$output,
      ArrayObj :$infile_opts = array(),
      ArrayObj :$outfile_opts = array()
  ) {
    my $ffm = $self->_ffmpeg_cmd;
    my $global_opts = $self->global_opts;

    $ffm->global_options( $global_opts->all )   if $global_opts->has_any;
    $ffm->infile_options( $infile_opts->all )   if $infile_opts->has_any;
    $ffm->outfile_options( $outfile_opts->all ) if $outfile_opts->has_any;

    $ffm->input_file("$input");
    $ffm->output_file("$output");

    my $res = $ffm->exec;
    report $ffm->errstr unless $res;
    say $ffm->stdout if $self->verbose;

    return $output->exists ? $output->stat->size
      : confess "No output file found at $output"
  }

}

package App::cdelius::Backend::Burner {
  use Defaults::Modern;
  use App::cdelius::Exception;
  use Moo; use MooX::late;

  has cdrecord => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    required => 1,
  );

  has cdrecord_opts => (
    is       => 'ro',
    isa      => ArrayObj,
    coerce   => 1,
    required => 1,
  );

  method burn_cd( $self:
    Path :$wav_dir
  ) {
    my $cdr  = $self->cdrecord;
    my @opts = split ' ', $self->cdrecord_opts;

    report "No such directory $wav_dir"
      unless $wav_dir->exists;

    my @tracks;
    for my $chld ($wav_dir->children) {
      push @tracks, $chld if $chld =~ /\.wav$/;
    }

    report "No files present under $wav_dir"
      unless @tracks;

    system($cdr, @opts, @tracks) 
  }
  
}

1;
