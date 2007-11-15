#!perl

use strict;
use warnings;

use Test::More tests => 2;

use Custom::Log;

my $file = 'test.log';
my $log  = Custom::Log->open(file => $file);
is(ref $log, 'Custom::Log', 'Check correct instantiation');
unlink $file;

eval { my $log = Custom::Log->open() };
isnt($@, undef, 'Check incorrect instantiation');

__END__
vim:set syntax=perl:
