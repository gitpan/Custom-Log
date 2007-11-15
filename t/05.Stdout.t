#!perl

use strict;
use warnings;

use Test::More;
use Custom::Log;

my $mod = 'IO::Capture::Stdout';
eval "use $mod";

my @types = qw/ foo bar baz /;

$@
	? plan skip_all => "Module '$mod' is not installed"
	: plan tests => scalar @types;
;

my $log = Custom::Log->open(file => 'STDOUT');
my $cap = new IO::Capture::Stdout;

$cap->start;
foreach my $type (@types) {
	$log->$type("Got type '$type'");
}
$cap->stop;

foreach my $type (@types) {
	isnt($cap->read =~ /$type/is, '', "Check STDOUT for type '$type'");
}

__END__
vim:set syntax=perl:
