package TwitterBot;

use strict;
use warnings;

use Moose;
use AnyEvent::Twitter::Stream;
use TwitterUtil;
use PullTimer;

has 'username' => (isa => 'Str', is => 'ro', required => 1);
has 'password' => (isa => 'Str', is => 'ro', required => 1);
has 'ssl' => (isa => 'Bool', is => 'ro', default => 1);

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
		after => 0,
		interval => 10,
		cb => sub {
			for my $sub ($self->timer->pull) {
				$sub->($self);
			}
		},
	);

	$self->{_EVENTS} = [];
	push @{$self->{_EVENTS}}, $timer;
	push @{$self->{_EVENTS}}, $stream;
}

sub _build_twitter_util {
	my $self = shift;
	return TwitterUtil->new(
		username => $self->username,
		password => $self->password,
		ssl => $self->ssl,
	);
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
