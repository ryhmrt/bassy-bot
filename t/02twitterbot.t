#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More 'no_plan';
use TwitterBot;
use Test::MockObject;

binmode STDOUT, ':encoding(utf8)';

############################################################
# test updating friends
{
	my @friends;
	my $friends_ids_refreshed;
	my $followers_ids_refreshed;
	my $bot = TwitterBot->new(
		username => 'uname',
		password => 'password',
		util => (sub {
			my $mock = Test::MockObject->new();
			$mock->set_isa('TwitterUtil');
			$mock->mock(user => sub {
				return {
					id => 99,
					screen_name => 'myname'
				};
			});
			$mock->mock(friends_ids => sub {
				return [1,2,3,18943492];
			});
			$mock->mock(followers_ids => sub {
				return [1,2,3,4,5,6,18943492];
			});
			$mock->mock(create_friend => sub {
				push @friends, $_[1];
				return {
					id => $_[1],
					screen_name => "foobar",
				};
			});
			$mock->mock(refresh_friends_ids => sub {
				$friends_ids_refreshed = 1;
			});
			$mock->mock(refresh_followers_ids => sub {
				$followers_ids_refreshed = 1;
			});
			return $mock;
		})->(),
		actions => [],
	);
	$bot->update_friends;
	is_deeply(\@friends, [4,5,6], "update friends");
	ok($friends_ids_refreshed, "refreshing friends_ids");
	ok($followers_ids_refreshed, "refreshing followers_ids");
}
