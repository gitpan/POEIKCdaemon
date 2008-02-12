package POEIKCdaemon;

use strict;
use v5.8.1;
our $VERSION = '0.00_07';

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

__PACKAGE__->mk_accessors(qw/pidu argv alias ikc_self_port/);

####

sub init {
	my $class = shift || __PACKAGE__ ;
	my $self = $class->new;
	my %opt = @_;
	$DEBUG = $opt{debug};
	$self->argv($opt{argv}) if $opt{argv};
	$self->alias($opt{alias} || 'POEIKCd');
	$self->ikc_self_port($opt{port} || $ARGV[0] || 47225);
	$self->pidu(POEIKCdaemon::Utility->_new);
	$self->pidu->_init();
	$self->pidu->DEBUG($DEBUG) if $DEBUG;
	$self->pidu->inc->{org_inc}= \%inc;
	$self->pidu->stay(module=>'POEIKCdaemon::Utility');

	push @{$opt{Module}}, __PACKAGE__, 'POEIKCdaemon::Utility';
	$self->pidu->inc->{load}->{ $_ } = [$INC{Class::Inspector->filename($_)},time] for @{$opt{Module}};

	$0 = sprintf "poeikcd --alias=%s --port=%s",
				$self->alias, $self->ikc_self_port ;#if $0 =~ /poeikcd/;
	if ($DEBUG) {
		no warnings 'redefine';
		*POE::Component::IKC::Responder::DEBUG = sub { 1 };
		*POE::Component::IKC::Responder::Object::DEBUG = sub { 1 };
		POEIKCdaemon::Utility::_DEBUG_log(VERSION	=>$VERSION);
		POEIKCdaemon::Utility::_DEBUG_log(load_module=>$self->pidu->inc->{load});
		POEIKCdaemon::Utility::_DEBUG_log(GetOptions=>\%opt);
		POEIKCdaemon::Utility::_DEBUG_log('@INC'	=>\@INC);
	}
	return $self;
}

sub daemon {
	my $self = shift->init(@_);
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
	    object_states => [ $self =>  Class::Inspector->methods(__PACKAGE__) ]
	);

#	if ($self->argv){
#		my ( $session_alias, $event, $args ) = @{$self->argv};
#		my ( $session_alias, $event, $args ) = @{$self->argv};
#	}

	return 1;
}

sub _start {
	my $poe     = sweet_args ;
	my $object = $poe->object;

	printf "%s PID:%s ... Started!! (%s)\n", $0, $$, scalar(localtime);
	
	my $kernel = $poe->kernel;

	$object->{start_time} = localtime;
	$kernel->alias_set($object->alias);

	# 終了処理 を登録
	$kernel->sig( HUP  => '_stop' );
	$kernel->sig( INT  => '_stop' );
	$kernel->sig( TERM => '_stop' );
	$kernel->sig( KILL => '_stop' );

	$kernel->call(
		IKC =>
			#publish => $object->alias, Class::Inspector->methods(__PACKAGE__),
			publish => $object->alias, [qw/
				_stop 
				event_respond
				execute_respond
				function_respond
				method_respond
				something_respond
			/],
	);

	if ($DEBUG) {
		$kernel->post(IKC=>'monitor', '*'=>{
			register=>'callback_register',
			unregister =>'callback_unregister',
		});
	}
}

sub callback_register
{ 
	my $poe = sweet_args ;
	my (undef, $client, undef, $data ) = @{$poe->args};
	POEIKCdaemon::Utility::_DEBUG_log(register=>$client);
}

sub callback_unregister
{ 
	my $poe = sweet_args ;
	my (undef, $client, undef, $data ) = @{$poe->args};
	POEIKCdaemon::Utility::_DEBUG_log(unregister=>$client);
}

sub _stop {
	my $poe = sweet_args;
	$poe->kernel->stop();
	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log();
	printf "%s PID:%s ... stopped!! (%s)\n", $0, $$, scalar(localtime);
}

sub something_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my $session = $poe->session;
	my $object = $poe->object;
	my ($request) = @{$poe->args};
	my ($args, $rsvp) = @{$request};

	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($request);

	my @something = $object->pidu->_distinguish( poe=>$poe, args => $args );
	@something ? 
		$kernel->call($session, execute_respond => @something, $rsvp):

	$kernel->post( IKC => post => $rsvp, {poeikcd_error=>
		'It is not discriminable. '.
		q{"ModuleName::functionName" or  "ClassName->methodName" or "AliasName eventName"} 
	});
}

sub event_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	$kernel->yield(execute_respond => 'event', @{$request});
}

sub method_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	$kernel->yield(execute_respond => 'method', @{$request});
}

sub function_respond {
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


	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($from, $args, $rsvp);

	ref $args ne 'ARRAY' and
		return $kernel->call( IKC => post => $rsvp, 
		{poeikcd_error=>"A parameter is not an Array reference. It is ".ref $args} );

	my $module = shift @{$args};
	my $method = shift @{$args};

	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log(module => $module);
	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log(method => $method);
	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log(args => $args);

	if($from !~ /^event/ and not $object->pidu->use(module=>$module)) {

			return $kernel->call( IKC => post => $rsvp, {poeikcd_error=>$@} );
	}

	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log(from => $from);

	if ($module eq 'POEIKCdaemon::Utility'){
		$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($rsvp);
		my @re = eval {
			$method ? 
			$object->pidu->$method(
				poe=>$poe, rsvp=>$rsvp, from=>$from, args=>$args
			) : grep {not /^\_/ and not /^[A-Z]+$/} @{Class::Inspector->methods($module)};
		};
		my $re = @re == 1 ? shift @re : @re ? \@re : ();
		if (not $rsvp->{responded}) {
			$@ ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$@} ) :
				$kernel->post( IKC => post => $rsvp, $re );
			$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($re, $rsvp);
		}else{
			$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($re, $rsvp);
		}
		return;
	}

	my @re = $object->pidu->execute(poe=>$poe, from=>$from, module=>$module, method=>$method, args=>$args);
	my $e = $@ if $@;

	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($e);
	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log(@re);
	my $re = @re == 1 ? shift @re : @re ? \@re : ();

	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($module, $method, $re);

	if ($rsvp) {
		return $e ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$e} ) :
			    $kernel->post( IKC => post => $rsvp, $re );

		return  $kernel->post( IKC => post => $rsvp, $re ) if $re;
	}else{
		return @re ? @re : $re || ();
	}

}



1;
__END__

=head1 NAME

POEIKCdaemon - POE IKC daemon

=head1 SYNOPSIS

L<poeikcd>

	poeikcd start -p=47225 
	poeikcd stop  -p=47225 
	poeikcd --help

And then 
L<poikc> (POK IKC Client) 

	poikc -H hostname [options] args...
	poikc --help


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
