#!/usr/local/bin/perl

use strict;
use warnings;
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

$ret = $ikc->post_respond('POEIKCd/method_respond' => 
	['Cwd' => 'getcwd']
);
$ikc->error and die($ikc->error);
print Dumper $ret;
print '* 'x20,"\n";

$ret = $ikc->post_respond('POEIKCd/function_respond' => 
	['LWP::Simple' => 'get', 'http://search.cpan.org/~suzuki/']
);
$ikc->error and die($ikc->error);
print Dumper $ret;
print '* 'x20,"\n";

#	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
#		['POEIKCdaemon::Utility' => 'stay', 'MyClass' ]
#	);
#	$ikc->error and die($ikc->error);
#	print Dumper $ret;
#	print '* 'x20,"\n";

#	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
#		['MyClass' => 'my_method', 'args1', 'args2', 'args3 ..' ]
#	);
#	$ikc->error and die($ikc->error);
#	print Dumper $ret;
#	print '* 'x20,"\n";

#	$ret = $ikc->post_respond('POEIKCd/method_respond' => 
#		['POEIKCdaemon::Utility'=> 'reload', 'MyClass'=> 'my_method']
#	);
#	$ikc->error and die($ikc->error);
#	print Dumper $ret;
#	print '* 'x20,"\n";



########

$ret = $ikc->post_respond('POEIKCd/method_respond' => 
	['POEIKCdaemon::Utility' => 'get_A_INC']
);
$ikc->error and die($ikc->error);
print Dumper $ret;
print '* 'x20,"\n";

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

########

$ikc or die sprintf "%s\n\n",$POE::Component::IKC::ClientLite::error;
$ret = $ikc->post_respond('POEIKCd/method_respond' => 
	['POEIKCdaemon::Utility' => 'stop']
);
$ikc->error and die($ikc->error);
print Dumper $ret;
print '* 'x20,"\n";

