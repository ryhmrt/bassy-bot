#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';

use BassyBot;
use Test::MockObject;
use Log::Log4perl;

Log::Log4perl->init("bassy-bot-logger.conf");

binmode STDOUT, ':encoding(utf8)';

############################################################
{
	my $bot = BassyBot->new(
		'username' => 'uname',
		'consumer_key' => 'ck',
		'consumer_secret' => 'cs',
		'token' => 'tk',
		'token_secret' => 'ts',
		'util' => sub {
			my $mock = Test::MockObject->new();
			$mock->set_isa('TwitterUtil');
			$mock->mock('friends_ids' => sub {
				return [1,2,3,18943492];
			});
			$mock->mock('user' => sub {
				return {
					'id' => 99,
					'screen_name' => 'myname'
				};
			});
			$mock->mock('tweet' => sub {
				my $self = shift;
				$self->{TWEET} = shift;
				$self->{REFID} = shift;
			});
			return $mock;
		}->(),
	);
	
# test reaction for @riue's tweet
#	$bot->reaction({
#		'id' => 12345,
#		'status' => 'msg',
#		'created_at' => '2009/9/12 18:02:00',
#		'text' => 'くだらない話',
#		'user' => {
#			'screen_name' => 'riue',
#			'id' => '18943492',
#		}
#	});
#
#	is($bot->util->{TWEET}, '@riue しょうもねぇーな！ #bassytime');
#	is($bot->util->{REFID}, '12345');

	$bot->reaction({
		'id' => 6789,
		'status' => 'msg',
		'created_at' => '2009/9/12 18:02:00',
		'text' => 'わかめ野郎',
		'user' => {
			'screen_name' => 'riue',
			'id' => '18943492',
		}
	});

	is($bot->util->{TWEET}, 'わかめじゃねーよ！！ RT @riue: わかめ野郎 #bassytime');
	is($bot->util->{REFID}, '6789');

	$bot->reaction({
		'id' => 123,
		'status' => 'msg',
		'created_at' => '2009/9/12 18:02:00',
		'text' => 'おちん○',
		'user' => {
			'screen_name' => 'foo',
			'id' => '1',
		}
	});

	is($bot->util->{TWEET}, '@foo この厨二がっ！ #bassytime');
	is($bot->util->{REFID}, 123);

	$bot->util->{TWEET} = undef;
	$bot->util->{REFID} = undef;
	$bot->reaction({
		'id' => 6789,
		'status' => 'msg',
		'created_at' => '2009/9/12 18:02:00',
		'text' => 'きちんと',
		'user' => {
			'screen_name' => 'foo',
			'id' => '1',
		}
	});

	is($bot->util->{TWEET}, undef);
	is($bot->util->{REFID}, undef);

	$bot->reaction({
		'id' => 6789,
		'retweeted_status' => {},
		'status' => 'msg',
		'created_at' => '2009/9/12 18:02:00',
		'text' => 'junko',
		'user' => {
			'screen_name' => 'foo',
			'id' => '1',
		}
	});

	is($bot->util->{TWEET}, undef);
	is($bot->util->{REFID}, undef);
}
