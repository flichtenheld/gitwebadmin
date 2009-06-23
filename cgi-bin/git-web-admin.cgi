#!/usr/bin/perl

use strict;
use warnings;

use lib '/home/flichtenheld/git/git-web-admin/';
use GitWebAdmin;
my $webapp = GitWebAdmin->new();
$webapp->run();
