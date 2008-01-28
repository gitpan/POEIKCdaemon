use Test::Base;
use strict;

BEGIN {
eval q{ use Net::Config qw(%NetConfig) };
plan skip_all => "Net::Config is not installed." if $@;

eval q{ use HTTP::Request::Common qw(GET) };
plan skip_all => "HTTP::Request::Common is not installed." if $@;

eval q{ use POE::Component::Client::HTTP qw(GET) };
plan skip_all => "POE::Component::Client::HTTP is not installed." if $@;

eval q{ use POE::Component::Client::HTTP qw(GET) };
plan skip_all => "POE::Component::Client::Keepalive is not installed." if $@;
}
BEGIN {
no warnings;
my $may_make_connections = $NetConfig{test_hosts};
skip_all => "No network connection", unless $may_make_connections;
}

use POE qw(
	Sugar::Args
	Loop::IO_Poll
	Component::IKC::Server
	Component::IKC::Client
	Component::IKC::ClientLite
);
use POEIKCdaemon;
use Data::Dumper;
use Errno qw(EAGAIN);
my $DEBUG = shift || '';

$| = 1;

#  'debug' => $DEBUG,
my $options = {
  'INC' => [
             './t'
           ],
  'alias' => 'POEIKCd',
  'port' => 47225
};

if ($DEBUG) {
	$DEBUG =~ /a/i ? $options->{debug}=1 : $DEBUG=1;
}

my $pid;
FORK: {
	if( $pid = fork ) {
	    # Parent process
	} elsif (defined $pid) {
	    # Child process
		POEIKCdaemon->daemon(%{$options});
		#	my $pikcd = POEIKCdaemon->init(%{$options});
		#	POE::Session->create(
		#		package_states => [ main => Class::Inspector->methods('main') ],
		#	);
		#	$pikcd->spawn();
		#	$pikcd->poe_run();
	    exit;
	} elsif ( $! == EAGAIN) {
	    sleep 1;
	    redo FORK;
	} else {
	    die "Can't fork: $\n";
	}
} # End Of Label:FORK

	sleep 1;
		*POEIKCdaemon::Utility::DEBUG = $DEBUG;

		my ($name) = $0 =~ /(\w+)\.\w+/;
		$name .= $$;
		my %cicopt = (
			ip => '127.0.0.1',
			port => $options->{port},
			name => $name,
		);

		$DEBUG and POEIKCdaemon::Utility::_DEBUG_log(\%cicopt);

		if( Proc::ProcessTable->use ){
			for my $ps( @{Proc::ProcessTable->new->table} ) {
				if ($ps->{pid} != $$ and $ps->{fname} eq 'poeikcd'){
					plan skip_all => $ps->{cmndline}." .... already running \n";
					die;
				}
			}
		}

		my $ikc = create_ikc_client(%cicopt);
		$ikc ? 	plan(tests => 1 * blocks) : plan skip_all => '';

		my $r;
		my $c;
		run {
			my $t = shift;
			my ($no, $type, $v, $name, $comment) = split /\t/, $t->name ;
			
			my $i = $t->input ;
			my $e;
			my $seq_num = $t->seq_num ;

			$r = $ikc->post_respond(
				$options->{alias}.'/method_respond' => eval $i);
				$ikc->error and die($ikc->error);
			
#			POEIKCdaemon::Utility::_DEBUG_log($seq_num,$c);
			eval $v if defined $v;
#			POEIKCdaemon::Utility::_DEBUG_log($seq_num,$c);
			$e = eval $t->expected ;
			$e = ref $e ? Dumper($e):$e;
			$r = ref $r ? Dumper($r):$r;

			for ($type) {
				$_ eq 'isnt'	and isnt($r , $e, $name), last;
				$_ eq 'is'		and is	($r , $e, $name), last;
				$_ eq 'ok_r'	and ok	($r ,     $name), last;
				$_ eq 'ok_e'	and ok	($e ,     $name), last;
			}
			POEIKCdaemon::Utility::_DEBUG_log(
				sprintf "[%2d] t=%s, n=%s, \ni=%s, \ne=%s, \nr=%s, \nc=%s, \nv=%s, \ncomment=%s",
				$seq_num, $type, $name, ($i||"`'"), ($e||"`'"), ($r||"`'"), (Dumper($c||"`'")), $v||"`'", $comment||"`'",
			);
			$type eq 'pass'	and pass;
		};

		$ikc->post_respond($options->{alias}.'/stop_respond' );
		$ikc->error and die($ikc->error);

    #wait;
	waitpid($pid, 0);

__END__

=== 1	is	#	POEIKCdaemon::Utility=>get_VERSION
--- input: ['POEIKCdaemon::Utility' => 'get_VERSION']
--- expected: $POEIKCdaemon::VERSION

