package Custom::Log;

$VERSION = 0.01;

use strict;
use warnings;

=head1 NAME

B<Custom::Log> - Yes... Another OO-ish logging module.

=head1 SYNOPSIS

I<Object instatiation>

   use Custom::Log;

   my $log = Custom::Log->open (
       file => 'logs/my.log',
       mode => 'append',
   );

I<Basic logging>

   # Just like many other logging packages:
   $log->log('INFO', 'I can has info?');
   $log->log('ERROR', 'Oh crapz! Someone killed a kittah!');

I<Custom logging>

   # Call any log type you like as an object method. For 
   # example, if you are logging cache hits and misses you 
   # might want to do something like:
   if ($CACHE->{$key}) {
       $log->cache_hit("Got hit on key $key");
       return $CACHE->{$key};
   } else {
       $log->cache_miss("Awww... Key $key was a miss");
       $CACHE->{$key} = do_expensive_operation(@args);
   }

I<Other usage>

   # Use the object as a file handle for print() statements
   # from within your script or application:
   print {$$log} "This is a custom message. Pay attention!\n";

=head1 DESCRIPTION

Yet another darn logger? Why d00d?

Well...

I wanted to write a logging module that developers could use in a 
way that felt natural to them and it would just work. 

I wanted to write a logging module that was adaptable enough that
it could be used in dynamic, ever changing environments.

I wanted to write a logging module that was flexible enough to
satisfy most logging needs without too much overhead.

Custom::Log still has a ways to go, but the direction seems promising.
Comments and suggestions are always welcome. 

=head1 LOG FORMAT

Currently Custom::Log has only one format for the log entries which
looks like:

    TIME/DATE STAMP [LOG TYPE] LOG MESSAGE (CALLER INFO)

Eventually this module will have support for a user override of
the default format, as it should having a name like Custom::Log.

=head1 LOG TYPES

Log "type" refers to the string displayed in the square brackets 
of your log output. In the following example the type is 'BEER ERROR':

    Thu Nov  8 21:14:12 2007 [BEER ERROR] Need more (main foo.pl 99)

For those unfamiliar with logging this is especially useful when
grepping for specific types of errors, ala: 

    % grep -i ' beer error' /path/to/my.log

As stated above, there is no set list of types that this module 
supports... If you want to have a new type start showing up in 
your logs just call an object method of that name and Custom::Log 
will automatically do what you want: 

    $log->new_type('Hai!');

=cut

use Carp;

my $PKG  = __PACKAGE__;
my $MODE = '>>';  # By default we append

=head1 METHODS

=over 4

=item *

B<open()>

This is the object constructor. (Sure, you can still use new()
if you wish) B<open()> has two available parameters, each with
several allowed values. They are:

 * file [ file name | STDOUT | STDERR ]

    This parameter is REQUIRED.

 * mode [ append | clobber ]

    This parameter is OPTIONAL. The default value is 'append'.

Here is an example instantiation for logging to a file that 
you want to clobber:

    my $log = Custom::Log->open (
        file => '/path/to/logs/my.log',
        mode => 'clobber',
    );

Here is an example instantiation for logging to STDERR:

    my $log = Custom::Log->open (file => STDERR);

As you can see there is no need to quote STDERR and STDOUT, but
it will still work if you do decide to quote them.

=cut

sub open {
	my $class = shift;

	# Catch an object call
	$class = ref $class || $class;

	return bless _init({@_}), $class;
}

sub _init {
	my $args = shift;
	my $fh;

	unless ($args->{'file'}) {
		croak "$PKG: Must supply file: Custom::Log->open(file => 'foo')";
	}

	# Override append mode to clobber mode if requested
	if (defined $args->{'mode'} && $args->{'mode'} =~ m/^clobber$/) {
		$MODE = '>';
	}

	if ($args->{'file'} =~ /STD(?:OUT|ERR)/i) {
		$fh = $args->{'file'};
	} else {
		CORE::open $fh, $MODE, $args->{'file'}
			or croak "$PKG: Failed to open file '$args->{file}': $!";
	}

	return \$fh;
}

# For those of you that decide you want to use the standard 
# constructor notation of new(), here you go.
sub new { shift->open(@_) }

=item *

B<close()>

Close the file handle.

=cut

sub close { close ${(shift)} }

=item *

B<log()>

Your basic log subroutine. just give it the message type and 
the message body:

    $log->log('TYPE','MESSAGE');

Message types are discussed above.

=cut

sub log {
	my $fh   = shift;               # File handle reference
	my $type = uc shift || return;  # Message type, REQUIRED
	my $msg  = shift || return;     # Message body, REQUIRED
	my $time = scalar localtime;    # Formatted timestamp

	# Formatted caller info. Because custom types are essentially
	# wrapper functions for log() we need to check up one more
	# level to get the correct caller information. 
	my $call = join(' ', 
		map { 
			(caller(1))[$_]  # Called using $log->[custom type] 
				||           #      - OR -
			(caller(0))[$_]  # Called using $log->log
		} 0..2
	);

	# Turn off strict refs so that we can print to STDERR
	# and STDOUT witout perl spitting an error and dying.
	no strict 'refs';

	# Output formatted log entry
	print {$$fh} "$time [$type] $msg ($call)\n";
}

=item *

B<Custom Methods>

Log any type of message you want simply by calling the type as an
object method. For example, if you want to log a message with a 
type of ALARM you would do:

   $log->alarm('OONTZ!');

This would print a log entry that looks like:

   Thu Nov  8 21:14:12 2007 [ALARM] OONTZ! (main techno.pl 42)

This functionality was the impetus for writing this module.
What ever type you want to see in the log B<I<JUST USE IT!>> =)

=back

=cut

sub AUTOLOAD {
	my $log  = shift;
	my $type = (our $AUTOLOAD = $AUTOLOAD);

	return if $type =~ /::DESTROY$/;
	$type =~ s/.*::(.+)$/$1/;

	# Define a subroutine for our new type. Since this new
	# sub just turns around and calls log() with a set value
	# for the $type variable you can probably lable this a 
	# form of function currying. 
	{
		no strict;
		no warnings;
		*$type = sub { shift->log($type,@_) };
	}

	# Log with our new type
	$log->log($type,@_);
}

# Cleanup... Just close the file handle
sub DESTROY { shift->close }

1;

__END__

=head1 OTHER USAGE

While most OO modules bless a reference to a data structure, 
this module blesses a reference to an open file handle. Why 
did I do that? Because I can and I felt like doing something 
different. The only "special" thing this really lets you do 
is use the object as a file handle from within your script 
or application. All you have to do is dereference it when 
you use it. For example:

    # Normal log entry
    $log->info('This is information');

    # Special log entry
    print {$$log} "*** Hai. I am special. Pls give me attention! ***\n";

Obviously if you use the object in this special way you will not
get any of the nice additional information (timestamp, log type, 
and caller information) that you would get when using the normal 
way. This simply gives you the flexibility to print anything you 
want to your log. A useful example would be a dump of an object
or data structure: 

    use Data::Dumper;
    print {$$log} "Object dump:\n" . Dumper($object);

=head1 AUTHOR

James Conerly I<E<lt>jmc.dev.perl@gmail.comE<gt>> 2007

=head1 BUGS

None that I know of... yet =)

=head1 LICENSE

This software is free to use. If you use pieces of my code in your
scripts or applications all I ask is that you site me. Other than
that, log away my friends.

=head1 SEE ALSO

Carp

=cut
