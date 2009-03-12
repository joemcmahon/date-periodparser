use Test::More tests=>12;
use Time::Local;
use Date::PeriodParser;
{
  $Date::PeriodParser::TestTime = $base = 1018674096;
  $Date::PeriodParser::TestTime = $base = 1018674096; # eliminate "used only once" warning
}

sub slt { scalar localtime timelocal @_ }
sub sl { scalar localtime shift }
my ($s, $mn, $h, $d, $m, $y, $wd, $yd, $dst) = localtime($base);


%tests = (
          'a week ago'                =>
             [ slt(0,  0,  0,  $d-7, $m, $y, abs($wd-7)%7, $yd-7, $dst),
               slt(59, 59, 23, $d-7, $m, $y, abs($wd-7)%7, $yd-7, $dst) ],
          '1 day ago'                =>
             [ slt(0,  0,  0,  $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst),
               slt(59, 59, 23, $d-1, $m, $y, ($wd-1)%7, $yd-1, $dst) ],
          'four days ago'                =>
             [ slt(0,  0,  0,  $d-4, $m, $y, ($wd-4)%7, $yd-4, $dst),
               slt(59, 59, 23, $d-4, $m, $y, ($wd-4)%7, $yd-4, $dst) ],
          'in three days time'        =>
             [ slt(0,  0,  0,  $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst),
               slt(59, 59, 23, $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst) ],
          'in 3 days time'        =>
             [ slt(0,  0,  0,  $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst),
               slt(59, 59, 23, $d+3, $m, $y, ($wd+3)%7, $yd+3, $dst) ],
          'seven days away'        =>
             [ slt(0,  0,  0,  $d+7, $m, $y, ($wd+7)%7, $yd+7, $dst),
               slt(59, 59, 23, $d+7, $m, $y, ($wd+7)%7, $yd+7, $dst) ],
         );

my($from, $to);
foreach $interval (keys %tests) {
  ($from, $to) = parse_period($interval);
  is(sl($from), $tests{$interval}->[0]);
  is(sl($to), $tests{$interval}->[1]);
}
