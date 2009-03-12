use Test::More tests=>8;
use Time::Local;
use Date::PeriodParser;
{
  $Date::PeriodParser::TestTime = $base = 1018674096;
  $Date::PeriodParser::TestTime = $base = 1018674096; # eliminate "used only once" warning
}

sub slt { scalar localtime timelocal @_ }
sub sl { scalar localtime shift }
my ($s, $mn, $h, $d, $m, $y, $wd, $yd, $dst) = localtime($base);
                                               # Fri Apr 12 22:01:36 2002
%tests = (
        "round about now"  => [ sl(1018673796), sl(1018674396) ],
                              # Fri Apr 12 21:56:36 2002,
                              # Fri Apr 12 22:06:36 2002
"roughly yesterday afternoon" 
                           => [sl(1018549800), sl(1018580400)],
                              # Thu Apr 11 11:30:00 2002
                              # Thu Apr 11 20:00:00 2002 
 "around the morning of the day before yesterday" 
                           => [sl(1018414800), sl(1018472400)], 
                              # Tue Apr  9 22:00:00 2002
                              # Wed Apr 10 14:00:00 2002
 "roughly eleven days ago" => [ sl(1017518400), sl(1017863999) ], 
                              # Sat Mar 30 12:00:00 2002
                              # Wed Apr  3 11:59:59 2002
         );

my($from, $to);
foreach $interval (keys %tests) {
  ($from, $to) = parse_period($interval);
  is(sl($from), $tests{$interval}->[0]);
  is(sl($to), $tests{$interval}->[1]);
}
