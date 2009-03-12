use Test::More tests=>6;
use Date::PeriodParser;

# zero leeway
my($from,$to);
($from, $to) = Date::PeriodParser::apply_leeway(1000, 1000, 0);
is($from, 1000);
is($to, 1000);

# positive leeway
($from, $to) = Date::PeriodParser::apply_leeway(1000, 1000, 1000);
is($from, 0);
is($to, 2000);

# negative leeway - not used, but edge case
($from, $to) = Date::PeriodParser::apply_leeway(1000, 1000, -1000);
is($from, 2000);
is($to, 0);
