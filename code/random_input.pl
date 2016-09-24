#!/usr/bin/env perl

use strict;
use warnings;

die "argument manquant: utiliser random_input.pl \"nombre de lettres\"" unless defined $ARGV[0];
my $number = $ARGV[0];
for(1..$number) {
	my $letter = int rand(26);
	print chr($letter+ord('a'));
}
print "\n";
