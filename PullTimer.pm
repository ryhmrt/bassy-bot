package PullTimer;

use strict;
use warnings;

sub new {
  my $class = shift;
  my @local_epoch = localtime(0);
  my $self = bless {
    '_LOCAL_DIFF' => $local_epoch[0] + $local_epoch[1]*60 + $local_epoch[2]*60*60,
    '_TARGETS' => {}
  }, $class;
  $self->{_LAST_TIME} = $self->time();
  return $self;
}

sub time {
  my $self = shift;
  return (time() + $self->{_LOCAL_DIFF}) % (24*60*60);
}

sub add_target {
  my $self = shift;
  my $time = shift;
  my $content = shift;
  my ($h, $m) = split(/\:/, $time);
  $self->{_TARGETS}{$h*60*60 + $m*60} = $content;
#  print "timer updated: ", %{$self->{_TARGETS}}, "\n";
}

sub pull {
  my $self = shift;
  my $time = $self->time();
  my $last_time = $self->{_LAST_TIME};
#  print "search timer between $last_time and $time\n";
  my @current_times = grep {
      ($_ > $last_time and $_ <= $time)
      or ($time < $last_time and $_ > $last_time)
      or ($time < $last_time and $_ <= $time)
    } keys %{$self->{_TARGETS}};
#  print "result :", join(",", @current_times), "\n";
  $self->{_LAST_TIME} = $time;
  return map { $self->{_TARGETS}{$_} } @current_times;
}

1;
