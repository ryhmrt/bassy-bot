#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use TwitterUtil;
use Test::MockObject;

binmode STDOUT, ':encoding(utf8)';

############################################################
# test refreshing attributes
{
	my $friends_ids_call_count = 0;
	my $followers_ids_call_count = 0;
	my $blocking_ids_call_count = 0;
	my $util = TwitterUtil->new(
		username => 'uname',
		password => 'password',
		ssl => 1,
		twitter => (sub {
			my $mock = Test::MockObject->new();
			$mock->set_isa('Net::Twitter');
			$mock->mock(show_user => sub {
				return {
					id => 99,
					screen_name => 'myname'
				};
			});
			$mock->mock(friends_ids => sub {
				$friends_ids_call_count++;
				return [1,2,3,18943492];
			});
			$mock->mock(followers_ids => sub {
				$followers_ids_call_count++;
				return [1,2,3,4,5,6,7,8,18943492];
			});
			$mock->mock(blocking_ids => sub {
				$blocking_ids_call_count++;
				return [4,8];
			});
			return $mock;
		})->(),
	);

	$util->friends_ids();
	$util->friends_ids();
	is($friends_ids_call_count, 1);
	$util->refresh_friends_ids();
	$util->friends_ids();
	is($friends_ids_call_count, 2);

	$util->followers_ids();
	$util->followers_ids();
	is($followers_ids_call_count, 1);
	$util->refresh_followers_ids();
	$util->followers_ids();
	is($followers_ids_call_count, 2);

	$util->blocking_ids();
	$util->blocking_ids();
	is($blocking_ids_call_count, 1);
	$util->refresh_blocking_ids();
	$util->blocking_ids();
	is($blocking_ids_call_count, 2);
}
