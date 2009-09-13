package TwitterUtil;

use strict;
use warnings;

use Moose;
use Net::Twitter;

has 'username' => (isa => 'Str', is => 'ro', required => 1);
has 'password' => (isa => 'Str', is => 'ro', required => 1);
has 'ssl' => (isa => 'Bool', is => 'ro', default => 1);

has 'twitter' => (
	isa => 'Net::Twitter',
	is => 'ro',
	lazy => 1,
	builder => '_build_net_twitter',
);

has 'user' => (
	isa => 'HashRef',
	is => 'ro',
	lazy => 1,
	builder => '_retrieve_myself',
);

has 'friends_ids' => (
	isa => 'ArrayRef',
	is => 'rw',
	lazy => 1,
	builder => '_retrieve_friends_ids',
);

sub _build_net_twitter {
	my $self = shift;
	return Net::Twitter->new(
		traits   => [qw/API::REST/],
		username => $self->username,
		password => $self->password,
		ssl => $self->ssl,
	) or die "can't create Net::Twitter";
}

sub _retrieve_myself {
	my $self = shift;
	return &_trap_twitter_error( sub{
		return $self->twitter->show_user($self->username);
	});
}

sub _retrieve_friends_ids {
	my $self = shift;
	return &_trap_twitter_error( sub{
		$self->twitter->friends_ids($self->username);
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

sub refresh {
	my $self = shift;
	$self->friends_ids($self->_retrieve_friends_ids());
}

sub tweet {
  my $self = shift;
  my $message = shift;
  my $in_reply_to_status_id = shift;
  my %new_status = (status => $message);
  $new_status{in_reply_to_status_id} = $in_reply_to_status_id if $in_reply_to_status_id;
  $self->twitter->update(\%new_status);
}

no Moose;
__PACKAGE__->meta->make_immutable();

1;
