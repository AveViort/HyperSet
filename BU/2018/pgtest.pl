#!/usr/bin/perl -w

use strict;
use DBI;

# Module environment init.
my $moduleshome = $ENV{MODULESHOME};
if ($moduleshome eq "") {
    $moduleshome = "/pdc/modules/etc";
}
require "$moduleshome/init/perl";

# Add pgsql-module
&module("load pgsql");

# Hack to use new settings of PERL5LIB in this script
foreach my $lib (split(/:/, $ENV{PERL5LIB})) {
    eval "use lib \"$lib\";";
}

# Setup connection settings.
my $dbsrvname = `echo -n \`whoami\``;
if ($ENV{"PGKRBSRVNAME"}) {
    $dbsrvname = $ENV{"PGKRBSRVNAME"};
}
my $dbport = `echo -n \`id -u\``;
if ($ENV{"PGPORT"}) {
    $dbport =  $ENV{"PGPORT"};
}
my $dbhost = "sbcdb.pdc.kth.se";
if ($ENV{"PGHOST"}) {
    $dbport =  $ENV{"PGHOST"};
}
my $dbuser = `echo -n \`whoami\``;
if ($ENV{"PGUSER"}) {
    $dbuser =  $ENV{"PGUSER"};
}

my $dbh = DBI->connect("dbi:Pg:dbname=$dbuser;host=$dbhost;port=$dbport;krbsrvname=$dbsrvname", "", "") || die "Failed to connect";

my $sth = $dbh->prepare("SELECT name FROM names WHERE name ~ ?");

# Any arguments to script?
my $query = ".*";
if ($ARGV[0]) {
    $query = $ARGV[0];
}

$sth->execute($query);

while ( my @row = $sth->fetchrow_array ) {
    print "@row\n";
}
