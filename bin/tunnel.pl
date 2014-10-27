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

my $file = $ENV{"HOME"} . '/.tunnels';
open my $info, $file or die "Could not open $file: $!";

print("\n" . `date`);
while(<$info>)  {   
  chomp;
  if ( $_ =~ /^#/ || $_ !~ /./){
    # a comment or whitespace - ignore
    next
  } 

  check_command_running($_);
  print("\n");
}
