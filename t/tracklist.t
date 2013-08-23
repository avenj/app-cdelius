use Test::More;
use strict; use warnings FATAL => 'all';

use App::cdelius::UI;

{ package
  MockTrack;
  sub new  { bless [], shift }
  sub name { rand }
  sub path { rand }
}

my $tlist = App::cdelius::UI::TrackList->new;

cmp_ok $tlist->add_track(
  track => MockTrack->new
), '==', 0, 'add_track first track ok';

cmp_ok $tlist->all, '==', 1, '->all returned one track ok';

done_testing;
