package TwitterBot;

use strict;
use warnings;
use utf8;

use Class::Accessor "antlers";
use TwitterUtil;
use PullTimer;
use Log::Log4perl;

has 'username' => (isa => 'Str', is => 'ro');
has 'consumer_key' => (isa => 'Str', is => 'ro');
has 'consumer_secret' => (isa => 'Str', is => 'ro');
has 'token' => (isa => 'Str', is => 'ro');
has 'token_secret' => (isa => 'Str', is => 'ro');
has 'ssl' => (isa => 'Bool', is => 'ro');
has 'timer' => (isa => 'PullTimer', is => 'ro');
has 'util' => (isa => 'TwitterUtil', is => 'ro');
has 'logger' => (isa => 'Log::Log4perl', is => 'ro');
has 'last_status' => (is => 'rw');

sub new {
	my $class = shift;
	my %opt = @_;
	return $class->SUPER::new({
		'logger' => $opt{'logger'} || Log::Log4perl->get_logger($class),
		'timer' => $opt{'timer'} || PullTimer->new(),
		'util' => $opt{'util'} || TwitterUtil->new(@_),
	});
}

sub sleep {
	my $self = shift;
	sleep 30;
}

sub fetch {
	my $self = shift;
	my %opt;
	if ($self->last_status()) {
		$opt{'since_id'} = $self->last_status()->{id};
		$opt{'count'} = 100;
		$self->logger->debug("since_id: $opt{'since_id'}.");
	} else {
		$opt{'count'} = 1;
		$self->logger->debug("no since_id.");
	}
	my $statuses = $self->util->timeline(\%opt);
	$self->last_status($statuses->[0]) if $statuses and @$statuses;
	return $statuses;
}

sub start {
	my $self = shift;
	$self->update_friends();
	$self->fetch() or die "first fetch failed.\n";
	for (;;) {
		for my $timer_action ($self->timer->pull()) {
			$timer_action->($self);
		}
		my $statuses = $self->fetch();
		if ($statuses) {
			$self->logger->info(scalar(@$statuses) . ' statuses.');
			for my $status ( reverse @$statuses ) {
				$self->reaction($status);
			}
		}
		$self->sleep;
	}
}

sub reaction {
	my $self = shift;
	my $status = shift;
	for my $action (@{$self->actions()}) {
		last if $action->($self, $status);
	}
}

# each action methods will called with status object
# the action method should return true if you want to block other action methods
sub actions {
	die "plz override actions method! it should return action array-ref\n";
}

sub not_following_followers_ids {
	my $self = shift;
	return grep {
		my $id = $_;
		! grep {$_ eq $id} @{$self->util->friends_ids}, @{$self->util->blocking_ids};
	} @{$self->util->followers_ids};
}

sub update_friends {
	my $self = shift;
	$self->util->refresh_friends_ids;
	$self->util->refresh_followers_ids;
	$self->util->refresh_blocking_ids;
	for my $friend_id ($self->not_following_followers_ids) {
		my $user = $self->util->create_friend($friend_id);
		$self->logger->info("new friend <$user->{screen_name}/$user->{id}> added.");
	}
	$self->util->refresh_friends_ids;
}

sub tweet {
	my $self = shift;
	$self->logger->info("> $_[0]".($_[1] ? " in_reply_to_status_id => $_[1]" : ""));
	$self->util->tweet(@_);
}

1;
