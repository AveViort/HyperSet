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

our ($translated_genes, $dbh,	$data);
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

sub gene_synonyms { # for submitted ARBITRARY gene/protein/enzime IDs, finds reference IDs (normally  gene symbols)
	my ( $genes, $spec, $type ) = @_;
	my ( $rows, $gene_arr, $gg, $sth, $fcgenes);
  # print 'REC AGS GENES: '.join(" ",@{$genes} ).'<br>'."\n"  ;

	$gene_arr = "\'" . uc( join( "\', \'", @{$genes} ) ) . "\'";
	my $sm = "SELECT optname, hsname FROM  $HSconfig::optnames WHERE org_id = \'$spec\' and upper(optname) IN ($gene_arr)";
		$sth =
	  $dbh->prepare_cached($sm)  || die "Failed to prepare SELECT statement 1";
	    # print $sm;
	$sth->execute();
	while ( $rows = $sth->fetchrow_hashref ) {
		$fcgenes->{ $rows->{'hsname'} } = $type
		  if !defined( $fcgenes->{ $rows->{'hsname'} } )
		  or ( $fcgenes->{ $rows->{'hsname'} } ne 'query' );
		   # print 'hs_gene '.$rows->{'hsname'}.'<br>'."\n"  ;
		$HS_bring_subnet::found_genes->{$spec}->{ $rows->{'hsname'} }++;
# push @{ $HS_bring_subnet::submitted_genes->{$spec}->{$rows->{'optname'}}->{'hsnames'} }, $rows->{'hsname'} 
push @{ $HS_bring_subnet::submitted_genes->{$spec}->{uc($rows->{'optname'})}->{'hsnames'} }, uc($rows->{'hsname'}) 
if $rows->{'hsname'};
$translated_genes->{$spec}->{uc($rows->{'optname'})}->{$rows->{'hsname'}} = $type;
	}

	for $gg ( @{$genes} ) {
		$HS_bring_subnet::submitted_genes->{$spec}->{ uc($gg) }->{'status'} = 'ID not found'
		  if !defined( $HS_bring_subnet::submitted_genes->{$spec}->{ uc($gg) } );
		# push @GO, $gg if $gg =~ m/^\s*GO\:/i;
	}
	# if ( $GO[0] ) {
		# $gene_arr = "\'" . uc( join( "\', \'", @GO ) ) . "\'";
		# $sth =
		  # $dbh->prepare_cached(
# "SELECT hsname FROM $HSconfig::fcgene2go WHERE org_id = ? and go_code IN ($gene_arr)"
		  # )
		  # || die "Failed to prepare SELECT NAMES_by_GO statement 1";
		# $sth->execute($spec);
		# while ( $rows = $sth->fetchrow_hashref ) {
			# $fcgenes->{ $rows->{'hsname'} } = $type
			  # if !defined( $fcgenes->{ $rows->{'hsname'} } )
			  # or $fcgenes->{ $rows->{'hsname'} } ne 'query';
			# $HS_bring_subnet::found_genes->{$spec}->{ $rows->{'hsname'} } = 1;
		# }
	# }

	return ($fcgenes);
}

sub gene_descriptions { #retieves BOTH descriptions and diplay names (= gene symbols)
my($genes, $spec) = @_;
	my ( $rows, $sm, $node_data);

		my $gene_arr = uc( "\'" . join( "\', \'", sort {$a cmp $b} keys( %{ $genes } ) ) . "\'" );
		$sm = "SELECT hsname, showname, description FROM $HSconfig::shownames WHERE upper(hsname) IN ($gene_arr)";
		# my $gene_arr =  "\'" . join( "\', \'", sort {$a cmp $b} keys( %{ $genes } ) ) . "\'" ;
		# $sm = "SELECT hsname, showname, description FROM $HSconfig::shownames WHERE hsname IN ($gene_arr)";
		$sm .= " and org_id = \'$spec\'" if $spec;
		$sm =~ s/[A-Z0-9]\'[A-Z\-\_]//gi; 
		# print $sm.'<br>';
		my $sth = $dbh->prepare_cached($sm)  || die "Failed to prepare SELECT show-names statement";
		$sth->execute();

		while ( $rows = $sth->fetchrow_hashref ) {
			next if defined( $node_data->{ $rows->{hsname} }->{'name'} );
			next
			  if (  defined( $rows->{showname} )
				and defined( $node_data->{ $rows->{hsname} }->{'name'} )
				and $node_data->{ $rows->{hsname} }->{'name'} =~
				m/$rows->{showname}/ );
$node_data->{ $rows->{hsname} }->{'name'} = !$rows->{showname} ? $rows->{hsname} : $rows->{showname};
			$node_data->{ $rows->{hsname} }->{'description'} = $rows->{description};
			$node_data->{ $rows->{hsname} }->{'name'}      = $rows->{hsname};
			$node_data->{ $rows->{hsname} }->{'description'} =~ s/\[.+Acc\:.+\]//;
			$node_data->{ $rows->{hsname} }->{'description'} =~ s/[+\]\[\@]//g;
			$node_data->{ $rows->{hsname} }->{'description'} =~ s/[\|\\\/\"\'\;\,]/_/g;
		}
	return $node_data;
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
