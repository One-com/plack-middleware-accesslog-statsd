use inc::Module::Install;

name     'Plack-Middleware-AccessLog-StatsD';
all_from 'lib/Plack/Middleware/AccessLog/StatsD.pm';
author   q{Peter Makholm <peter@makholm.net>};
license  'perl';
githubmeta;

requires 'Time::HiRes';
requires 'Plack::Middleware::EasyHooks';

build_requires 'Test::More';

auto_install;

WriteAll;

