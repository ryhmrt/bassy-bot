#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use PullTimer;

binmode STDOUT, ':encoding(utf8)';

*PullTimer::time = sub { return 0; };
my $timer = new PullTimer();
$timer->{'_LOCAL_DIFF'} = 0;
is($timer->{'_LAST_TIME'}, 0);

$timer->add_target('0:00', 'content of 0:00');
$timer->add_target('0:01', 'content of 0:01');
$timer->add_target('23:59', 'content of 23:59');
$timer->add_target('12:00', 'content of 12:00');

*PullTimer::time = sub { return 23*60*60 + 59*60; };
my @actions = sort $timer->pull();

is(scalar(@actions), 3);
is($actions[0], 'content of 0:01');
is($actions[1], 'content of 12:00');
is($actions[2], 'content of 23:59');

*PullTimer::time = sub { return 23*60*60 + 59*60; };
my @actions = sort $timer->pull();
is(scalar(@actions), 0);

*PullTimer::time = sub { return 60; };
my @actions = sort $timer->pull();
is(scalar(@actions), 2);
is($actions[0], 'content of 0:00');
is($actions[1], 'content of 0:01');

*PullTimer::time = sub { return 0; };
my @actions = sort $timer->pull();
is(scalar(@actions), 3);
is($actions[0], 'content of 0:00');
is($actions[1], 'content of 12:00');
is($actions[2], 'content of 23:59');
