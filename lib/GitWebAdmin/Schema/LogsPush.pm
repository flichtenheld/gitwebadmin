package GitWebAdmin::Schema::LogsPush;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

GitWebAdmin::Schema::LogsPush

=cut

__PACKAGE__->table("logs_push");

=head1 ACCESSORS

=head2 rid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 old_id

  data_type: 'text'
  is_nullable: 0

=head2 new_id

  data_type: 'text'
  is_nullable: 0

=head2 ref

  data_type: 'text'
  is_nullable: 0

=head2 notified

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 logid

  data_type: 'bigint'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'logs_push_logid_seq'

=head2 uid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "rid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "old_id",
  { data_type => "text", is_nullable => 0 },
  "new_id",
  { data_type => "text", is_nullable => 0 },
  "ref",
  { data_type => "text", is_nullable => 0 },
  "notified",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "logid",
  {
    data_type         => "bigint",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "logs_push_logid_seq",
  },
  "uid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("logid");

=head1 RELATIONS

=head2 rid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Repos>

=cut

__PACKAGE__->belongs_to("rid", "GitWebAdmin::Schema::Repos", { id => "rid" });

=head2 uid

Type: belongs_to

Related object: L<GitWebAdmin::Schema::Users>

=cut

__PACKAGE__->belongs_to("uid", "GitWebAdmin::Schema::Users", { id => "uid" });


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2012-03-31 15:57:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1+cpEfVmU4F/Zt8TBODelA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
