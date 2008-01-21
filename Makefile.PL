print "\n", '-'x78, "\n\n";
use inc::Module::Install;
name 'POEIKCdaemon';
all_from 'lib/POEIKCdaemon.pm';

requires('Class::Accessor::Fast');
requires('Class::Inspector');
requires('UNIVERSAL::require');
requires('Getopt::Long');
requires('POE');
requires('POE::Sugar::Args');
requires('POE::Loop::IO_Poll');
requires('POE::Component::IKC::Server');
requires('POE::Component::IKC::ClientLite');
requires('Proc::Daemon');
requires('Pod::Usage');
requires('Best');
requires('YAML');

build_requires 'Test::More';
build_requires 'Test::Base';
build_requires 'Proc::ProcessTable';

install_script 'bin/poeikcd';
install_script 'bin/pikc';

use_test_base;
auto_include;
auto_install;
WriteAll;

print "\n", '-'x78, "\n\n";
