#!/usr/local/bin/perl

###	perl -I t -I lib -MPOEIKCdaemon -e POEIKCdaemon::daemon

use strict;
use warnings;
$| = 1;
use POE::Component::IKC::ClientLite;
use Data::Dumper;
use Sys::Hostname;

	my $host = 'localhost';
	my $port = $ARGV[1] || 54321;

	print scalar localtime,"\n";
	printf "[poeikcd ..  %s / PORT:%s]\n", $host, $port;

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
		['POEIKCdaemon::Utility' => 'unshift_INC', './t'],
		['POEIKCdaemon::Utility' => 'unshift_INC', '~/lib'],
		['POEIKCdaemon::Utility' => 'delete_INC', './t'],
		['POEIKCdaemon::Utility' => 'reset_INC'],
		['POEIKCdaemon::Utility' => 'get_H_INC'],
		['POEIKCdaemon::Utility' => 'get_pid'],
		['POEIKCdaemon::Utility' => 'get_object_something', 'ikc_self_port'],
		['POEIKCdaemon::Utility' => 'get_object_something', 'session_alias'],
		['POEIKCdaemon::Utility' => 'get_stay'],
		['POEIKCdaemon::Utility' => 'get_VERSION'],
		['POEIKCdaemon::Utility' => 'stop'],
		['Cwd' => 'getcwd'],
		['IKC_d_Localtime' => 'timelocal'],
		['POEIKCdaemon::Utility' => 'reload', 'IKC_d_Localtime'],
		['POEIKCdaemon::Utility' => 'reload', 'IKC_d_Localtime' => 'timelocal'],
		['POEIKCdaemon::Utility' => 'stay', 'IKC_d_Localtime' ],
		['POEIKCdaemon::Utility' => 'get_Class_Inspector', 'POEIKCdaemon::Utility'],
		['POEIKCdaemon::Utility' => 'get_Class_Inspector', 'POEIKCdaemon::Utility','methods'],
		['Cwd' => 'getcwd'],
		['LWP::Simple' => 'get', 'http://search.cpan.org/~suzuki/'],
	);


	printf "%2d => %s\n", $_, join("\t"=> @{$exe{$_}}) for sort {$a<=>$b} keys %exe;

	print '*' x 20, "\n";

	$ARGV[0] or printf(" perl eg/client_lite.pl [1 .. %d]", scalar(keys %exe)-1), exit;

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

