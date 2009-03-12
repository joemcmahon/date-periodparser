package Date::PeriodParser;
use Lingua::EN::Words2Nums;
use 5.006;
use strict;
use warnings;
use Time::Local;
use Date::Calc;

use constant GIBBERISH => -1;
use constant AMBIGUOUS => -2;

# Boring administrative details
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( parse_period	) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( parse_period);
our $VERSION = '0.03';

$Date::PeriodParser::DEBUG = 0;

our $TestTime; # This is set by test.pl so we don't have to be dynamic

my $roughly = qr/((?:a?round(?: about)?|about|roughly|circa|sometime)\s*)+/;

sub debug {
    print STDERR "# @_\n" if $Date::PeriodParser::DEBUG;
}

sub parse_period {
    local $_ = lc shift; # Since we're doing lots of regexps on it.
    my $now = $TestTime || time;
    my ($s, $m, $h, $day, $mon, $year) = (localtime $now)[0..5];

    # Tidy slightly.
    s/^\s+//;s/\s+$//;
    return (GIBBERISH, "You didn't supply an argument.") unless $_;

    # We're trying to find two things: from and to.
    # We also want to keep track of how vague the user's being, so we
    # provide a flexibility score - for instance "about two weeks ago"
    # means maybe three days either side, but "around last September"
    # means perhaps twelve days either side. 
    my ($from, $to, $leeway);
    my $vague = s/^$roughly\s*//;
    debug("this is a vague time");
    
    # Stupid cases first.
    # "now": precisely now, or +/- 5 minutes if vague
    return apply_leeway($now, $now, 300 * $vague) 
        if /^now$/;

    if ($_ eq "" and $vague) { # Biggest range possible.
        $from = 0; $to = 2**31-1;
        return ($from, $to);
    }

    # Recent times
    if (/(the day (before|after) )?(yesterday|today|tomorrow)/ ||
	/^this (morning|afternoon|evening|lunchtime)/   ||
	/^at lunchtime$/ ||
	/^(in the) (morning|afternoon|evening)/ ||
	/^(last |to)night/) {

        if (s/the day (before|after)//) {
            my $wind = $1 eq "before" ? -1 : 1;
            debug("Modifying day by $wind");
            $day += $wind;
        }
        if (/yesterday/)   { $day--; debug("Back 1 day") }
        elsif (/tomorrow/) { $day++; debug("Forward 1 day") }
	# if it's later than the morning and the phrase is "in the morning", add a day.
	if ($h>12 and /in the morning$/) {$day++}
	# if it's later than the afternoon and the phrase is "in the afternoon",
	# add a day.
	elsif ($h>18 and /in the afternoon$/) {$day++}
	# if it's nighttime, and the phrase is "in the evening", add a day.
	elsif (($h>21 or $h<6) and /in the evening$/) {$day++}
        $day-- if /last/;
        ($from, $to, $leeway) = period_or_all_day($day, $mon, $year, $now);
        return apply_leeway($from, $to, $leeway * $vague);
    }

    # "ago" and "from now" are both pretty limited: only an offset in
    # days is currently supported.
    s/a week/seven days/g;
    if (/^(.*) day(?:s)? ago$/ || /^in (.*) day(?:s)?(?: time)$/ || 
        /^(.*) days (?:away)?\s*(?:from now)?$/) {
        my $days = $1;
	{
	  local $_; 
          # This trashes $_
	  $days = words2nums($days);
	}
        if (defined $days) { 
            $days *= -1 if /ago/;
            debug("Modifying day by $days");
            $day += $days;
            ($from, $to, $leeway) = 
	      period_or_all_day($day, $mon, $year, $now);
            return apply_leeway($from, $to, $leeway * $vague);
        }
     }

    if (!$from and !$to) {
        return (GIBBERISH, "I couldn't parse that at all.");
    }
}

my %points_of_day = (
    morning   => [
                    [0, 0, 0],
                    [12, 0, 0]
                 ],
    lunchtime => [
                    [12, 0, 0],
                    [13,30, 0]
                 ],
    afternoon => [
                    [13,30, 0], # "It is not afternoon until a gentleman
                    [18, 0, 0]  # has had his luncheon."
                 ],
    evening   => [
                    [18, 0, 0], # Regardless of what Mediterraneans think
                    [23,59,59]
                 ],
    day       => [
                    [0, 0, 0],
                    [23,59,59],
                 ]
);

