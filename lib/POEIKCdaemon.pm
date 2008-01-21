package POEIKCdaemon;

use strict;
use v5.8.1;
our $VERSION = '0.00_03';

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

__PACKAGE__->mk_accessors(qw/pidu alias ikc_self_port/);

####

sub init {
	my $class = shift || __PACKAGE__ ;
	my $self = $class->new;
	my %opt = @_;
	$DEBUG = $opt{debug};
	$self->alias($opt{alias} || 'POEIKCd');
	$self->ikc_self_port($opt{port} || $ARGV[0] || 47225);
	$self->pidu(POEIKCdaemon::Utility->_new);
	$self->pidu->_init();
	$self->pidu->DEBUG($DEBUG) if $DEBUG;
	$self->pidu->inc(\%inc);
	$self->pidu->stay(module=>'POEIKCdaemon::Utility');
	$0 = sprintf "poeikcd alias:%s port:%s",
				$self->alias, $self->ikc_self_port ;#if $0 =~ /poeikcd/;
	if ($DEBUG) {
		POEIKCdaemon::Utility::_DEBUG_log(VERSION=>$VERSION);
		POEIKCdaemon::Utility::_DEBUG_log($INC{ Class::Inspector->filename(__PACKAGE__)});
		POEIKCdaemon::Utility::_DEBUG_log(GetOptions=>\%opt);
		POEIKCdaemon::Utility::_DEBUG_log('@INC'=>\@INC);
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
	    heap => {},
	    object_states => [ $self =>  Class::Inspector->methods(__PACKAGE__) ]
	);
	return 1;
}

sub _start {
	my $poe     = sweet_args ;
	my $object = $poe->object;

	printf "%s PID:%s ... Started!! (%s)\n", $0, $$, scalar(localtime);
	
	my $kernel = $poe->kernel;

	$object->{start_time} = time;
	$kernel->alias_set($object->alias);

	# 終了処理 を登録
	$kernel->sig( HUP  => '__stop' );
	$kernel->sig( INT  => '__stop' );
	$kernel->sig( TERM => '__stop' );
	$kernel->sig( KILL => '__stop' );

	$kernel->call(
		IKC =>
			publish => $object->alias, Class::Inspector->methods(__PACKAGE__),
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

sub _stop{
	my $poe = sweet_args;
	my $object = $poe->object;
	$poe->kernel->stop();

	printf "%s PID:%s ... stopped!! (%s)\n", $0, $$, scalar(localtime);

}

sub __stop{
	my $poe = sweet_args;
	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log();
	$poe->kernel->yield('_stop');
}

sub stop_respond{
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	my ($expr, $rsvp) = @{$request};
	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($rsvp);
	$poe->kernel->call( IKC => post => 
		$rsvp, 
		sprintf("%s PID:%s ... stopped!! (%s)\n", $0, $$, scalar(localtime))
		#[scalar(localtime), $$, $poe->object->ikc_self_port] 
	);
	$poe->kernel->yield('__stop');
}

sub eval_respond {
	my $poe = sweet_args;
	my $kernel = $poe->kernel;
	my ($request) = @{$poe->args};
	my ($expr, $rsvp) = @{$request};
	$expr = shift @{$expr} if ref $expr eq 'ARRAY';

	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($expr);

	my @re = eval $expr;
	my $re = @re == 1 ? shift @re : \@re;
	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($re);
	$@ ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$@} ) :
		 $kernel->post( IKC => post => $rsvp, $re );
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

	$object->pidu->use(module=>$module) or 
		return $kernel->call( IKC => post => $rsvp, {poeikcd_error=>$@} );

	if ($module eq 'POEIKCdaemon::Utility'){
		$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($rsvp);
		my @re = eval {
			#my $module = shift @{$args} if ref $args eq 'ARRAY';
			$method ? 
			$object->pidu->$method(
				poe=>$poe, rsvp=>$rsvp, from=>$from, args=>$args
			) : grep {not /^\_/ and not /^[A-Z]+$/} @{Class::Inspector->methods($module)};
		};
		my $re = @re == 1 ? shift @re : \@re;
		if (not $rsvp->{responded}) {
			$@ ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$@} ) :
				$kernel->post( IKC => post => $rsvp, $re );
			$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($re, $rsvp);
		}else{
			$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($re, $rsvp);
		}
		return;
	}

	my @re = $from =~ /method/ ? 
		eval   { $module->$method( @{$args} )} : eval {
			no strict 'refs';
			my $code = *{"${module}::$method"};
			$code->( @{$args} );
		};

	my $re = @re == 1 ? shift @re : \@re;

	$DEBUG and POEIKCdaemon::Utility::_DEBUG_log($re);

	$@ ? $kernel->post( IKC => post => $rsvp, {poeikcd_error=>$@} ) :
		 $kernel->post( IKC => post => $rsvp, $re );
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
L<pikc> (POK IKC Client) 

	pikc --help

    pikc -H remote_hostname -p=47225 -a=POEIKCd -s=m -o=y MyClass my_method args1 args2

    pikc -s=method_respond POEIKCdaemon::Utility get_VERSION
    pikc -s m POEIKCdaemon::Utility get_A_INC -o d
    pikc -s m POEIKCdaemon::Utility get_H_ENV -o y
    pikc -s=function_respond LWP::Simple get http://search.cpan.org/~suzuki/
    pikc -s=eval_respond 'scalar `ps ux`'

or 
use POE::Component::IKC::ClientLite

	use POE::Component::IKC::ClientLite;
	use Data::Dumper;

	my $host = '127.0.0.1';
	my $port = $ARGV[0] || 47225;

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

	# shutdown
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
