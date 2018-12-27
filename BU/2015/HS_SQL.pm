package HS_SQL;

use DBI;
#use DBD::Pg qw(:pg_types);
# use CGI qw(:standard);
# use CGI::Carp qw(fatalsToBrowser);
#use List::Util qw[min max];
#use IPC::Open2;

use strict vars;
use HStextProcessor;
use HSconfig;

BEGIN {
	require Exporter;
	use Exporter;
	require 5.002;
	our($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = 1.00;
	@ISA = 			qw(Exporter);
	#@EXPORT = 		qw();
	%EXPORT_TAGS = 	();
	@EXPORT_OK	 =	qw();
}
#SQL code:
#  CREATE TABLE users (id SERIAL NOT NULL, username VARCHAR(64) NOT NULL,  password VARCHAR(64) NOT NULL, email  VARCHAR(256), PRIMARY KEY (id), UNIQUE (id), UNIQUE (username));
# COMMIT;
# INSERT INTO users (id, username, password) VALUES(default, 'andale', '180844');
# CREATE TABLE sessions (id SERIAL NOT NULL, username VARCHAR(64) NOT NULL,  ip VARCHAR(64) NOT NULL, started timestamp, expires timestamp, PRIMARY KEY (id), UNIQUE (id));
# 
# print system('PGPASSWORD="SuperSet" psql -d hyperset -U hyperset  -c "SELECT procpid FROM pg_stat_activity;" -t | PGPASSWORD="SuperSet" xargs -n1 -I {} psql -d hyperset -U hyperset  -c "SELECT pg_cancel_backend({})"');exit; psql -c "SELECT pid FROM pg_stat_activity;" -t | xargs -n1 -I {} psql -c "SELECT pg_cancel_backend({})"

our ($dbh,	$data);
our $session_length = "'24 hours'";
#SQL connection:
sub connect2PG {
my $dsn  = "DBI:Pg:dbname=hyperset";
my $user = 'hyperset';
my $ps   = 'SuperSet';
my $dbh = DBI->connect( $dsn, $user, $ps,  {
        RaiseError => 1, AutoCommit => 0
    }) || die "Failed to connect as $dsn, user $user.../n";
	return($dbh);
}

sub dbh {
my $dsn  = "DBI:Pg:dbname=hyperset";
my $user = 'hyperset';
my $ps   = 'SuperSet';
$dbh = DBI->connect( $dsn, $user, $ps ,  {
        RaiseError => 1, AutoCommit => 0
    }) || die "Failed to connect as $dsn, user $user.../n";
return $dbh;
}


#hack protection:
# my ( $gg, $ee, $ss );
# for $gg (@genes) {
	# $gg =~ s/\s//g;
	# if ( $gg !~ m/^[A-Za-z0-9\:\_\-\.]+$/ ) {
		# if ( $output eq 'webgraph' ) {
			# print $q->header();
			# print $q->start_html();
		# }
		# print $q->h4(
			# { -style => 'Color: red;' },
			# $gg
			  # . ': invalid input: just use letters, digits, dash, underscore, and dot'
		# );
		# $end_it = 1;
		# goto END_IT1;
	# }
# }
1;
__END__
