package POEIKCdaemon::Utility;

use strict;
use v5.8.1;
our $VERSION = '0.00_00';

use warnings;
use Data::Dumper;

use Class::Inspector;
use UNIVERSAL::require;
use base qw(Class::Accessor::Fast);

sub reload {
	shift;
	my ($poe, $rsvp, $module, @args) = @_;

	no warnings;

	my @deletelist;
	for ( keys %INC ){
		push @deletelist, delete $INC{$_} unless $POEIKCdaemon::inc{$_};
	}

	{no strict;%{"${module}::"}=();}

	if( @args ) {
		unshift @args, $module;
		$poe->kernel->call($poe->session => execute => \@args, $rsvp ) 
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
	shift;
	my ($poe, $rsvp) = @_;
	return $poe->object->{ikc_self_port};
}

sub stop {
	shift;
	my ($poe, $rsvp) = @_;
	$poe->kernel->call( IKC => post => $rsvp, [scalar(localtime), time, $$] ) or return $!;
	$poe->kernel->post($poe->session => '__stop' ) or $!;
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

