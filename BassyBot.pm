package BassyBot;

use strict;
use warnings;
use utf8;

use base qw(TwitterBot);
use Time::ParseDate;

$BassyBot::VERSION = '0.4pre';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->timer->add_target("12:00", sub {
		my $self = shift;
		$self->tweet("今日もバッシータイム開始！冷やしパーコ！");
	});
	$self->timer->add_target("15:00", sub {
		my $self = shift;
		$self->tweet("しょうもねぇーな！");
	});
	$self->timer->add_target("18:00", sub {
		my $self = shift;
		$self->tweet("一人で焼肉食いにいってくる。18000円だけどな！");
	});

	$self->logger->info("bassy-bot initialized.");

	return $self;
}

my @ACTIONS = (
	# print out message
	sub {
		my $self = shift;
		my $tweet = shift;
		$self->logger->info("Searching reaction for ". &_format_tweet($tweet));
		return ();
	},
	# ignore myself
	sub {
		my $self = shift;
		my $tweet = shift;
		return $tweet->{user}{id} eq $self->util->user->{id};
	},
	# ignore non-friend
	sub {
		my $self = shift;
		my $tweet = shift;
		my @friends = @{$self->util->friends_ids};
		$self->logger->debug("check if user:$tweet->{user}{id} is in friends-list(".join(",", @friends).")");
		return ! grep {$tweet->{user}{id} eq $_} @friends;
	},
	# RT
	sub {
		my $self = shift;
		my $tweet = shift;
		if ($tweet->{text} =~ /RT \@bassytime\:/) {
			$self->tweet("いってねーよバーカ！ RT \@$tweet->{user}{screen_name}: $tweet->{text}", $tweet->{id});
			return 1;
		}
		return ();
	},
	# 俺のVM
	sub {
		my $self = shift;
		my $tweet = shift;
		if ($tweet->{text} =~ /揺れた|ゆれた|地震|yrt/) {
			$self->tweet("俺のVM RT \@$tweet->{user}{screen_name}: $tweet->{text}", $tweet->{id});
			return 1;
		}
		return ();
	},
	# Reply
	sub {
		my $self = shift;
		my $tweet = shift;
		if ($tweet->{text} =~ /\@bassytime/) {
			$self->tweet("\@$tweet->{user}{screen_name} ホントしょうもねぇーな！", $tweet->{id});
			return 1;
		}
		return ();
	},
	# この厨二がっ！
	sub {
		my $self = shift;
		my $tweet = shift;
		if ($tweet->{text} =~ /unko|utm|ちん|チン/) {
			$self->tweet("\@$tweet->{user}{screen_name} この厨二がっ！", $tweet->{id});
			return 1;
		}
		return ();
	},
	# @riue(18943492)
	sub {
		my $self = shift;
		my $tweet = shift;
		if ($tweet->{user}{id} eq '18943492') {
			$self->tweet("\@$tweet->{user}{screen_name} しょうもねぇーな！", $tweet->{id});
			return 1;
		}
		return ();
	},
);

sub actions {
	return \@ACTIONS;
}

sub _format_tweet {
	my $tweet = shift;
	my $time = parsedate($tweet->{created_at});
	my $ago = time - $time;
	if ($ago < 60) {
		$ago = $ago . 's';
	} elsif ($ago < 60 * 60) {
		$ago = int($ago/60) . 'm';
	} else {
		$ago = int($ago/60/60) . 'h';
	}
	return "$ago ago: $tweet->{id} <$tweet->{user}{screen_name}/$tweet->{user}{id}> $tweet->{text}";
}

1;
