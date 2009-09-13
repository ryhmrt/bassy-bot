package TwitterBot;

use strict;
use warnings;

use Moose;
use AnyEvent::Twitter::Stream;
use TwitterUtil;
use PullTimer;
use Log::Log4perl;

has 'username' => (isa => 'Str', is => 'ro', required => 1);
has 'password' => (isa => 'Str', is => 'ro', required => 1);
has 'ssl' => (isa => 'Bool', is => 'ro', default => 1);
has 'auto_update_friends_interval' => (isa => 'Int', is => 'ro', default => 60*60*24);

has 'util' => (
	isa => 'TwitterUtil',
	is => 'ro',
	lazy => 1,
	builder => '_build_twitter_util',
);

has 'timer' => (
	isa => 'PullTimer',
	is => 'ro',
	builder => '_build_timer',
);

has 'actions' => (
	isa => 'ArrayRef',
	is => 'ro',
	builder => '_build_actions',
);

has 'logger' => (
	isa => 'Log::Log4perl::Logger',
	is => 'ro',
	lazy => 1,
	builder => '_build_logger',
);

sub BUILD {
	my $self = shift;
	
	my $done = AnyEvent->condvar;
	$self->{_CV} = $done;

	my $stream = AnyEvent::Twitter::Stream->new(
		username => $self->username,
		password => $self->password,
		method   => 'filter',
		follow   => join(',', $self->following_ids),
		on_tweet => sub {
			my $tweet = shift;
			$self->reaction($tweet);
		},
		on_error => sub {
			my $error = shift;
			warn "ERROR: $error";
			$done->send;
		},
		on_eof   => sub {
			$done->send;
		},
	);
	
	my $timer = AnyEvent->timer(
		after => 10,
		interval => 10,
		cb => sub {
			for my $sub ($self->timer->pull) {
				$sub->($self);
			}
		},
	);

	my $friends_updater = AnyEvent->timer(
		after => 0,
		interval => $self->auto_update_friends_interval,
		cb => sub {
			$self->update_friends;
		},
	);

	$self->{_EVENTS} = [];
	push @{$self->{_EVENTS}}, $timer;
	push @{$self->{_EVENTS}}, $stream;
	push @{$self->{_EVENTS}}, $friends_updater;
}

sub _build_twitter_util {
	my $self = shift;
	return TwitterUtil->new(
		username => $self->username,
		password => $self->password,
		ssl => $self->ssl,
	);
}

sub _build_logger {
	my $self = shift;
	return Log::Log4perl->get_logger(ref $self);
}

sub _build_timer {
	return PullTimer->new();	
}

sub _build_actions {
	die "override _build_actions method!";
}

sub start {
	my $self = shift;
	$self->{_CV}->recv;
}

sub following_ids {
	my $self = shift;
	return $self->util->user->{id}, @{$self->util->friends_ids};
}

sub not_following_followers_ids {
	my $self = shift;
	return grep {
		my $id = $_;
		! grep {$_ eq $id} @{$self->util->friends_ids} ;
	} @{$self->util->followers_ids};
}

sub update_friends {
	my $self = shift;
	$self->util->refresh_friends_ids;
	$self->util->refresh_followers_ids;
	for my $friend_id ($self->not_following_followers_ids) {
		my $user = $self->util->create_friend($friend_id);
		$self->logger->info("new friend <$user->{screen_name}/$user->{id}> added.");
	}
	$self->util->refresh_friends_ids;
}

sub reaction {
  my $self = shift;
  my $tweet = shift;
  for my $action (@{$self->actions}) {
    last if $action->($self, $tweet);
  }
}

no Moose;
__PACKAGE__->meta->make_immutable();

1;
