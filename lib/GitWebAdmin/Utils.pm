#
#  Copyright (C) 2009 Astaro AG  www.astaro.com
#  All rights reserved.
#
#  Author: Frank Lichtenheld <flichtenheld@astaro.com> 28.08.2009
#
##############################################################################
package GitWebAdmin::Utils;

use strict;
use warnings;

use File::Temp qw(tempfile);
use File::Slurp;

sub check_key {
  my ($key) = @_;

  my ($fh, $fname) = tempfile();
  write_file($fh, \$key)
    or die "500 Error during key check\n";
  open my $out, '-|', qw(ssh-keygen -l -f), $fname
    or die "500 Error during key check\n";
  my $line = <$out>;
  close $out or return;
  if( $line =~ /^(\d+) ((?:[0-9a-f]{2}:){15}[0-9a-f]{2}) \Q$fname\E \(([DR]SA)\)$/ ){
    return ($1, $2, $3);
  }
  return;
}

1;
