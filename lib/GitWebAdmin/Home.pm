package GitWebAdmin::Home;
use base 'GitWebAdmin';

use strict;
use warnings;

sub start {
  my $c = shift;

  my $db = $c->param('db');
  my $repos = $db->resultset('Repos')->search(
    { private => 0 }, { order_by => $c->query->param('sort_by') || 'name' });

  return $c->tt_process({ repos => $repos });
}

1;
