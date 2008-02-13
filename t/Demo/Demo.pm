package Demo::Demo;

use Cwd;

our $time; 
our $cut;

local $|=1;

sub demo {
	return join "\t"=>__PACKAGE__,__LINE__,'(',@_,')',scalar(localtime),caller;
}


sub loop_test {
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	sleep 0.5;
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
	return (scalar localtime, time);
}

sub get_time {
	$time
}


sub end_loop {
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	warn unlink $path;
	return @_;
}

END {
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	unlink $path;
}

sub relay_start {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
	
	return 'relay_1', __LINE__,@_;
}

sub relay_1 {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;

	return 'relay_2', __LINE__, @_;
}

sub relay_2 {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
	$cut > 20 ? ('relay_stop', __LINE__,@_) : (3,'relay_1', __LINE__,@_);
	#return 'relay_stop', __LINE__,@_;
}

sub relay_stop {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;

#	my $dir = getcwd;
#	my $path = $dir. '/test-poeikcd.txt';
#	unlink $path;

	return ;
}

#use POEIKCdaemon::Utility;
sub chain_start {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
	return __LINE__,@_;
}

sub chain_1 {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
	return __LINE__,@_;
}

sub chain_2 {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
	return __LINE__,@_;
}

sub chain_3 {
	sleep 0.5;
	my $dir = getcwd;
	my $path = $dir. '/test-poeikcd.txt';
	$cut++;
	$time =  scalar(localtime) . ' cut='. $cut;
	my $str = POEIKCdaemon::Utility::_log_header. join "\t"=>$cut,'(',@_,')', caller(1);
	`echo "***" >> $path`;
	`date >> $path`;
	`echo "$str" >> $path`;
	return __LINE__,@_;
}


1;

