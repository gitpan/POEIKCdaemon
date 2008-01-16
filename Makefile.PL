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

build_requires 'Test::More';
install_script 'bin/poeikcd';

use_test_base;
auto_include;
auto_install;
WriteAll;

