#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Custom::Log',
    'VERSION_FROM' => 'lib/Custom/Log.pm',
    'ABSTRACT'     => 'OO-ish customizable logging',
    'AUTHOR'       => 'James Conerly <jmc.dev.perl@gmail.com>',
);

__END__
