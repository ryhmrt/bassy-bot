package TwitterUtil;

use strict;
use warnings;
use utf8;

use Class::Accessor "antlers";
use Net::Twitter;

has 'username' => (isa => 'Str', is => 'ro');
has 'consumer_key' => (isa => 'Str', is => 'ro');
has 'consumer_secret' => (isa => 'Str', is => 'ro');
has 'token' => (isa => 'Str', is => 'ro');
has 'token_secret' => (isa => 'Str', is => 'ro');
has 'ssl' => (isa => 'Bool', is => 'ro');

sub new {
	my $class = shift;
	return $class->SUPER::new({@_});
}

sub twitter {
	my $self = shift;
	return $self->{'twitter'} ||= Net::Twitter->new(
		traits   => [qw/OAuth API::REST/],
		'consumer_key' => $self->consumer_key,
		'consumer_secret' => $self->consumer_secret,
		'access_token' => $self->token,
		'access_token_secret' => $self->token_secret,
		'ssl' => $self->ssl,
	) or die "can't create Net::Twitter";
}

sub user {
	my $self = shift;
	return $self->{'user'} ||= &_trap_twitter_error( sub{
		return $self->twitter->show_user($self->username);
	});
}

sub friends_ids {
	my $self = shift;
	return $self->{'friends_ids'} ||= &_trap_twitter_error( sub{
		$self->twitter->friends_ids($self->username);
	});
}

sub followers_ids {
	my $self = shift;
	return $self->{'followers_ids'} ||= &_trap_twitter_error( sub{
		$self->twitter->followers_ids($self->username);
	});
}

sub blocking_ids {
	my $self = shift;
	return $self->{'blocking_ids'} ||= &_trap_twitter_error( sub{
		$self->twitter->blocking_ids();
	});
}

sub _trap_twitter_error {
	my $sub = shift;
	my $result = $sub->();
	if ( my $err = $@ ) {
	    die $@ unless blessed $err && $err->isa('Net::Twitter::Error');
	
	    warn "HTTP Response Code: ", $err->code, "\n",
	         "HTTP Message......: ", $err->message, "\n",
	         "Twitter error.....: ", $err->error, "\n";
	}
	return $result;
}

sub refresh_friends_ids {
	my $self = shift;
	delete $self->{'friends_ids'};
}

sub refresh_followers_ids {
	my $self = shift;
	delete $self->{'followers_ids'};
}

sub refresh_blocking_ids {
	my $self = shift;
	delete $self->{'blocking_ids'};
}

sub create_friend {
	my $self = shift;
	my $id = shift;
	return &_trap_twitter_error( sub{
		$self->twitter->create_friend($id);
	});
}

sub tweet {
  my $self = shift;
  my $message = shift;
  my $in_reply_to_status_id = shift;
  my %new_status = (status => $message);
  $new_status{in_reply_to_status_id} = $in_reply_to_status_id if $in_reply_to_status_id;
  $self->twitter->update(\%new_status);
}

sub timeline {
	my $self = shift;
	my $opt = shift;
	my $statuses;
	return &_trap_twitter_error( sub{
		$self->twitter->home_timeline($opt);
	});
}


1;
