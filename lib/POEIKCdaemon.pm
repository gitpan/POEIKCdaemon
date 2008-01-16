package POEIKCdaemon;

use strict;
use v5.8.1;
our $VERSION = '0.00_02';

use warnings;
use Data::Dumper;
use Sys::Hostname ();
use Class::Inspector;
use UNIVERSAL::require;
use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Server
	Component::IKC::Client
);

use base qw/Class::Accessor::Fast/;
use POEIKCdaemon::Utility;

our @inc = @INC;
our %inc = %INC;
our $DEBUG;

__PACKAGE__->mk_accessors(qw/pidu session_alias ikc_self_port/);

####

sub debug {
	__PACKAGE__->daemon(debug=>1);
}

sub daemon {
	POEIKCdaemon::Utility::_DEBUG_header(\@INC);
	my $class = shift || __PACKAGE__ ;
	my $self = $class->new;
	my %opt = @_;
	$DEBUG = $opt{debug};
	$self->session_alias($opt{session_alias} || 'POEIKCd');
	$self->ikc_self_port($opt{port} || $ARGV[0] || 54321);
	$self->pidu(POEIKCdaemon::Utility->new);
	$self->pidu->init();
	$self->pidu->inc(\%inc);
	$self->pidu->stay(module=>'POEIKCdaemon::Utility');

	$0 = sprintf "poeikcd session_alias:%s port:%s",
				$self->session_alias, $self->ikc_self_port ;#if $0 =~ /poeikcd/;

	$self->spawn();
	$self->poe_run();
}

sub poe_run {
	POE::Kernel->run();
}


sub spawn
{
	my $self = shift;

	POE::Component::IKC::Server->spawn(
		port => $self->ikc_self_port ,
		name => __PACKAGE__,
		aliases  => [ __PACKAGE__ . Sys::Hostname::hostname],
	);

	POE::Session->create(
	    heap => $self,
	    object_states => [ $self =>  Class::Inspector->methods(__PACKAGE__) ]
	);
	return 1;
}

sub _start {
	my $poe     = sweet_args ;
	my $object = $poe->object;

	printf "%s PID:%s ... start!! (%s)\n", $0, $$, scalar(localtime);
	
	my $kernel = $poe->kernel;

	$object->{start_time} = time;
	$kernel->alias_set($object->session_alias);

	# 終了処理 を登録
	$kernel->sig( HUP  => '__stop' );
	$kernel->sig( INT  => '__stop' );
	$kernel->sig( TERM => '__stop' );
	$kernel->sig( KILL => '__stop' );

	$kernel->call(
		IKC =>
			publish => $object->session_alias, Class::Inspector->methods(__PACKAGE__),
	);

#	$kernel->post(IKC=>'monitor', '*'=>{
#		register=>'callback_register',
#		unregister =>'callback_unregister',
#	});
}

#sub callback_register
#{ 
#	my $poe = sweet_args ;
#	my (undef, $client, undef, $data ) = @{$poe->args};
#}
#
#sub callback_unregister
#{ 
#	my $poe = sweet_args ;
#	my (undef, $client, undef, $data ) = @{$poe->args};
#}

sub __stop{
	my $poe = sweet_args;
	$poe->kernel->yield('_stop');
}

sub _stop{
	my $poe = sweet_args;
	my $object = $poe->object;
	$poe->kernel->stop();

	printf "%s PID:%s ... stop!! (%s)\n", $0, $$, scalar(localtime);

}

sub method_respond{
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};

	$kernel->yield(execute_respond => 'method', @{$request});
}


sub function_respond{
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};

	$kernel->yield(execute_respond => 'function', @{$request});
}

sub execute_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $object = $poe->object;
	my ( $from, $args, $rsvp , ) = @{$poe->args};

	ref $args ne 'ARRAY' and
		return $kernel->call( IKC => post => $rsvp, 
		{poeikcd_error=>"A parameter is not an Array reference. It is ".ref $args} );

	my $module = shift @{$args};
	my $method = shift @{$args};

	$object->pidu->use(module=>$module) or 
		return $kernel->call( IKC => post => $rsvp, {poeikcd_error=>$@} );

	if ($module eq 'POEIKCdaemon::Utility'){
		my @re = eval {
			#my $module = shift @{$args} if ref $args eq 'ARRAY';
			$object->pidu->$method(
				poe=>$poe, rsvp=>$rsvp, from=>$from, args=>$args
			);
		};
		my $re = @re == 1 ? shift @re : \@re;
		$@ ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$@} ) :
			$kernel->post( IKC => post => $rsvp, $re );
		return;
	}

	my @re = $from =~ /method/ ? 
		eval   { $module->$method( @{$args} )} : eval {
			no strict 'refs';
			my $code = *{"${module}::$method"};
			$code->( @{$args} );
		};

	my $re = @re == 1 ? shift @re : \@re;

	$@ ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$@} ) :
		 $kernel->post( IKC => post => $rsvp, $re );
}



1;
__END__

=head1 NAME

POEIKCdaemon - POE IKC daemon

=head1 SYNOPSIS

  poeikcd start -p=54321 # or   poeikcd start --port=54321
  poeikcd stop  -p=54321 # or   poeikcd stop  --port=54321
  #
  perl -MPOEIKCdaemon -e POEIKCdaemon::daemon 54321 >> /tmp/poeikcd_log 2>&1 &

And then 

	use POE::Component::IKC::ClientLite;
	use Data::Dumper;

	my $host = '127.0.0.1';
	my $port = $ARGV[0] || 54321;

	print scalar localtime,"\n";
	printf "[ %s : %s ]\n", $host, $port;
	my ($name) = $0 =~ /(\w+)\.\w+/;
	$name .= $$;
	my $ikc = create_ikc_client(
		ip => $host,
		port => $port,
		name => $name,
	);
	my $ret;

	$ikc or die sprintf "%s\n\n",$POE::Component::IKC::ClientLite::error;

	# method_respond
	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['Cwd' => 'getcwd']
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;

	# function_respond
	$ret = $ikc->post_respond('POEIKCd/function_respond' => 
		['LWP::Simple' => 'get', 'http://search.cpan.org/~suzuki/']
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;

	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['MyClass' => 'my_method', 'args1', 'args2', 'args3 ..' ]
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;

	# reload
	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility'=> 'reload', 'MyClass'=> 'my_method']
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;

	# stay , It is not reload.
	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility' => 'stay', 'MyClass' ]
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;
	print '* 'x20,"\n";

	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility' => 'get_A_INC']
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;
	print '* 'x20,"\n";

	# @INC It can change. unshift @INC
	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility' => 'unshift_INC', '~/lib'],
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;
	print '* 'x20,"\n";

	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
			['POEIKCdaemon::Utility' => 'reset_INC'],
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;
	print '* 'x20,"\n";

	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility' => 'stop']
	);
	$ikc->error and die($ikc->error);
	print Dumper $ret;



=head1 DESCRIPTION

POEIKCdaemon is daemon of POE::Component::IKC

=head1 AUTHOR

Yuji Suzuki E<lt>yuji.suzuki.perl@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POE::Component::IKC::ClientLite>

=cut
