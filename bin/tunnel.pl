#!/usr/bin/perl 

use strict;
use warnings;


sub connect2
{
  my ($line) = @_;
  my ($remote_host, $remote_port, $local_host, $local_port) = split(/ /, $line);

  my $command="ssh -f -q -N -R $remote_port:$local_host:$local_port alex\@$remote_host";

  print `date`;
  print("$command\n");

  `pgrep -f -x \"$command\" 2>&1`;
  if ($? != 0)
  {
    print "no tunnel exists - opening one\n";
    system($command);
    if ($? != 0){
      die("Can't open tunnel - exiting");
    }
  } else {
    print("Tunnel up\n");
  }

  # 2. Test tunnel by looking at "netstat" output on $remote_host
  my $num_tries=5;
  while ($num_tries > 0){
    my @result = `ssh -p 443 alex\@$remote_host netstat -an`;
    foreach (@result){
      if ($_ =~ /tcp.*$remote_port.*LISTEN/) {
        print("Tunnel up on remote side\n");
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

while(<$info>)  {   
  chomp;
  connect2($_);
}
