#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';

use BassyBot;
use Test::MockObject;

binmode STDOUT, ':encoding(utf8)';

my $bot = BassyBotTest->new(username => 'uname', password => 'password');

$bot->reaction({
	id => 12345,
	status => 'msg',
	created_at => '2009/9/12 18:02:00',
	text => 'くだらない話',
	user => {
		screen_name => 'riue',
		id => '18943492',
	}
});
is($bot->util->{TWEET}, '@riue しょうもねぇーな！');
is($bot->util->{REFID}, '12345');

############################################################
BEGIN {
	package BassyBotTest;

	use Moose;
	extends 'BassyBot';
	use Test::MockObject;

	sub _build_twitter_util {
		my $mock = Test::MockObject->new();
		$mock->set_isa('TwitterUtil');
		$mock->mock(friends_ids => sub {
			return [1,2,3,18943492];
		});
		$mock->mock(user => sub {
			return {
				id => 99,
				screen_name => 'myname'
				};
		});
		$mock->mock(tweet => sub {
			my $self = shift;
			$self->{TWEET} = shift;
			$self->{REFID} = shift;
		});
		return $mock;
	}
}