sub apply_point_of_day {
    my ($d, $m, $y, $point) = @_;
    my ($from, $to); 
    if ($point eq "night") { # Special case
        $from = timelocal(0,0,21,$d,$m,$y);
        $to   = timelocal(59,59,5,$d+1,$m,$y);
    } else {
        my $spec = $points_of_day{$point};
        my @from = (reverse(@{$spec->[0]}),$d,$m,$y);
        my @to   = (reverse(@{$spec->[1]}),$d,$m,$y);
        $from = timelocal(@from);
        $to   = timelocal(@to);
    }
    return ($from, $to);
}

sub period_or_all_day {
    my $point;
    my ($day, $mon, $year, $now) = @_;
    my $leeway;

    if (/(morning|afternoon|evening|lunchtime|night)/) {
        $leeway = 60*60*2;
        $point = $1;
    } else {
        # To determine the leeway, consider how many days ago this was;
        # we want to be more specific about recent events than ancient
        # ones.
        my $was = timelocal(0,0,0, $day, $mon, $year);
        my $days_ago = int(($now-$was)/(60*60*24))+1;
        $leeway = 60*60*3*$days_ago;
        # Up to a maximum of five days
        $leeway > 24*60*60*5 and $leeway = 24*60*60*5;
        debug("Wanted around $days_ago, allowing $leeway either side");
        $point = "day";
    }
    return (apply_point_of_day($day, $mon, $year, $point), $leeway);
}

sub apply_leeway {
    my ($from, $to, $leeway) = @_;
    $from -= $leeway; $to += $leeway;
    return ($from, $to);
}

1;
__END__

=head1 NAME

Date::PeriodParser - Turns English descriptions into time periods

=head1 SYNOPSIS

  use Date::PeriodParser;
  my ($midnight, $midday) = parse_period("this morning");
  my ($monday_am, $sunday_pm) = parse_period("this week");
  ... parse_period("sometime this afternoon");
  ... parse_period("around two weeks ago");


=head1 DESCRIPTION

The subroutine C<parse_period> attempts to turn the English description
of a time period into a pair of Unix epoch times. As a famous man once
said, "Of course, this is a heuristic, which is a fancy way of saying
that it doesn't work".

=head1 WHAT'S CURRENTLY SUPPORTED

=over 4

=item * sometime

Returns full range of dates from the epoch to the latest-possible date
(currently "Mon Jan 18 19:14:07 2038").

=item * now

Returns the current date and time.

=item * today, tomorrow, yesterday

Supported, with "the day before" and "the day after" accepted as modifiers.
This means you can say relatively meaningless things like "the day after
yesterday" and "the day before tomorrow", but they work.

=item * day, morning, lunchtime, afternoon, evening, night

These are all supported with "this" and "in the" as modifiers;
relative times specified with "in the" (for morning, afternoon, and evening)
disambiguate relative to the current time. For instance, if it's afternoon
and "in the morning" is specified, this implies "tomorrow morning".

=item * "ago" and "from now"

Offsets in days and "a week" are accepted; you cannot cross a month
boundary in this release.

=item * "in I<xxx> day(s)" and "in I<xxx> days time"

Offsets in days are supported; again, crossing month boundaries does not
yet work.

=back

If you enter something it can't parse, it'll return an error code and an
explanation instead of two epoch time values. Error code -1 means "You
entered gibberish", error code -2 means "you entered something
ambiguous", and the explanation will tell you how to disambiguate it.

=head1 BUGS

Parsing is limited. Some relatively complicated things work fine, but some
simple things do not.

=over 4 

=item * Supports only a number of days "ago" or "from now". Should be expanded 
to handle weeks, months, and years as well. 

=item * The time-of-day words ("morning", "afternoon", "evening", "night", and 
"lunchtime") should accept relative modifiers (e.g., "lunchtime tomorrow", 
"yesterday evening"), but don't.

=item * Day offsets carrying the day of the month over a valid limit 
cause an internal error in localtime(). This is the biggest bug at present
and will be addressed in the next release.

=back

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>
Joe McMahon, C<mcmahon@cpan.org>

=head1 LEGAL

Copyright (C) 2002 by Simon Cozens; Copyright (c) 2005 by Joe McMahon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
