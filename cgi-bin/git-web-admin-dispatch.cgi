#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/../lib";

use GitWebAdmin::Dispatch;
GitWebAdmin::Dispatch->dispatch();

