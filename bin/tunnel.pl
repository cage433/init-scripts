#!/usr/bin/perl 

use strict;
use warnings;

sub check_command_running
{
  my ($command) = @_;

  print("$command\n");

  # 1. Execute ssh command if it's not currently running
  `pgrep -f -x \"$command\" 2>&1`;
  if ($? != 0)
  {
    print "no tunnel exists - opening one\n";
    system($command);
    if ($? != 0){
      die("Can't open tunnel - exiting");
    }
  } else {
    print("Tunnel up locally\n");
  }
}


sub check_reverse_tunnel
{
  my ($line) = @_;
  my ($from_port, $to_host, $to_port) = split(/ /, $line);

  my $command="ssh -f -q -N -R $from_port:$to_host:$to_port traftunnel";

  check_command_running($command);

  my $num_tries=5;
  while ($num_tries > 0){
    my @result = `ssh -Tn traftunnel`;
    foreach (@result){
      if ($_ =~ /tcp.*$from_port.*LISTEN/) {
        print("Tunnel up remotely\n");
        return 0;
      }
    }
    sleep 1;
    print "Can't find tunnel remotely - will try again\n";
    $num_tries -= 1;
  }

  print "Killing tunnel\n";
  system("pkill",  "-f", "-x", $command);
  if ($? != 0){
    die("Couldn't kill tunnel");
  }

  print "Opening new tunnel after killing\n";
  system($command);
  if ($? != 0){
    die("Couldn't open tunnel");
  }
}

my $file = $ENV{"HOME"} . '/.tunnels';
open my $info, $file or die "Could not open $file: $!";

print("\n" . `date`);
while(<$info>)  {   
  chomp;
  if ( $_ =~ /^#/ || $_ !~ /./){
    # a comment or whitespace - ignore
    next
  } 

  if ($_ =~ /^ssh /){
    check_command_running($_);
  } else { 
    check_reverse_tunnel($_);
  }
  print("\n");
}
