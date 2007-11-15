#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

Module::Build->new (
	module_name       => 'Custom::Log',
	license           => 'perl',
	dist_author       => 'James Conerly',
	dist_version_from => 'lib/Custom/Log.pm',
	requires          => { 'Carp' => 0 },
)->create_build_script;

__END__
