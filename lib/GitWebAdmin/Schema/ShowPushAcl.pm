package GitWebAdmin::Schema::ShowPushAcl;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

GitWebAdmin::Schema::ShowPushAcl

=cut

__PACKAGE__->table("show_push_acl");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 1

=head2 priority

  data_type: 'integer'
  is_nullable: 1

=head2 user

  data_type: 'integer'
  is_nullable: 1

=head2 group

  data_type: 'text'
  is_nullable: 1

=head2 repository

  data_type: 'text'
  is_nullable: 1

=head2 user_flags

  data_type: 'text'
  is_nullable: 1

=head2 repo_flags

  data_type: 'text'
  is_nullable: 1

=head2 ref

  data_type: 'text'
  is_nullable: 1

=head2 action

  data_type: 'enum'
  extra: {custom_type_name => "push_action_type",list => ["create","update","replace","delete"]}
  is_nullable: 1

=head2 result

  data_type: 'enum'
  extra: {custom_type_name => "acl_result_type",list => ["allow","deny"]}
  is_nullable: 1

=head2 comment

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 1 },
  "priority",
  { data_type => "integer", is_nullable => 1 },
  "user",
  { data_type => "integer", is_nullable => 1 },
  "group",
  { data_type => "text", is_nullable => 1 },
  "repository",
  { data_type => "text", is_nullable => 1 },
  "user_flags",
  { data_type => "text", is_nullable => 1 },
  "repo_flags",
  { data_type => "text", is_nullable => 1 },
  "ref",
  { data_type => "text", is_nullable => 1 },
  "action",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "push_action_type",
      list => ["create", "update", "replace", "delete"],
    },
    is_nullable => 1,
  },
  "result",
  {
    data_type => "enum",
    extra => { custom_type_name => "acl_result_type", list => ["allow", "deny"] },
    is_nullable => 1,
  },
  "comment",
  { data_type => "text", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-11-10 18:32:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tIvyl7Ryb3FghInjcdD2SQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
