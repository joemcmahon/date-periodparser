use strict;
use warnings;
use Test::More;
use Date::PeriodParser;

eval {
    require Devel::Hide;
    Devel::Hide->import('Lingua::EN::Words2Nums');
};
plan skip_all => 'Devel::Hide not installed' if $@;

plan tests => 2;

my ($result, $message) = parse_period('seven days ago');
cmp_ok(
    $result, '<', 0,
    'failure because of missing dependency',
);
is(
    $message,
    'Lingua::EN::Words2Nums not installed',
    'dependency missing message',
);
