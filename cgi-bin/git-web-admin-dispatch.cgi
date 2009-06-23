#!/usr/bin/perl

use strict;
use warnings;

use lib '/home/flichtenheld/git/git-web-admin/lib';

use GitWebAdmin::Dispatch;
GitWebAdmin::Dispatch->dispatch();

