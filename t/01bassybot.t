#!/usr/bin/perl

use Test::More;# tests => ;

use strict;
use warnings;
use utf8;

use BassyBot;

my $mock_util = MockUtil->new();
{
	no strict 'refs';
	*{'TwitterBot::util'} = sub {
		return $mock_util;
	};
}

my $bot = BassyBot->new(username => 'uname', password => 'password');

$bot->reaction({
	id => 12345,
	status => 'msg',
	user => {
		screen_name => 'riue',
		id => '18943492',
	}
});
is($mock_util->{TWEET}, '@riue しょうもねぇーな！');
is($mock_util->{REFID}, '12345');

done_testing();

############################################################
package MockUtil;

sub new {
	return bless {}, shift;	
}

sub friends_ids {
	return [1,2,3,18943492];
}

sub user {
	return {
		id => 99,
		screen_name => 'myname'
		};	
}

sub tweet {
	my $self = shift;
	$self->{TWEET} = shift;
	$self->{REFID} = shift;
}