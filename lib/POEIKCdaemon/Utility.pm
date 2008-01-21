package POEIKCdaemon::Utility;

use strict;
use v5.8.1;

use warnings;
use Data::Dumper ();

use Class::Inspector;
use UNIVERSAL::require;

our $DEBUG;

sub DEBUG {
	my $self = shift;
	$DEBUG = shift if @_;;
}

sub _new {
    my $class = shift ;
    my $self = {
        @_
        };
    $class = ref $class if ref $class;
    bless  $self,$class ;
    return $self ;
}


sub inc {shift->{inc}}

sub _init {
	my $self = shift;
	$self->{inc} = {};
}

sub get_A_INC { return \@INC }
sub get_H_INC { return \%INC }
sub get_H_ENV { return \%ENV }
sub get_pid { return $$ }
sub get_VERSION { return $POEIKCdaemon::VERSION }

sub get_object_something {
	my $self = shift;
	my %args = @_;
	my $poe = $args{poe};
	my ($something) = @{$args{args}};
	return $poe->object->$something; # ikc_self_port alias;
}

sub unshift_INC {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	for( @{$args{args}} ){
		unshift @INC, map {s/~/$ENV{HOME}/;$_} split /:/ => $_;
	}
	return \@INC;
}

sub reset_INC {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $path = shift @{$args{args}};
	@INC = @POEIKCdaemon::inc;
	return \@INC;
}

sub delete_INC {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $path = shift @{$args{args}};
	my @inc;
	for (@INC) {
		push @inc, $_ unless $path eq $_;
	}
	@INC = @inc;
	return \@INC;
}

sub use {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $module, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{module}, $args{args} );
	$module ||=  shift @{$args{args}} or return;
	return Class::Inspector->loaded( $module ) ? 1 : $module->use() ? 1 : ();
}


sub get_Class_Inspector {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $module = shift @{$args{args}} or return;
	return not(@{$args}) ? Class::Inspector->methods('Class::Inspector') : do {
		my $method = shift @{$args};
		Class::Inspector->$method($module);
	};
}

sub stay {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $module, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{module}, $args{args} );
	$module ||= shift @{$args{args}} or return;
	$self->inc->{stay}->{$module} ||= time;
	return $self->inc->{stay};
}

sub get_stay {
	my $self = shift;
	return $self->inc->{stay};
}

sub reload {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $module = shift @{$args{args}} or return;

	my @deletelist;

	if (not $self->inc->{stay}->{$module}) {

		no warnings;

		for ( sort keys %INC ){
			next if $self->inc->{$_} ;
			next if $self->inc->{stay}->{$_};
			push @deletelist, delete $INC{$_};
		}

		{no strict 'refs';%{"${module}::"}=();}
		
	}

	if( @{$args} >= 1) {
		unshift @{$args}, $module;
		$DEBUG and _DEBUG_log( $rsvp, $args);
		$poe->kernel->call($poe->session => execute_respond => $from, $args, $rsvp,  )
			or return $!;
		$rsvp->{responded} = (caller(0))[3];
	}else{
		return \@deletelist;
	}
}




sub _DEBUG_log {
	$DEBUG or return;
	Date::Calc->use or return;
	#YAML->use or return;
	my ($pack, $file, $line, $subroutine) = caller(0);
	my $levels_up = 0 ;
	($pack, $file, $line, ) = caller($levels_up);
	$levels_up++;
	(undef, undef, undef, $subroutine, ) = caller($levels_up);
	{
		(undef, undef, undef, $subroutine, ) = caller($levels_up);
		if(defined $subroutine and $subroutine eq "(eval)") {
		    $levels_up++;
		    redo;
		}
		$subroutine = "main::" unless $subroutine;
	}
	my $log_header = sprintf "[DEBUG %04d/%02d/%02d %02d:%02d:%02d %s %d %s %d %s] - ",
			Date::Calc::Today_and_Now() , $ENV{HOSTNAME}, $$, $file, $line, $subroutine;
	my @data = @_;
	print(
		$log_header, (join "\t" => map {
			ref($_) ? Data::Dumper::Dumper($_) : 
			defined $_ ? $_ : "`'" ; 
		} @data ),"\n"
	);
}


1;

__END__

=head1 NAME

POEIKCdaemon::Utility - Utility for POEIKCdaemon

=head1 SYNOPSIS

The reload of the module.

	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility'=> 'reload', 'MyClass']
	);
	print Dumper $ret;

The reload of the module and Method execution.

	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility'=> 'reload', 'MyClass'=> 'my_method']
	);
	print Dumper $ret;

=head1 DESCRIPTION

POEIKCdaemon::Utility is Utility for POEIKCdaemon

=head1 AUTHOR

Yuji Suzuki E<lt>yuji.suzuki.perl@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<POEIKCdaemon>

=cut

