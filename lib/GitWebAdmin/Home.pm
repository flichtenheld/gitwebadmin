package GitWebAdmin::Home;
use base 'GitWebAdmin';

use strict;
use warnings;

sub start {
  my $c = shift;

  my $db = $c->param('db');
  my $repos = $db->resultset('ActiveRepos')->search(
    { private => 0 }, { order_by => $c->query->param('sort_by') || 'name' });
  my $groups = $db->resultset('Groups');
  my $users = $db->resultset('Users');

  return $c->tt_process({ repos => $repos,
                          groups => $groups,
                          users => $users });
}

1;
