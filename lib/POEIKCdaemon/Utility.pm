package POEIKCdaemon::Utility;

use strict;
use v5.8.1;

use warnings;
use Data::Dumper;

use Class::Inspector;
use UNIVERSAL::require;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/inc/);

sub init {
	my $self = shift;
	$self->inc({});
	#$self->inc->{stay};
}

sub use {
	my $self = shift;
	my %args = @_;
	my $module = $args{module} or return;
	#my %inc = %INC;
	return Class::Inspector->loaded( $module ) ? 1 : $module->use() ? 1 : ();
}

sub stay {
	my $self = shift;
	my %args = @_;
	my $module = $args{args}->[0];
	$self->inc->{stay}->{$module} ||= time;
}

sub get_stay {
	my $self = shift;
	return $self->inc->{stay};
}

sub reload {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $args) = (
		delete $args{poe}, $args{rsvp}, $args{from}, $args{args} );
	my $module = $args->[0];

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

	if( @{$args} >= 2 ) {
		$poe->kernel->call($poe->session => execute_respond => $from, $args, $rsvp,  ) 
			or return $!;
	}else{
		return \@deletelist;
	}
}

sub get_A_INC {
	return \@INC;
}

sub get_H_INC {
	return \%INC;
}

sub get_H_ENV {
	return \%ENV;
}

sub get_pid {
	return $$;
}

sub get_port {
	my $self = shift;
	my %args = @_;
	my $poe = $args{poe};
	return $poe->object->{ikc_self_port};
}

sub stop {
	my $self = shift;
	my %args = @_;
	my ($poe, $rsvp, $from, $module, $args) = (
		$args{poe}, $args{rsvp}, $args{from}, $args{module}, $args{args} );
	$poe->kernel->call( IKC => post => $rsvp, [scalar(localtime), time, $$] ) or return $!;
	$poe->kernel->post($poe->session => '__stop' ) or $!;
}



#sub _DEBUG_header {
#	Date::Calc->use or return;
#	my ($pack, $file, $line, $subroutine) = caller(0);
#	my $levels_up = 0 ;
#	($pack, $file, $line, ) = caller($levels_up);
#	$levels_up++;
#	(undef, undef, undef, $subroutine, ) = caller($levels_up);
#	{
#		(undef, undef, undef, $subroutine, ) = caller($levels_up);
#		if(defined $subroutine and $subroutine eq "(eval)") {
#		    $levels_up++;
#		    redo;
#		}
#		$subroutine = "main::" unless $subroutine;
#	}
#	my $log_header = sprintf "[DEBUG] %04d/%02d/%02d %02d:%02d:%02d %s %d %s %d %s - ",
#			Date::Calc::Today_and_Now() , $ENV{HOSTNAME}, $$, $file, $line, $subroutine;
#	my @data = @_;
#	print(
#		$log_header, (join "\t" => map {
#			ref($_) ? Dumper($_) : 
#			defined $_ ? $_ : "`'" ; 
#		} @data ), ($Debug::line_flag ? '' : "\n")
#	);
#}


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

A stop of poeikcd

	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
		['POEIKCdaemon::Utility' => 'stop']
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

