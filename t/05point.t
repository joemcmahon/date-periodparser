use Test::More tests=>12;
use Date::PeriodParser;
use Time::Local;

# Apply points of day to a range
# Adjusts day/month/year point to a range

my($from, $to);
my $base_day = 8;
my $base_month = 8;
my $base_year = 2003;

($from, $to) = Date::PeriodParser::_apply_point_of_day($base_day,
                                                      $base_month,
                                                      $base_year,
                                                      "night");
is($from,
   timelocal(0, 0, 21, $base_day, $base_month, $base_year), "from night");
is($to,
   timelocal(59, 59, 5, $base_day+1, $base_month, $base_year), "to night");

($from, $to) = Date::PeriodParser::_apply_point_of_day($base_day,
                                                      $base_month,
                                                      $base_year,
                                                      "morning");
is($from,
   timelocal(0, 0, 0, $base_day, $base_month, $base_year), "from morning");
is($to,
   timelocal(0, 0, 12, $base_day, $base_month, $base_year), "to morning");

($from, $to) = Date::PeriodParser::_apply_point_of_day($base_day,
                                                      $base_month,
                                                      $base_year,
                                                      "lunchtime");
is($from,
   timelocal(0, 0, 12, $base_day, $base_month, $base_year), "from lunchtime");
is($to,
   timelocal(0, 30, 13, $base_day, $base_month, $base_year), "to lunchtime");

($from, $to) = Date::PeriodParser::_apply_point_of_day($base_day,
                                                      $base_month,
                                                      $base_year,
                                                      "afternoon");
is($from,
   timelocal(0, 30, 13, $base_day, $base_month, $base_year), "from afternoon");
is($to,
   timelocal(0, 0, 18, $base_day, $base_month, $base_year), "to afternoon");

($from, $to) = Date::PeriodParser::_apply_point_of_day($base_day,
                                                      $base_month,
                                                      $base_year,
                                                      "evening");
is($from,
   timelocal(0, 0, 18, $base_day, $base_month, $base_year), "from evening");
is($to,
   timelocal(59, 59, 23, $base_day, $base_month, $base_year), "to evening");

($from, $to) = Date::PeriodParser::_apply_point_of_day($base_day,
                                                      $base_month,
                                                      $base_year,
                                                      "day");
is($from,
   timelocal(0, 0, 0, $base_day, $base_month, $base_year), "from day");
is($to,
   timelocal(59, 59, 23, $base_day, $base_month, $base_year), "to day");

