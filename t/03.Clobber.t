#!perl

use strict;
use warnings;

use Test::More tests => 1;

use Custom::Log;

# Create file with some content
my $file = 'test.log';
open my $fh, '>', $file or die "$0: $!\n";
print {$fh} "OLD LINE\n";
close $fh;

# Create a Custom::Log log entry
my $log = Custom::Log->open(
	file => $file,
	mode => 'clobber',
);

$log->log('TEST','NEW LINE');
$log->close;

# Read our log to see if it contains both the old
# and the new entries.
open $fh, '<', $file or die "$0: $!\n";
my $text = join '', <$fh>;
close $fh;
is($text =~ /OLD.*NEW/s, '', 'Verify append mode');

unlink $file;

__END__
vim:set syntax=perl:
