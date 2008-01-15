#!/usr/local/bin/perl

###	perl -I t -I lib -MPOEIKCdaemon -e POEIKCdaemon::daemon
$ARGV[0] or exit(print "
### perl eg/client_lite.pl 1 
### perl eg/client_lite.pl 2 
### perl eg/client_lite.pl :
\n");

use strict;
use warnings;
$| = 1;
use POE::Component::IKC::ClientLite;
use Data::Dumper;
use Sys::Hostname;

	my $host = 'localhost';
	my $port = $ARGV[1] || 54321;

	print scalar localtime,"\n";
	printf "[ %s : %s ]\n", $host, $port;

	my ($name) = $0 =~ /(\w+)\.\w+/;
	$name .= $$;

	my $ikc = create_ikc_client(
			ip => $host,
			port => $port,
			name => $name,
	);

	$ikc or do{
		printf "%s\n\n",$POE::Component::IKC::ClientLite::error; 
		exit;
	};

	my $ret;
	my $nom=0;
	my %exe = map {$nom++=>$_}
	(
		['Foo::Class'=>'FooMethod'=>'@args'],
		['POEIKCdaemon::Utility' => 'reload', 'POEIKCdaemon::Utility'],
		['POEIKCdaemon::Utility' => 'get_H_ENV'],
		['POEIKCdaemon::Utility' => 'get_A_INC'],
		['POEIKCdaemon::Utility' => 'get_H_INC'],
		['POEIKCdaemon::Utility' => 'get_pid'],
		['POEIKCdaemon::Utility' => 'get_port'],
		['POEIKCdaemon::Utility' => 'get_stay'],
		['POEIKCdaemon::Utility' => 'stop'],
		['Cwd' => 'getcwd'],
		['IKC_d_Localtime' => 'timelocal'],
		['POEIKCdaemon::Utility' => 'reload', 'IKC_d_Localtime'],
		['POEIKCdaemon::Utility' => 'reload', 'IKC_d_Localtime' => 'timelocal'],
		['POEIKCdaemon::Utility' => 'stay', 'IKC_d_Localtime' ],
		[],
		[],
		['Cwd' => 'getcwd'],
		['LWP::Simple' => 'get', 'http://search.cpan.org/~suzuki/'],
	);


	printf "%s => %s\n", $_, Dumper $exe{$_} for sort {$a<=>$b} keys %exe;

	printf "[%d]\t%s\n", $ARGV[0], join "\t"=>@{$exe{ $ARGV[0] }};

	my $session_alias = $ARGV[2] || 'POEIKCd';
	
	my $event = $ARGV[0] <= 15 ? 'method_respond' : 'function_respond';
	print $event,"\n";
	
	$ret = $ikc->post_respond($session_alias.'/'.$event => $exe{ $ARGV[0] });

	$ikc->error and die($ikc->error);
	if (my $r = ref $ret) {
		if ( $r eq 'HASH'){
			my %ret = %{$ret};
			for(sort keys %ret){printf "%-35s= %s", $_, Dumper $ret{$_}}
			print "\n";
		}else{
			print(Dumper($ret));
		}
	}else{
		print(Dumper($ret));
	}

