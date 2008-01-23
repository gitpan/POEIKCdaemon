use strict;
use Test::Base;

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

my $options = {
#  'debug' => $DEBUG,
  'alias' => 'POEIKCd',
  'port' => 47225
};

if ($DEBUG) {
	$DEBUG =~ /a/i ? $options->{debug}=1 : $DEBUG=1;
        no warnings 'redefine';
    *POE::Component::IKC::Responder::DEBUG = sub { 1 };
    *POE::Component::IKC::Responder::Object::DEBUG = sub { 1 };
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

=== 2	is	@{$c->{INC}}=@INC	POEIKCdaemon::Utility=>get_A_INC
--- input: ['POEIKCdaemon::Utility' => 'get_A_INC']
--- expected: \@INC

=== 3	isnt	$c->{i1}=$r	POEIKCdaemon::Utility=>get_A_INC	# lib qw(./t)
--- input: ['POEIKCdaemon::Utility' => 'unshift_INC', './t']
--- expected: \@INC

=== 4	is		POEIKCdaemon::Utility=>get_A_INC	# 前回 $c のと $r 比較
--- input: ['POEIKCdaemon::Utility' => 'get_A_INC']
--- expected: $c->{i1}

=== 5	ok_e	#	POEIKCdaemon::Utility=>get_A_INC	# ./t が @INCにあるか確認
--- input: ['POEIKCdaemon::Utility' => 'get_A_INC']
--- expected: './t' eq shift @{$r}



=== 6	ok_r	$c->{t1}=$r;sleep(1);	IKC_d_Localtime=>timelocal	# 時間取得
--- input: ['IKC_d_Localtime' => 'timelocal']
--- expected: $r

=== 7	is	$c->{t2}=$r;sleep(1);	IKC_d_Localtime=>timelocal	# 前回 $c のと $r 比較(前回と同じ時間になってるはず）
--- input: ['IKC_d_Localtime' => 'timelocal']
--- expected: $c->{t1}

=== 8	isnt	$c->{t3}=$r;sleep(1);	POEIKCdaemon::Utility=>reload,IKC_d_Localtime=>timelocal	# リロードしたので、前回のとは違う1
--- input: ['POEIKCdaemon::Utility' => 'reload', 'IKC_d_Localtime' => 'timelocal']
--- expected: $c->{t2}

=== 9	isnt	$c->{t4}=$r;sleep(1);	POEIKCdaemon::Utility=>reload,IKC_d_Localtime=>timelocal	# リロードしたので、前回のとは違う2
--- input: ['POEIKCdaemon::Utility' => 'reload', 'IKC_d_Localtime' => 'timelocal']
--- expected: $c->{t3}

=== 10	is	$c->{t5}=$r;sleep(1);	IKC_d_Localtime=>timelocal	# 前回 $c のと $r 比較(前回と同じ時間になってるはず）
--- input: ['IKC_d_Localtime' => 'timelocal']
--- expected: $c->{t4}

=== 11	ok_r	$c->{s1}=$r;#	POEIKCdaemon::Utility=>stay,IKC_d_Localtime	# stay させた IKC_d_Localtime
--- input: ['POEIKCdaemon::Utility' => 'stay', 'IKC_d_Localtime' ]
--- expected: exists $r->{IKC_d_Localtime}

=== 12	is	$c->{t6}=$r;sleep(1);	POEIKCdaemon::Utility=>reload,IKC_d_Localtime=>timelocal	# リロードしたが前回と同じ
--- input: ['POEIKCdaemon::Utility' => 'reload', 'IKC_d_Localtime' => 'timelocal']
--- expected: $c->{t5}



=== 13	is	#	POEIKCdaemon::Utility=>delete_INC
--- input: ['POEIKCdaemon::Utility' => 'delete_INC', './t']
--- expected: $c->{INC}

=== 14	is	#	POEIKCdaemon::Utility=>unshift_INC	# lib qw(./t)
--- input: ['POEIKCdaemon::Utility' => 'unshift_INC', './t']
--- expected: $c->{i1}

=== 15	is	#	POEIKCdaemon::Utility=>reset_INC
--- input: ['POEIKCdaemon::Utility' => 'reset_INC']
--- expected: $c->{INC}

=== 16	ok_r	#	POEIKCdaemon::Utility=>get_load
--- input: ['POEIKCdaemon::Utility' => 'get_load']
--- expected: 
