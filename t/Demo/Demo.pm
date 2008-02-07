package Demo::Demo;

use Cwd;

our $time; 
our $cut;

sub demo {
	return join "\t"=>__PACKAGE__,__LINE__,'(',@_,')',scalar(localtime),caller;
}


sub loop_test {
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = join "\t"=>__PACKAGE__,__LINE__,'(',@_,')',scalar(localtime),caller;
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
}

sub get_time {
	$time
}


sub end_loop {
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	unlink $path;
	return @_;
}

END {
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	unlink $path;
}

1;

