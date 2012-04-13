package GitWebAdmin::Schema::Mirrors;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

GitWebAdmin::Schema::Mirrors

=cut

__PACKAGE__->table("mirrors");

=head1 ACCESSORS

=head2 repo

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 enabled

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 mirrorof

  data_type: 'text'
  is_nullable: 1

=head2 mirrorupd

  data_type: 'integer'
  default_value: 86400
  is_nullable: 1

=head2 last_check

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 last_updated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 last_error

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 last_error_change

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "repo",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "enabled",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "mirrorof",
  { data_type => "text", is_nullable => 1 },
  "mirrorupd",
  { data_type => "integer", default_value => 86400, is_nullable => 1 },
  "last_check",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "last_updated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "last_error",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "last_error_change",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("repo");

=head1 RELATIONS

=head2 repo

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("repo", "GitWebAdmin::Schema::Repos", { id => "repo" });


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-04-11 14:18:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5kWSA0Xl4x1nHtAMyU34xA

#"}};

use Class::Method::Modifiers;

my $now = 'NOW()';
around last_error => sub {
  my ($orig, $self) = (shift, shift);

  if (@_) {
    my $value = $_[0];
    my $orig_value = $self->$orig() || '';
    if( $orig_value ne $value ){
      $self->last_error_change(\$now);
    }
  }
  $self->$orig(@_);
};

# You can replace this text with custom content, and it will be preserved on regeneration
1;
