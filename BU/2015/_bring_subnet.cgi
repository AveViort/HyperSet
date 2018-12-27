#!/usr/bin/perl -w
use warnings;
use strict;
use CGI qw(-no_xhtml);
use DBI;
use lmx;
use funcoupweb;

#IN THIS FILE, VARIABLE'S MEANING IS EXPLAINED USUALLY AT THEIR FIRST USE (I.E. LATER THEN AT THE POINT OF DECLARATION WITH 'our' OR 'my'). IT CAN BE OMITTED IN CASE OF A LONG, SELF-EXPLANATORY, NAME - OR SIMPLY OVERLOOKED... :)
#FUNCTION'S MEANING CAN BE FOUND AT FIRST LINE OF IT'S DEFINITION

$ENV{'PATH'} = '/bin:/usr/bin';


our (
$dbh,	$data,                    $node,
	@evOrder,                 $added_top_genes,
	$extra,                   $extra_data,
	$debug,                   $end_it,
	$dataImage,               %nodes,
	%place,                   %present,
	%active_groups,           $show_fbs,
	@linkstubslist,
	$show_annotations,        $show_ihop,
	$show_groups,             @species_of_evidence,
	@types_of_evidence,       @nonconfidence,
	%initSettings,            $coff,
	%FBScol,                  $fc_class,
	$nonconventional,         $jsquid_screen,
	$structured_table,        $single_table,
	$tmpfile,                 $keep_query,
	$uniprot_table,           $coff_class,
	$GO_table,                %GOlocation,
	@genes,                   @context_genes,
	$show_context,            $max_links,
	$pathway_table,           $optnames,
	$fcgene2go,               $pathwayName,
	$pathwaySize,             $pathwayMembership,
	$kegg_id_url,             $FCtypeLinkPrintCutoff,
	$kegg_url,                %fc_url,
	$downloadDir,             $downloadFile,
	%maxPartialFBS,           %val,
	@FBSscale,                $DBtag,
	$weblink,                 %oltag,
	%tag,                     %label,
	%dash,                    %evidenceOrder,
	$deletedByAracne,         $genename,
	$cnts,                    $found_number,
	%linkname,                %hexcolor,
	$scorecol,                $stuff,
	$css_sheet,               $jslocation,
	$picMakerLocation,        $medusaLocation,
	$tmp_loc_path,            $tmp_web_path,
	$runjsquid_path,          $medusaFile,
	$usid,                    $net_max,
	$cladeImage,              %clade_memb,
	%clade,                   %kingdom,
	%class,                   %ID,
	%color,                   %node_color,
	%bzc,                     %shape,
	%img,                     $border,
	$found_neighbors,         $graf_path,
	$desired_nodes,           $displayFCnamesOnly,
	$network,                 $submitted_genes,
	$fcgenes,                 $desired_links_per_query,
	$alreadyIncluded,         $found_genes,
	$found_pairs,             $previouslySelected,
	$inparanoid_table,        $orthologs,
	%ev,                      %species,
	%spec_network,            %org,
	%node_type_ID,            $spec_list,
	$type_list,               $shape_list,
	$render_list,             $nonconventional_pairs,
	$antiCrashLimit,
	$scored_pairs,            %algo_descr,
	$reduction,
	$olDeclaration,           $overDivDeclaration,
	$styleDeclaration,        $scriptDeclaration,
	$legendAside,             $genestring,
	$tag,                     %sty,
	@clade_list,              $XMLcode,
	$show_extra_data,       $repaint_nodes,     %maxLmxContrast,
	$java,                  $submitted_species, @spoe,
	$ortho_render,          @tyoe,              @neis,
	$evgroup,               $cin_class,         $submitted_coff,
	$order,                 $wgversion,         $desired_links_total,
	$qvotering,             $reduce,            $reduce_by,
	$show_names,            $show_homologs,     $show_neighbor,
	$show_GO,               $output,            $base,
	%retrieve,              %defined_FC_types,  $use_nonconventional,
	$time,                  $timing,            $ppi_refs,
	$pairwiseSupplementary, $only_overlap,      $lmx,
	$pw,                    %criteria,          %link_table,
	%profile_table
);
my($wheight, $wwidth);

$time = time();
$debug = 0;
$medusaLocation   = 'http://funcoup.sbc.su.se/java/'; #the JAVA applet is downloaded by the client browser from here
$picMakerLocation = 'http://funcoup.sbc.su.se/cgi-bin/'; #the applet version that generates static network picture
$jslocation       = 'http://funcoup.sbc.su.se/js/'; #javascripts
$graf_path        = 'http://funcoup.sbc.su.se/pics/'; #various icons
$runjsquid_path   = 'http://jsquid.sbc.su.se/start.html'; #do not know what it is... /AA
$tmp_web_path = 'http://funcoup.sbc.su.se/xmlcode/'; #jSquid-compatible XML sources to show  requested networks are stored here - web path
$tmp_loc_path = '/var/www/funcoup.sbc.su.se/tmp/files/xmlcode/'; #same, but internally valid path
system("/usr/sbin/tmpwatch -m 24 $tmp_loc_path");
$css_sheet = 'http://funcoup.sbc.su.se/funcoup_styles.css'; #CSS style sheet
$scorecol   = 'fbs_max'; #in principle, one can query by other likelihhod etc. columns

my $q = new CGI; #new instance of the CGI object passed from the query page index.html
############################ and its parameters are converted to internal variables of this script

#READING CGI PARAMETERS:
if ( defined( $q->param('for_species') ) ) {
#one or many genes are allowed in any space or comma-delimited list	
        $genestring = $q->param('genes');
	$genestring =~ s/^\s+//        if $genestring;
	$genestring =~ s/[\'\"\,\;]/ /g if $genestring;
	@genes = split( /\s+/, uc($genestring) );

	$genestring = $q->param('context_genes');
	$genestring =~ s/^\s+//        if $genestring;
	$genestring =~ s/[\'\"\,\;]/ /g if $genestring;
	@context_genes = split( /\s+/, uc($genestring) );
	if ( $#genes >= 0 ) {
		while ( !$genes[0] ) { shift @genes; }
	}
	if ( $#context_genes >= 0 ) {
		while ( !$context_genes[0] ) { shift @context_genes; }
	}
	$submitted_species = $q->param('for_species');
	$pw                = $q->param('pw');
	$lmx               = ( #this is only needed for specific and test  cases
		     ( $submitted_species eq 'zfish' )
		  or ( defined($pw) and ( $pw eq 'lmx1a-ma' ) )
	) ? 1 : undef;
	if ($lmx) {
if ( $submitted_species eq 'zfish' ) {
			$criteria{contrast}   = $q->param('criterion');
			$criteria{confidence} = $q->param('zfish_confidence');
			$criteria{pairwise}   = $q->param('zfish_relevance');
			$criteria{individual} = $q->param('zfish_2way');
			$repaint_nodes        = 1;
		}}
	$show_context = 'yes' if $context_genes[0]; #enables querying for FC with genes defined in the magenta box of index.html - they don't affect the initial querying
	$java         = $q->param('java'); #tests JAVA version
	$fc_class     = $q->param('fc_class'); #for which FC class the network is retrieved; default: all classes together
#for which sub-set of evidence the network is retrieved (by species or datatype); default: altogether:
	$base         = $q->param('base');
	if    ( $base eq 'all' )     { }
	elsif ( $base eq 'species' ) {
		@spoe = $q->param('species_of_evidence');
		if ( $#spoe < 0 ) { }
	}
	elsif ( $base eq 'types' ) {
		@tyoe = $q->param('types_of_evidence');
		if ( $#tyoe < 0 ) { }
	}
	else { die 'No evidence base defined. Please set values in the section \"Base network links on evidence\"'."\n"; }
#if other species' networks should be shown together:
	$ortho_render = $q->param('ortho_render');
#an in which particular species:
	@neis         = $q->param('network_in_species');
	#$evgroup = $q->param('evidence_group');
# show queried genes/proteins as yellow diamonds:
	$keep_query                         = $q->param('keep_query');

	$submitted_coff                     = $q->param('coff');

	$order                              = $q->param('order'); #network order
#choice of algorithm to reduce too large networks:
	$reduce                             = $q->param('reduce');
	if ($reduce) {
		$reduce_by           = $q->param('reduce_by');
		$desired_links_total = $q->param('no_of_links');
		$qvotering           = $q->param('qvotering');
	}
	else {$desired_links_total = 1000000;}
	$use_nonconventional = $q->param('use_nonconventional'); #show links without FunCoup evidence: miRNA, TF binding, chromosome neighbors etc.
	$only_overlap        = $q->param('only_overlap'); #only such links that coincide with FunCoup ones
	$show_names          = $q->param('show_names');
	$wheight             = $q->param('wheight');
	$wwidth              = $q->param('wwidth');
	$jsquid_screen       = $q->param('jsquid_screen');
	$structured_table    = $q->param('structured_table');
	$single_table        = $q->param('single_table');
}
#END OF READING CGI PARAMETERS
###########################################
$coff               = pgk2fbs($submitted_coff) if defined($submitted_coff); #convert p-cscore to FBS
#Various display parameters:
$show_homologs      = 'yes';
$show_ihop          = 'yes';
$show_neighbor      = 'pathway';
$keep_query         = 0                        if !defined($keep_query);
$show_GO            = 'yes';
$show_fbs           = 1;
$show_extra_data = 1 if $submitted_species eq 'human';
@linkstubslist                      = ( 'ENSEMBL', 'InParanoid' );
$show_annotations                   = 1;
$show_groups                        = 1;
$FCtypeLinkPrintCutoff = 3;
$evgroup               = 'all' if !$evgroup;
#PARAMETERS TO REPLACE CGI IN DEBUG MODE:
$criteria{contrast} = 'd1_vs_d2345'            if !$criteria{contrast};
@genes               = ('1.8.1.9') if !$genes[0];
$submitted_species   = 'mouse'     if !$submitted_species;
$coff                = 0.4         if !$coff;
$output              = 'webgraph'  if !$output;
$wheight             = 640         if !$wheight;
$wwidth              = 800         if !$wwidth;
$reduce_by           = 'noislets'  if !$reduce_by;
$show_names          = 'Names'     if !$show_names;
$desired_links_total = 10          if !$desired_links_total;
$desired_nodes       = 3;
$antiCrashLimit      = 800;
#Displaying the number of links for each node on the global network is only possible with pre-calculated values from a special table, and only at 3 discrete cut-offs; so it is prepared here:
if    ( $submitted_coff < 0.375 ) { $coff_class = 0.25; }
elsif ( $submitted_coff > 0.675 ) { $coff_class = 0.75; }
else { $coff_class = 0.50; }

if ( !$submitted_species || !defined $genes[0] || $#genes < 0 ) {
	print_noquery_dialog();
}
#SQL connection:
my $dsn  = "DBI:Pg:dbname=funcoup";
my $user = 'funcoup';
my $ps   = 'mrd1TP53';
$dbh = DBI->connect( $dsn, $user, $ps ) || die "Failed to connect as $dsn, user $user.../n";
#end of SQL connection

#hack protection:
my ( $gg, $ee, $ss );
for $gg (@genes) {
	$gg =~ s/\s//g;
	if ( $gg !~ m/^[A-Za-z0-9\:\_\-\.]+$/ ) {
		if ( $output eq 'webgraph' ) {
			print $q->header();
			print $q->start_html();
		}
		print $q->h4(
			{ -style => 'Color: red;' },
			$gg
			  . ': invalid input: just use letters, digits, dash, underscore, and dot'
		);
		$end_it = 1;
		goto END_IT1;
	}
}

funcoupweb::define_common_data();
define_data();
$scorecol          = $FBScol{$fc_class}; #which column to use for confidence cut-off
$submitted_species = $species{$submitted_species};

@{$shape_list} = ( 'query', 'context' ); #which shapes to use to highlight submitted IDs etc.
push @{$shape_list}, 'a KEGG pathway member' if $show_neighbor eq 'pathway';
push @{$shape_list}, 'other';
@{$spec_list} = ();
@{$type_list} = ();
push @{$spec_list}, @species_of_evidence;
push @{$type_list}, @types_of_evidence;

if ( lc($ortho_render) ne 'yes' ) {
	@{$render_list} = $submitted_species;
	if ( !$network->{$submitted_species}->{'all'} ) { #error processing when no correct network file is defined for the SQL database
		print
"\nNo functional coupling network defined for $org{$submitted_species}.\n";
		$end_it = 1;
		goto END_IT1;
	}}
else { #define the list of species for simultaneous display
	for $ss (@neis) { push @{$render_list}, $species{$ss}; }}

#THIS LINE RETURNS MOST OF THE DATA TO GENERATE THE RESULT PAGE:
data( \@genes, $coff, $order );
#error processing:
if ( scalar( keys( %{$data} ) ) < 1 ) {
	$end_it = 1;
	error_head();
	print
"\nNo links found in the $org{$submitted_species} network for the submitted ID"
	  . ( scalar(@genes) > 1 ? 's ' : ' ' ) . ':<br>'
	  . join( ", ", (@genes) )
	  . "<br>at this confidence level (final score cutoff = $coff\)\.\n";
	error_foot();
	$end_it = 1;
	goto END_IT1;
}
END_IT1: if ( !$end_it ) { #HERE THE RESULT PAGE IS GENERATED VIA CALLING A CHAIN OF PROCEDURES:
	my ($link_list);
	if ($show_fbs) { @{$link_list} = ( 'fbs', @{$spec_list}, @{$type_list} ); }
	else { @{$link_list} = ( @{$spec_list}, @{$type_list} ); }
	push @{$link_list}, @nonconfidence;
	push @{$link_list}, @{ $defined_FC_types{$submitted_species} };
	if ( lc($ortho_render) eq 'yes' ) {
		push @{$link_list}, 'ortho';
		my ( $spec, $gene, $ortho, $dd, $i, $current_species );
		for $spec ( keys( %{$found_genes} ) ) {
			for $gene ( keys( %{ $orthologs->{$spec} } ) ) {
				for $ortho ( @{ $orthologs->{$spec}->{$gene} } ) {
					next
					  if (
						   !$node->{$ortho}
						or !$node->{$gene}
						or (   $found_pairs->{$spec}->{$gene}->{$ortho}
							or $found_pairs->{$spec}->{$ortho}->{$gene} )
					  );
					$i = pair_sign($ortho, $gene);
					$data->{$i}->{prot1}              = $gene;
					$data->{$i}->{prot2}              = $ortho;
					$data->{$i}->{ortho}              = 'yes';
					$found_pairs->{$spec}->{$gene}->{$ortho}   =
					  $found_pairs->{$spec}->{$ortho}->{$gene} = 'ortho';
				}
			}
		}
	}
	print '<table width="' . $wwidth . '"><tr><td>';
	printEXPLANATION( $data, $network->{$submitted_species}->{'all'} );
	print '</td></tr></table>';
	printCONDITIONS();
	printToXMLjsquid( $wheight, $wwidth, $link_list ) if $jsquid_screen;
	printStructuredTable($link_list) if $structured_table;
	printSingleTable($link_list)     if $single_table;
	$timing .= ( time() - $time ) . ' sec to generate the web page.<br>' . "\n";
	$time = time();

#	print $timing.'<br>'.$lmx.'<br>'."\n";
	printSAVEBUTTON();
	printBOOKMARK();
	printGA();
}
print $q->end_html() . "\n" if ( $output eq 'webgraph' );

sub data { #brings most of the data to display the sub-network
	my ( $genes, $coff, $order ) = @_;
	my ( $source, $gene_arr, $start_species, $current_species, $temp_gene_set,
		$initial_gene_set, @links, $MAtable );

	$start_species = $species{$submitted_species};
	fc_names( $genes, $start_species, 'query' );

#$timing .= '<br>contr: '.$criteria{contrast}.'<br>indiv: '.$criteria{individual}.'<br>pairw: '.$criteria{pairwise}.'<br>';
	if ( $lmx and defined( $criteria{individual} ) ) {
		$MAtable = 'lmx'   if $start_species eq 'mmu';
		$MAtable = 'zfish' if $start_species eq 'dre';
		$added_top_genes = lmx::names_by_top( $MAtable, $start_species )
		  if $MAtable;
		$timing .=
		    "$start_species "
		  . scalar( keys( %{ $found_genes->{$start_species} } ) ) . "\n"
		  . '<br>';
	}
	if ( scalar( keys( %{ $found_genes->{$start_species} } ) ) < 1 ) {
		print_no_id_dialog();
		return;
		error_head();
		print "\nThe $org{$submitted_species} identifier "
		  . ( scalar(@genes) > 1 ? 's ' : ' ' ) . ':<br>'
		  . join( ", ", (@genes) )
		  . '<br>submitted as query is not found in our database.<br>' . "\n";
		error_foot();
		print $q->end_html() . "\n" if ( $output eq 'webgraph' );
		return;
	}

	if ($qvotering) {
		$desired_links_per_query = $desired_links_total /
		  scalar( keys( %{ $found_genes->{$submitted_species} } ) );
		$desired_links_per_query = 5 if $desired_links_per_query < 5;
	}

	if ( $output eq 'webgraph' ) {
		print $q->header();
		print $q->start_html(
			-title   => 'FunCoup sub-network',
			-dtd     => 'HTML 4.0',
			-BGCOLOR => 'white',
			-expires => '-1'
		);
		$styleDeclaration =
		  '<link rel="stylesheet" type="text/css" href="'
		  . $css_sheet . '" />' . "\n";
		print $styleDeclaration. "\n";
		print $olDeclaration. "\n";
		print $scriptDeclaration. "\n";
		print $overDivDeclaration. "\n";
	}

	@{$initial_gene_set} = keys( %{ $found_genes->{$start_species} } );
	if ( grep( /$start_species/, @{$render_list} ) ) {
		fc_links( $initial_gene_set, $start_species );
	}
	$timing .= ( time() - $time ) . ' sec to retrieve FC links.<br>' . "\n";
	$time = time();
	for $current_species ( @{$render_list} ) {
		next if ( $current_species eq $start_species );
		@{$temp_gene_set} =
		  orthologs( $initial_gene_set, $start_species, $current_species );
		fc_links( $temp_gene_set, $current_species );
		@{$temp_gene_set} = keys( %{ $found_genes->{$start_species} } );
		@{$temp_gene_set} =
		  orthologs( $temp_gene_set, $start_species, $current_species );
	}
	if ( lc($ortho_render) eq 'yes' ) {
		$timing .=
		  ( time() - $time )
		  . ' sec to retrieve links among orthologs.<br>' . "\n";
		$time = time();
	}

	nonconventional() if $use_nonconventional;
	if ($lmx) {
		lmx::lmx_data()   if ( lc($submitted_species) eq 'mmu' );
		lmx::zfish_data() if ( lc($submitted_species) eq 'dre' );
	}
	$timing .=
	  ( time() - $time ) . ' sec to retrieve nonconventional links.<br>' . "\n";
	$time = time();
	descriptions();

#$timing .= (time() - $time).' sec to retrieve descriptions.<br>'."\n"; $time = time();
	hubbiness( $node, $coff_class );
	uniprot_ids() if $show_ihop;

#$timing .= (time() - $time).' sec to define hubbiness.<br>'."\n"; $time = time();
	pathway() if $show_neighbor eq 'pathway';

#$timing .= (time() - $time).' sec for pathway members.<br>'."\n"; $time = time();
	GOs() if $show_GO;

	#$timing .= (time() - $time).' sec for GO terms.<br>'."\n"; $time = time();
	extra_data() if $show_extra_data;
	ppi_refs();
	$timing .= ( time() - $time ) . ' sec to retrieve extra data.<br>' . "\n";
	$time = time();
	return undef;
}

sub orthologs { 
#establishes which orthologs should be displayed (in the multi-species mode). If an ortholog does not have relavant links, it won't appear - so it is not a substitute to InParanoid.sbc.su.se
	my ( $genes, $from, $to ) = @_;
	my ( $gene, $rows1, $rows2, @new_genes, $sm1, $sm2 );

	$sm1 =
"SELECT cluster_id from $inparanoid_table inner join optnames1 on optnames1.optname = $inparanoid_table\.fc_name where (pair = ? or pair = ?) and (optname = ? or fcname = ?)";
	$sm2 =
"SELECT fcname from $inparanoid_table  inner join optnames1 on optnames1.optname = $inparanoid_table\.fc_name where (pair = ? or pair = ?) and $inparanoid_table\.org_id = ? and cluster_id = ?";

#	$timing .= '<br>'.$sm1.'<br>';
#	$timing .= '<br>'.$sm2.'<br>';
	my $sth1 = $dbh->prepare_cached($sm1)
	  || die "Failed to prepare SELECT ORTHOLOG CLUSTER_ID statement";
	my $sth2 = $dbh->prepare_cached($sm2)
	  || die "Failed to prepare SELECT ORTHOLOG NAMES statement";
	for $gene ( @{$genes} ) {

		#$timing .= '<br>'.$gene.'<br>';
		$sth1->execute(
			$species{$from} . '-' . $species{$to},
			$species{$to} . '-' . $species{$from},
			$gene, $gene
		);
#	$timing .= ' '.$gene;

		while ( $rows1 = $sth1->fetchrow_hashref ) {
#	$timing .= ' '.$rows1->{'cluster_id'};
			$sth2->execute(
				$species{$from} . '-' . $species{$to},
				$species{$to} . '-' . $species{$from},
				$species{$to}, $rows1->{'cluster_id'}
			);
#	$timing .= '<br>';
			while ( $rows2 = $sth2->fetchrow_hashref ) {
				push @{ $orthologs->{ $species{$from} }->{$gene} },
				  $rows2->{'fcname'};
				push @new_genes, $rows2->{'fcname'};
#	$timing .= ' '.$rows2->{'fcname'};
			}
#	$timing .= '<br>';
		}
	}
	return (@new_genes);
}

sub _pair_sign ($$) {
	my ( $prot1, $prot2 ) = @_;
	if ( $prot1 and $prot2 ) {
		return
		  lc( join( '_#_#_#_', ( sort { $a cmp $b } ( $prot1, $prot2 ) ) ) );
	}
	else { return undef; }
}

sub hubbiness {
	my ( $node, $coff ) = @_;
	my ( $sm, $sth, @genelist, $spec, $genearr, $rows );

	for $spec ( keys( %{$found_genes} ) ) {
		@genelist = keys( %{ $found_genes->{$spec} } );
		$genearr  = "\'" . join( "\', \'", @genelist ) . "\'";
		$sm       =
'select prot as fcname, hubbiness from hubbiness_counts  where version = \''
		  . $network->{$spec}->{'all'}
		  . '\' and org_id = \''
		  . $spec
		  . '\' and cutoff = \''
		  . $coff
		  . '\' and prot IN ('
		  . $genearr . ')';

		#   $timing .= '<br>'.$sm.'<br>';
		$sth = $dbh->prepare_cached($sm)
		  || die "Failed to prepare SELECT statement HUBBINESS\n";
		$sth->execute();
		while ( $rows = $sth->fetchrow_hashref ) {
			$node->{ $rows->{'fcname'} }->{'hubbiness'} = $rows->{'hubbiness'};
		}
	}
	return ($node);
}

sub reduce_subnet { #implements a number of alternative algorithms to reduce too complex networks before displaying them. For description of the algorithms, see http://funcoup.sbc.su.se/algo.html

	my ( $mode, $spec ) = @_;
	my (
		$data_len, $dd,        $p,         @dpairs,
		%is_link,  $qq,        $i,         $j,
		$k,        $not_query, $N_removed, @weakest
	);

	if ( lc($mode) eq 'score' ) {
		@dpairs =
		  sort { $data->{$a}->{'fbs'} <=> $data->{$b}->{'fbs'} }
		  keys( %{$data} );
		while ( scalar( keys( %{$data} ) ) > $desired_links_total ) {
			$p = shift @dpairs;
			remove_existing( $data->{$p}->{'prot1'},
				$data->{$p}->{'prot2'}, $spec );
			delete $data->{$p};
		}
		return undef;
	}
	elsif ( $mode =~ m/aracne/i ) {
		for $i ( sort { $a cmp $b } keys( %{ $found_genes->{$spec} } ) ) {
			for $j ( sort { $a cmp $b } keys( %{ $found_genes->{$spec} } ) ) {
				last if $j eq $i;
				next
				  if (  !$found_pairs->{$spec}->{$i}->{$j}
					and !$found_pairs->{$spec}->{$j}->{$i} );
				for $k ( sort { $a cmp $b } keys( %{ $found_genes->{$spec} } ) )
				{
					last if $j eq $i;
					next
					  if (  !$found_pairs->{$spec}->{$i}->{$k}
						and !$found_pairs->{$spec}->{$k}->{$i} );
					next
					  if (  !$found_pairs->{$spec}->{$k}->{$j}
						and !$found_pairs->{$spec}->{$j}->{$k} );
					@weakest = ( $i, $j ) if ( !extraSupport( $i, $j, $spec ) );
					@weakest = ( $i, $k )
					  if ( !extraSupport( $i, $k, $spec ) )
					  and ( $scored_pairs->{$spec}->{$i}->{$k}->{$scorecol} <
						$scored_pairs->{$spec}->{ $weakest[0] }->{ $weakest[1] }
						->{$scorecol} );
					@weakest = ( $j, $k )
					  if ( !extraSupport( $j, $k, $spec ) )
					  and ( $scored_pairs->{$spec}->{$j}->{$k}->{$scorecol} <
						$scored_pairs->{$spec}->{ $weakest[0] }->{ $weakest[1] }
						->{$scorecol} );
					next
					  if (
						$found_pairs->{$spec}->{ $weakest[0] }->{ $weakest[1] }
						eq 'delete' );
					$deletedByAracne++;
					$found_pairs->{$spec}->{ $weakest[0] }->{ $weakest[1] }   =
					  $found_pairs->{$spec}->{ $weakest[1] }->{ $weakest[0] } =
					  'delete';
				}
			}
		}
		for $p ( keys( %{$data} ) ) {
			if ( $found_pairs->{$spec}->{ $data->{$p}->{'prot1'} }
				->{ $data->{$p}->{'prot2'} } eq 'delete' )
			{
				remove_existing( $data->{$p}->{'prot1'},
					$data->{$p}->{'prot2'}, $spec );
				delete $data->{$p};
			}
		}
		return undef;
	}
	elsif ( ( $mode eq 'maxcoverage' ) or ( $mode eq 'noislets' ) ) {
		@dpairs =
		  sort { $data->{$a}->{'fbs'} <=> $data->{$b}->{'fbs'} }
		  keys( %{$data} );
		$max_links = $desired_links_total;
		$max_links += $alreadyIncluded if defined($alreadyIncluded);
	  REDO1: while ( scalar( keys( %{$data} ) ) > $max_links ) {
			$i         = -1;
			$N_removed = 0;
			for $p (@dpairs) {
				$dd = $data->{$p};
				$i++;
				next
				  if ( lc($mode) eq 'noislets' )
				  and
				  ( $previouslySelected->{ $dd->{'prot1'} }->{ $dd->{'prot2'} }
					or $previouslySelected->{ $dd->{'prot2'} }
					->{ $dd->{'prot1'} } );
				if (
					(
						    $fcgenes->{ $dd->{'prot1'} }
						and $fcgenes->{ $dd->{'prot1'} } =~ m/query|context/i
					)
					or (    $fcgenes->{ $dd->{'prot2'} }
						and $fcgenes->{ $dd->{'prot2'} } =~ m/query|context/i )
				  )
				{
					next
					  if (
						(
							    $fcgenes->{ $dd->{'prot1'} }
							and $fcgenes->{ $dd->{'prot1'} } =~
							m/query|context/i
						)
						and (   $fcgenes->{ $dd->{'prot2'} }
							and $fcgenes->{ $dd->{'prot2'} } =~
							m/query|context/i )
					  );
					if ( defined( $fcgenes->{ $dd->{'prot1'} } )
						and $fcgenes->{ $dd->{'prot1'} } =~ m/query|context/i )
					{
						$not_query = $dd->{'prot2'};
					}
					elsif ( defined( $fcgenes->{ $dd->{'prot2'} } )
						and $fcgenes->{ $dd->{'prot2'} } =~ m/query|context/i )
					{
						$not_query = $dd->{'prot1'};
					}
					else {
						die 'An error with query genes '
						  . $dd->{'prot1'} . ', '
						  . $dd->{'prot2'} . "...\n";
					}
					if (
						$qvotering
						and
						( scalar( keys(%is_link) ) <= $desired_links_per_query )
					  )
					{
						for $qq (
							keys( %{ $found_pairs->{$spec}->{$not_query} } ) )
						{
							$is_link{$not_query}++
							  if defined( $fcgenes->{$qq} )
							  and $fcgenes->{$qq} =~ m/query|context/i;
						}
						next if ( $is_link{$not_query} > 1 );
						delete $is_link{$not_query};
					}
					next
					  if (
						(
							(
								defined( $fcgenes->{ $dd->{'prot1'} } )
								and $fcgenes->{ $dd->{'prot1'} } =~ m/query/i
							)
							and ( $found_genes->{$spec}->{ $dd->{'prot1'} } <
								$desired_links_per_query )
						)
						or (
							(
								defined( $fcgenes->{ $dd->{'prot2'} } )
								and $fcgenes->{ $dd->{'prot2'} } =~ m/query/i
							)
							and ( $found_genes->{$spec}->{ $dd->{'prot2'} } <
								$desired_links_per_query )
						)
					  );
				}
				delete $data->{$p};
				splice( @dpairs, $i, 1 );

				if (
					( lc($mode) ne 'noislets' )
					or ( !$previouslySelected->{ $dd->{'prot1'} }
						->{ $dd->{'prot2'} }
						and !$previouslySelected->{ $dd->{'prot2'} }
						->{ $dd->{'prot1'} } )
				  )
				{
					remove_existing( $dd->{'prot1'}, $dd->{'prot2'}, $spec );
					$N_removed++;
				}
				goto REDO1;
			}
			return undef if !$N_removed;
		}
	}
	return undef;
}

sub remove_existing ($$$) { #removes entries, and their respective counts, after the network reduction
	my ( $prot1, $prot2, $spec ) = @_;
	$found_pairs->{$spec}->{$prot1}->{$prot2}--;
	$found_pairs->{$spec}->{$prot2}->{$prot1}--;
	delete $found_pairs->{$spec}->{$prot1}->{$prot2}
	  if $found_pairs->{$spec}->{$prot1}->{$prot2} < 1;
	delete $found_pairs->{$spec}->{$prot2}->{$prot1}
	  if $found_pairs->{$spec}->{$prot2}->{$prot1} < 1;
	$found_genes->{$spec}->{$prot1}--;
	$found_genes->{$spec}->{$prot2}--;
	delete $found_genes->{$spec}->{$prot1}
	  if scalar( keys( %{ $found_pairs->{$spec}->{$prot1} } ) ) < 1;
	delete $found_genes->{$spec}->{$prot2}
	  if scalar( keys( %{ $found_pairs->{$spec}->{$prot2} } ) ) < 1;
	return undef;
}

sub fc_names { # for submitted ARBITRARY gene/protein/enzime/pathway/GO IDs, finds reference IDs (normally ENSEMBL gene IDs)
	my ( $genes, $spec, $type ) = @_;
	my ( $rows, $gene_arr, $sth, @GO );

	$gene_arr = "\'" . uc( join( "\', \'", @{$genes} ) ) . "\'";
	$sth =
	  $dbh->prepare_cached(
"SELECT optname, fcname FROM  $optnames WHERE org_id = ? and upper(optname) IN ($gene_arr)"
	  )
	  || die "Failed to prepare SELECT statement 1";
	$sth->execute($spec);
	while ( $rows = $sth->fetchrow_hashref ) {
		$fcgenes->{ $rows->{'fcname'} } = $type
		  if !defined( $fcgenes->{ $rows->{'fcname'} } )
		  or ( $fcgenes->{ $rows->{'fcname'} } ne 'query' );
		$found_genes->{$spec}->{ $rows->{'fcname'} }++;
		push @{ $submitted_genes->{$spec}->{ uc( $rows->{'optname'} ) }
			  ->{'fcnames'} }, uc( $rows->{'fcname'} )
		  if $rows->{'fcname'};
	}

	for $gg ( @{$genes} ) {
		$submitted_genes->{$spec}->{ uc($gg) }->{'status'} = 'ID not found'
		  if !defined( $submitted_genes->{$spec}->{ uc($gg) } );

		push @GO, $gg if $gg =~ m/^\s*GO\:/i;

	}
	if ( $GO[0] ) {
		$gene_arr = "\'" . uc( join( "\', \'", @GO ) ) . "\'";
		$sth =
		  $dbh->prepare_cached(
"SELECT fcname FROM $fcgene2go WHERE org_id = ? and go_code IN ($gene_arr)"
		  )
		  || die "Failed to prepare SELECT NAMES_by_GO statement 1";
		$sth->execute($spec);
		while ( $rows = $sth->fetchrow_hashref ) {
			$fcgenes->{ $rows->{'fcname'} } = $type
			  if !defined( $fcgenes->{ $rows->{'fcname'} } )
			  or $fcgenes->{ $rows->{'fcname'} } ne 'query';
			$found_genes->{$spec}->{ $rows->{'fcname'} } = 1;
		}
	}

	return ();
}

sub extraSupport ($$$) { #works if PPI-based links are NOT subject to reduction
	my ( $A, $B, $sp ) = @_;
	my ( $required_algo, $required_data, $cutoff );

	$required_algo = 'ARACNE_ppi';
	$required_data = 'ppi';
	$cutoff        = 3;
	return undef if $reduce_by !~ m/$required_algo/i;
	return undef;
}

sub fc_links { #the main procedure of sub-network retrieval. Note that it iterates until the required network order is explored (although $order = 1 is the most common mode)
	my ( $gene_list, $spec ) = @_;
	my (
		$rows,      $oo,   $ee,       $sum, %filter,      $dd,
		$j,         $p,    @fld_list, $sm,  $gene_arr,    $union,
		$name_cond, $pnum, $s,        $i,   $scorecol_as, $prot1,
		$prot2,     $pair, $fc_cl
	);

	$fc_cl = $network->{$spec}->{'all'};
	$i     = 0;
	for $ee ( @spoe, @tyoe ) { $filter{$ee} = 1 if $ee; }
	undef @fld_list;
	push @fld_list, ( $scorecol . ' as fbs ' );
	push @fld_list, '*';

	for $oo ( 1 .. ( $order + 1 ) ) {
		if ( $show_context and ( $oo == $order + 1 ) ) {
			fc_names( \@context_genes, $species{$submitted_species}, 'context' )
			  if $show_context;
		}
		if ( $oo == 1 ) {
			$gene_arr = "\'" . join( "\', \'", @{$gene_list} ) . "\'";
		}
		else {
			$gene_arr = "\'"
			  . join( "\', \'", keys( %{ $found_genes->{$spec} } ) ) . "\'";
		}

		if ( $oo == $order + 1 ) {
			$name_cond =
			  " \(prot1 IN \( $gene_arr \) AND prot2 IN \( $gene_arr \)\)";
		}
		else {
			$name_cond =
			  " \(prot1 IN \( $gene_arr \) OR prot2 IN \( $gene_arr \)\)";
		}
		$sm = "SELECT "
		  . ( join( ', ', (@fld_list) ) )
		  . " FROM $fc_cl WHERE $name_cond AND $scorecol > $coff order by $scorecol desc";

		#  $timing .= '<br>'.$sm.'<br>';
		#print '<br>'.$sm.'<br>';
		my $sth = $dbh->prepare_cached($sm)
		  || die "Failed to prepare SELECT statement FC\n";
		$sth->execute();
		$j = 0;
		while ( $rows = $sth->fetchrow_hashref ) {
			next
			  if ( $found_pairs->{$spec}->{ $rows->{prot1} }->{ $rows->{prot2} }
				and
				$found_pairs->{$spec}->{ $rows->{prot2} }->{ $rows->{prot1} } );
			if ( $base ne 'all' ) {
				$sum = 0;
				for $ee ( keys(%filter) ) {
					$sum += $rows->{$ee} if defined( $rows->{$ee} );
				}
				next if $sum < $coff;
			}
			$i = pair_sign( $rows->{prot1}, $rows->{prot2} );
			$data->{$i}->{'species'} = $spec;

			for $ee ( keys( %{$rows} ) ) {
				$data->{$i}->{$ee} = $rows->{$ee};    # if ($retrieve{$ee});
			}
			$j++;
			$scored_pairs->{$spec}->{ $rows->{prot1} }->{ $rows->{prot2} }
			  ->{$scorecol} =
			  $scored_pairs->{$spec}->{ $rows->{prot2} }->{ $rows->{prot1} }
			  ->{$scorecol} = $rows->{$scorecol};
			$scored_pairs->{$spec}->{ $rows->{prot1} }->{ $rows->{prot2} }
			  ->{'ppi'} =
			  $scored_pairs->{$spec}->{ $rows->{prot2} }->{ $rows->{prot1} }
			  ->{'ppi'} = $rows->{'ppi'};
			$found_genes->{$spec}->{ $rows->{prot1} }++;
			$found_genes->{$spec}->{ $rows->{prot2} }++;
			$found_pairs->{$spec}->{ $rows->{prot1} }->{ $rows->{prot2} }++;
			$found_pairs->{$spec}->{ $rows->{prot2} }->{ $rows->{prot1} }++;
		}
		next if scalar( keys( %{$data} ) ) < 0;
		$found_number += $j;
		$cnts->{$spec}->{$oo}->{before} = scalar( keys( %{$data} ) );
		$cnts->{$spec}->{$oo}->{co}     = $coff;
		if ($reduce) {
			$reduction = lc($reduce_by);
			reduce_subnet( $reduction, $spec )
			  if ( ( $reduction eq 'maxcoverage' )
				or ( $reduction eq 'noislets' )
				or ( $reduction =~ m/aracne/i ) );
		}

		$cnts->{$spec}->{$oo}->{after} = scalar( keys( %{$data} ) );
		if ( ( $reduction eq 'noislets' ) ) {
			$alreadyIncluded = scalar( keys( %{$data} ) );
			for $p ( keys( %{$data} ) ) {
				$previouslySelected->{ $data->{$p}->{'prot1'} }
				  ->{ $data->{$p}->{'prot2'} } =
				  $previouslySelected->{ $data->{$p}->{'prot2'} }
				  ->{ $data->{$p}->{'prot1'} } = 1;
			}
		}
	}
	return undef;
}

sub descriptions { #retieves BOTH descriptions and diplay names (= gene symbols)
	my ( $rows, $AND, $OR, @gene_list, $spec, $sm );

	my $showname = 'showname' if !$displayFCnamesOnly;
	for $spec ( keys( %{$found_genes} ) ) {
		@gene_list = keys( %{ $found_genes->{$spec} } );

		my $gene_arr = uc( "\'" . join( "\', \'", @gene_list ) . "\'" );
		$sm =
"SELECT fcname, $showname, description FROM shownames1 WHERE upper(fcname) IN ($gene_arr) and org_id = \'$species{$spec}\'";
		my $sth = $dbh->prepare_cached($sm)
		  || die "Failed to prepare SELECT show-names statement";
		$sth->execute();
		while ( $rows = $sth->fetchrow_hashref ) {
			next if defined( $node->{ $rows->{fcname} }->{'showname'} );
			next
			  if (  defined( $rows->{showname} )
				and defined( $node->{ $rows->{fcname} }->{'showname'} )
				and $node->{ $rows->{fcname} }->{'showname'} =~
				m/$rows->{showname}/ );
			if ( $show_names eq 'Names' ) {

#$node->{$rows->{fcname}}->{'showname'} = $rows->{fcname} if !defined($node->{$rows->{fcname}}->{'showname'});
#$node->{$rows->{fcname}}->{'showname'} =  $species{$spec}.'_'.$node->{$rows->{fcname}}->{'showname'} if ($ortho_render eq 'yes');

				$node->{ $rows->{fcname} }->{'showname'} = (
					!$rows->{showname} ? $rows->{fcname}
					: ( $ortho_render eq 'yes' )
					? ( $species{$spec} . '_' . $rows->{showname} )
					: $rows->{showname}
				);

			}
			$node->{ $rows->{fcname} }->{'description'} = $rows->{description};
			$node->{ $rows->{fcname} }->{'fcname'}      = $rows->{fcname};
		}
	}

	for $spec ( keys( %{$found_genes} ) ) {
		for $gg ( keys( %{ $found_genes->{$spec} } ) ) {
			$node->{$gg}->{'species'}   = $spec;
			$node->{$gg}->{'node_type'} = 'query'
			  if $keep_query
			  and $fcgenes->{$gg}
			  and $fcgenes->{$gg} eq 'query';
			$node->{$gg}->{'node_type'} = 'context'
			  if $keep_query
			  and $fcgenes->{$gg}
			  and $fcgenes->{$gg} eq 'context';
			$node->{$gg}->{'node_type'} = '0' if !$node->{$gg}->{'node_type'};
			if ( $node->{$gg}->{'description'} ) {
				( $node->{$gg}->{'description'}, $node->{$gg}->{'sptr'} ) =
				  ( $1, $2 )
				  if $node->{$gg}->{'description'} =~ m/(.+)\[.+Acc\:(.+)\]/;
				$node->{$gg}->{'description'}      =~ s/[\>\<\&]//g;
				$node->{$gg}->{'full_description'} =
				  $node->{$gg}->{'description'};
				$node->{$gg}->{'description'} =~ s/[\'\"\(\)\;\,]//g;
				$node->{$gg}->{'description'} =~ s/[\s\.]+$//g;
				$node->{$gg}->{'description'} =
				  substr( $node->{$gg}->{'description'}, 0, 150 ) . '...'
				  if length( $node->{$gg}->{'description'} ) > 150;
			}
			$node->{$gg}->{'showname'} = $gg if !$node->{$gg}->{'showname'};
			$node->{$gg}->{'showname'} =
			  substr( $node->{$gg}->{'showname'}, 0, 80 );
			$node->{$gg}->{'showname'} =~ s/[+\]\[\@]//g;
			$node->{$gg}->{'showname'} =~ s/[\|\\\/\"\'\;\,]/_/g;
		}
	}

	return undef;
}

sub pathway { #retrieves KEGG (normally) pathway membership and defines respective variables
	my ( %node_type_ID, $rows, @gene_list, $spec, $sm );

	for $spec ( keys( %{$found_genes} ) ) {
		push @gene_list, keys( %{ $found_genes->{$spec} } );
	}
	my $gene_arr = uc( "\'" . join( "\', \'", @gene_list ) . "\'" );
	$sm =
"SELECT fcname as fcname, pathway, ec, org_id, kegg_id, description FROM $pathway_table WHERE fcname IN ("
	  . $gene_arr . ")";

	#$timing .= '<br>'.$sm.'<br>';
	my $sth = $dbh->prepare_cached($sm)
	  || die "Failed to prepare SELECT PATHWAY statement";
	$sth->execute;
	my $n = 0;
	while ( $rows = $sth->fetchrow_hashref ) {
		next if $rows->{'pathway'} !~ m/[0-9]/;
		$rows->{'description'} =~ s/[\>\<\&\'\"]//g;

		if ( 1 == 1 or !$node->{ $rows->{fcname} }->{'node_type'} ) {
			$node_type_ID{ $rows->{'pathway'} } = ++$n
			  if !$node_type_ID{ $rows->{'pathway'} };
			$node_type_ID{ $rows->{'pathway'} } = $rows->{'pathway'};
			$node->{ $rows->{'fcname'} }->{'node_type'} = $rows->{'pathway'}
			  if !$node->{ $rows->{'fcname'} }->{'node_type'};

			$rows->{'pathway'} =~ s/KEGG//i;
			$pathwaySize->{ $rows->{'pathway'} }++;
			$pathwayName->{ $rows->{'pathway'} } = $rows->{'description'};
			%{ $pathwayMembership->{ $rows->{'fcname'} }->{'pathway'}
				  ->{ $rows->{'pathway'} } } =
			  ( 'description', $rows->{'description'}, 'ec', $rows->{'ec'} );
			$pathwayMembership->{ $rows->{'fcname'} }->{'kegg_id'}
			  ->{ $rows->{'kegg_id'} } = 1;
		}
	}

	return undef;
}

sub GOs { #retrieves GO category membership and defines respective variables
	my ($node) = @_;
	my ( %node_type_ID, $rows, @gene_list, $spec, $sm );

	for $spec ( keys( %{$found_genes} ) ) {
		push @gene_list, keys( %{ $found_genes->{$spec} } );
	}
	my $gene_arr = uc( "\'" . join( "\', \'", @gene_list ) . "\'" );
	$sm =
"SELECT upper(fcname) as fcname, go_code, org_id FROM $GO_table WHERE fcname IN ("
	  . $gene_arr . ")";
	my $sth = $dbh->prepare_cached($sm)
	  || die "Failed to prepare SELECT GO statement";
	$sth->execute;
	my $n = 0;
	while ( $rows = $sth->fetchrow_hashref ) {
		$pathwayMembership->{ $rows->{'fcname'} }->{'go_code'} =
		  $rows->{'go_code'}
		  if defined( $GOlocation{ $rows->{'go_code'} } );
	}
	return ($node);
}

sub extra_data { #collects additional IDs to show in pop-up link menues
	my ( %node_type_ID, $rows, @gene_list, $spec, $sm );

	for $spec ( keys( %{$found_genes} ) ) {
		push @gene_list, keys( %{ $found_genes->{$spec} } );
	}
	my $gene_arr = uc( "\'" . join( "\', \'", @gene_list ) . "\'" );
	$sm = "SELECT * FROM $extra_data WHERE fcname IN (" . $gene_arr . ")";
	my $sth = $dbh->prepare_cached($sm)
	  || die "Failed to prepare SELECT EXTRADATA statement";
	$sth->execute;
	my $n = 0;
	while ( $rows = $sth->fetchrow_hashref ) {
		$extra->{ $rows->{'fcname'} }->{'HPA'} = $rows->{'hpa'};
	}
	return undef;
}

sub uniprot_ids {#collects Swiss-Prot IDs to show in pop-up link menues
	my ( %node_type_ID, $rows, @gene_list, $spec, $sm );

	for $spec ( keys( %{$found_genes} ) ) {
		push @gene_list, keys( %{ $found_genes->{$spec} } );
	}
	my $gene_arr = uc( "\'" . join( "\', \'", @gene_list ) . "\'" );
	$sm = "SELECT * FROM $uniprot_table WHERE fcname IN (" . $gene_arr . ")";
	my $sth = $dbh->prepare_cached($sm)
	  || die "Failed to prepare SELECT UniProt IDs statement";
	$sth->execute;
	while ( $rows = $sth->fetchrow_hashref ) {
		next if $rows->{'sptr'} =~ m/\_/;
		$extra->{ $rows->{'fcname'} }->{'uniprot'} = $rows->{'sptr'};
	}
	return undef;
}

sub ppi_refs {#collects additional data to show in PPI with source of evidence in pop-up link menues
	my (
		$sm,        $i,    $rows, $gene_arr, $say, $text,
		@gene_list, $spec, $ee,   $value,    $label
	);

	@gene_list = keys( %{ $found_genes->{$submitted_species} } );
	$gene_arr  = uc( "\'" . join( "\', \'", @gene_list ) . "\'" );
	$sm        =
"SELECT * FROM $ppi_refs WHERE org_id = '$submitted_species' and \(ensgene1 IN \( $gene_arr \) AND ensgene2 IN \( $gene_arr \)\)";
	my $sth = $dbh->prepare_cached($sm)
	  || die "Failed to prepare SELECT $ppi_refs statement";
	$sth->execute;
	while ( $rows = $sth->fetchrow_hashref ) {
		$text =
		  removeJunk(
			uc( $rows->{method} ) . ' experiment by ' . $rows->{exp_label} );
		$text = 'Inferred by curator'
		  if $rows->{method} =~ m/INFER.+BY.+CURATOR/i;
		$text .= ' (IntAct)';
		$text = 'HPRD' if $rows->{exp_label} =~ m/^HPRD$/i;
		$text = 'BIND' if $rows->{exp_label} =~ m/^BIND$/i;
		$say  = $text;
		$say  =
		    '<a href=\\\''
		  . pubmedLink( $rows->{pmid} )
		  . '\\\' TARGET=\\\'_blank\\\'>'
		  . $text . '</a>'
		  if ( $rows->{pmid} =~ m/^[0-9]+$/ );
		$i =
		  (
			defined(
				$pairwiseSupplementary->{ $rows->{ensgene1} }
				  ->{ $rows->{ensgene2} }
			)
		  )
		  ? scalar @{ $pairwiseSupplementary->{ $rows->{ensgene1} }
			  ->{ $rows->{ensgene2} } }
		  : 0;
		$label = $say
		  . (
			join( '.',
				sort { $a cmp $b } ( $rows->{ensgene1}, $rows->{ensgene1} ) )
		  );
		next if $pairwiseSupplementary->{$label};
		%{ $pairwiseSupplementary->{ $rows->{ensgene1} }->{ $rows->{ensgene2} }
			  ->[$i] } =
		  %{ $pairwiseSupplementary->{ $rows->{ensgene2} }
			  ->{ $rows->{ensgene1} }->[$i] } =
		  ( text => $say, pmid => $rows->{pmid} );
		$pairwiseSupplementary->{$say} = 1;
		next;
		%{ $pairwiseSupplementary->{ $rows->{ensgene1} }->{ $rows->{ensgene2} }
			  ->[$i] } =
		  %{ $pairwiseSupplementary->{ $rows->{ensgene2} }
			  ->{ $rows->{ensgene1} }->[$i] } = (
			org_id         => $rows->{org_id},
			exp_label      => $rows->{exp_label},
			method         => $rows->{method},
			interaction_id => $rows->{interaction_id},
			uniprot1       => $rows->{uniprot1},
			ensgene1       => $rows->{ensgene1},
			prot1role      => $rows->{prot1role},
			uniprot2       => $rows->{uniprot2},
			ensgene2       => $rows->{ensgene2},
			prot2role      => $rows->{prot2role},
			  );
	}
	return undef;
}

sub nonconventional { #collects additional  data to show links related to shared miRNA, TF binding, chromosome info etc - these do not require FunCoup evidence and have zero confidence
	my ( $i, $rows, $gene_arr, @gene_list, $spec, $ee, $value, $sm );

	for $spec ( keys( %{$found_genes} ) ) {
		@gene_list = keys( %{ $found_genes->{$spec} } );
		my $gene_arr = uc( "\'" . join( "\', \'", @gene_list ) . "\'" );
		$sm =
"SELECT * FROM $nonconventional WHERE prot1 IN \( $gene_arr \) OR prot2 IN \( $gene_arr \)";
		my $sth = $dbh->prepare_cached($sm)
		  || die "Failed to prepare SELECT $nonconventional statement";

		#$timing .= '<br>'.$sm.'<br>';
		$sth->execute;
		while ( $rows = $sth->fetchrow_hashref ) {
			$i = pair_sign( $rows->{prot1}, $rows->{prot2} );
			$data->{$i}->{'species'} = $rows->{org_id};
			$found_genes->{$spec}->{ $rows->{prot1} }++;
			$found_genes->{$spec}->{ $rows->{prot2} }++;
			$node->{ $rows->{prot1} }->{'count'}++
			  if ( $rows->{'type'} eq 'mirna_tg' );
			$node->{ $rows->{prot1} }->{'node_type'} = 'mirna'
			  if ( $rows->{'type'} =~ m/mirna/i );
			$node->{ $rows->{prot1} }->{'node_type'} = 'tf'
			  if ( $rows->{'type'} =~ m/tf/i );
			$nonconventional_pairs->{ $rows->{prot2} }->{ $rows->{prot1} }   =
			  $nonconventional_pairs->{ $rows->{prot1} }->{ $rows->{prot2} } =
			  1;

			for $ee ( keys( %{$rows} ) ) {
				if ( $ee eq 'type' ) {
					$data->{$i}->{ $rows->{'org_id'} } = 0.001;
					$data->{$i}->{ $rows->{$ee} } =
					  ( $rows->{'type'} eq 'mirna_tg' ) ? $rows->{label} : 1.5;
				}
				else {
					$data->{$i}->{$ee} = $rows->{$ee};
				}
			}
		}
	}
	return undef;
}

sub xmlWrap {
	my ( $tag, $data ) = @_;
	my $delim = ( length($data) > 64 ) ? "\n" : '';
	return (
		'<' . $tag . '>' . $delim . $data . $delim . '</' . $tag . '>' . "\n" );
}

sub printSAVEBUTTON {
	print '<P class="bookmark"><a href="'
	  . $tmp_web_path
	  . $tmpfile
	  . '" target="_blank"><img src="'
	  . $graf_path
	  . 'save.png">&nbsp;Save the XML code of the network graph</a> to open it at&nbsp;<a href="'
	  . $runjsquid_path
	  . '" target="_blank">jSquid web page</a> (removed after 1 day)</P>';

}

sub printBOOKMARK { #bookmark down the page

	print '<P class="bookmark"><a href="'
	  . selfLink( $q->query_string )
	  . '" target="_blank"><img src="'
	  . $graf_path
	  . 'bookmark.png">&nbsp;Bookmark this page to re-query the on-line database (both graph and the tables)</a> later</P>';
}

sub printGA {	#Google Analytics
	print qq{<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
try {
var pageTracker = _gat._getTracker("UA-9680767-2");
pageTracker._trackPageview();
} catch(err) {}</script>};

#	print "\n" . '<script type="text/javascript">
#var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
#document.write(unescape("%3Cscript src=\'" + gaJsHost + "google-analytics.com/ga.js\' type=\'text/javascript\'%3E%3C/script%3E"));
#</script>
#<script type="text/javascript">
#var pageTracker = _gat._getTracker("UA-2561568-1");
#pageTracker._initData();
#pageTracker._trackPageview();
#</script>' . "\n";
}

sub prnNODEGROUPS { #a part of jSquid XML syntax
	my ( @group, $i, $l );
	for $l ( sort { $a cmp $b } keys( %{$pathwaySize} ) ) {
		if ( $pathwaySize->{$l} > 0 ) {
			$active_groups{ $pathwayName->{$l} } = 1;
			push @group, '<nodegroup name="' . $pathwayName->{$l} . '"/>';
		}
	}
	push @group, '<nodegroup name="Sub-Cell Location"/>';
	return undef if !defined( $group[0] );
	return xmlWrap( 'nodegroups', join( "\n", @group ) );
}

sub prnINTERACTION {  #a part of jSquid XML syntax
	my ( @ty, @sp, @pl, @nc, $id, $ee );

	for $ee (@types_of_evidence) {
		if ( 1 == 1 or $present{$ee} ) {
			push @ty,
			  '<type ID="'
			  . ++$id
			  . '" name="'
			  . $sty{$ee}
			  . '" color="'
			  . $color{ $ID{$ee} } . '"/>';
			$place{ $ID{$ee} } = $id;
		}
	}
	for $ee (@species_of_evidence) {
		if ( $present{$ee} ) {
			push @sp,
			  '<spec ID="'
			  . ++$id
			  . '" name="'
			  . $sty{$ee}
			  . '" color="'
			  . $color{ $ID{$ee} } . '"/>';
			$place{ $ID{$ee} } = $id;
		}
	}
	for $ee ( @{ $defined_FC_types{$submitted_species} } ) {

		#if ($present{$ee}) {
		push @pl,
		  '<link ID="'
		  . ++$id
		  . '" name="'
		  . $sty{$ee}
		  . '" color="'
		  . $color{ $ID{$ee} } . '"/>';
		$place{ $ID{$ee} } = $id;

		#}
	}
	for $ee (@nonconfidence) {
		push @nc,
		  '<nonConf  ID="'
		  . ++$id
		  . '" name="'
		  . $sty{$ee}
		  . '" color="'
		  . $color{ $ID{$ee} }
		  . ( $dash{ $ID{$ee} } ? '" dashes="' . $dash{ $ID{$ee} } . '"' : '"' )
		  . ' checked="'
		  . ( ( ( $ee eq 'lmx' ) or ( $ee =~ /ortho/i ) ) ? 'true' : 'false' )
		  . '"/>';
		$place{ $ID{$ee} } = $id;

		#}
	}
	return xmlWrap(
		'interaction',
		join(
			"\n",
			(
				( $ty[0] ? xmlWrap( 'types',   join( "\n", @ty ) ) : '' ),
				( $sp[0] ? xmlWrap( 'species', join( "\n", @sp ) ) : '' ),
				(
					$pl[0] ? xmlWrap( 'predictedLinks', join( "\n", @pl ) ) : ''
				),
				(
					( $java and $nc[0] )
					? xmlWrap( 'nonConfidence', join( "\n", @nc ) )
					: ''
				)
			)
		)
	);
}

sub prnEDGES { #a part of jSquid XML syntax; prints network link definitions with multiple lines etc.
	my ($ll) = @_;
	my ( @edge, $max, $spr, $current_species, $dd, $spec, $fc_cl, $i, $node1,
		$node2, @link_list, $fbs_sum, $fbs_SUM, $ii, $pp );

	for $pp ( keys( %{$data} ) ) {
		$dd              = $data->{$pp};
		$current_species = $dd->{'species'};
		print "Orphan: no species found for gene pair "
		  . $dd->{'prot1'}
		  . ' and  '
		  . $dd->{'prot2'}
		  . "\! $pp \n" . '<br>'
		  if ( !$current_species and !$dd->{'ortho'} );
		$fc_cl = $network->{$current_species}->{'all'};
		$node1 = $dd->{'prot1'};
		$node2 = $dd->{'prot2'};
		next if $only_overlap and !$nonconventional_pairs->{$node1}->{$node2};
		next
		  if $dd->{'mirna_tg'}
		  and ( $node->{$node1}->{'count'} < 2 );    # and $dd->{'label'} < 3);
		undef $fbs_sum;

		for $ii ( 0 .. $#species_of_evidence ) {
			$fbs_sum->{spec} += $dd->{ $species_of_evidence[$ii] }
			  if defined( $dd->{ $species_of_evidence[$ii] } );
		}
		for $ii ( 0 .. $#types_of_evidence ) {
			$fbs_sum->{type} += $dd->{ $types_of_evidence[$ii] }
			  if defined( $dd->{ $types_of_evidence[$ii] } );
		}
		for $ee ( @{$ll} ) {
			next if !$dd->{$ee};
			undef $spr;
			if (   ( $ee eq 'blast_score' and $dd->{$ee} =~ m/[A-Za-z0-9]/ )
				or ( $ee eq 'ortho' and $dd->{$ee} =~ m/[A-Za-z0-9]/ )
				or ( $lmx and ( ( $ee =~ /zfish/i ) or ( $ee =~ /lmx/i ) ) ) )
			{
				$spr = '0.50';
			}
			else {
				if ( $dd->{$ee} )
				{
					if ( lc($ee) eq 'fbs' ) {
						chomp( $spr =
							  sprintf( "%3.2f", fbs2pgk( $dd->{fbs} ) ) );
					}
					else {
						$fbs_SUM =
						  ( defined( $species{$ee} ) ) ? $fbs_sum->{spec}
						  : (
							defined( $evidenceOrder{$ee} ) ? $fbs_sum->{type}
							: undef
						  );
						if ( defined($fbs_SUM) ) {
							chomp(
								$spr = sprintf(
									"%3.2f",
									(
										fbs2pgk( $dd->{fbs} ) * $dd->{$ee} /
										  $fbs_SUM
									)
								)
							);
						}
						else {
							chomp( $spr =
								  sprintf( "%3.2f", ( fbs2pgk( $dd->{$ee} ) ) )
							);
						}
					}
				}
			}
			if ( defined($spr) ) {
				$spr = '1.00' if $spr > 1;
				$spr = '0.00' if $spr < 0;
			}
			if (    $node->{$node1}->{'showname'}
				and $node->{$node2}->{'showname'}
				and $spr )
			{
				push @edge,
				  '<edge n1="'
				  . $node->{$node1}->{'showname'}
				  . '" n2="'
				  . $node->{$node2}->{'showname'}
				  . '" iType="'
				  . ( ( lc($ee) eq 'fbs' ) ? 0 : $place{ $ID{$ee} } )
				  . '" conf="'
				  . $spr
				  . '" ortn="'
				  . $bzc{ $ID{$ee} } . '"/>';
			}
			$nodes{$node1} = 1;
			$nodes{$node2} = 1;
		}
	}
	return xmlWrap( 'edges', join( "\n", @edge ) );
}

sub prnNODES { #a part of jSquid XML syntax
	my ( $nn, $NODE, $spec, $anno, $current_species, $i, $l, $x, $y, @link_arr,
		@group );

	$NODE = "\n" . '<nodes>' . "\n";
	for $nn ( keys(%nodes) ) {
		undef $current_species;
		$current_species = $node->{$nn}->{'species'};
		print "!!Orphan: no species found for $nn\!\n" if !$current_species;
		chomp( $x = sprintf( "%3.2f\n", rand() ) );
		chomp( $y = sprintf( "%3.2f\n", rand() ) );
		undef $anno;
		undef @group;
		undef @link_arr;

		if ( $show_annotations and $node->{$nn}->{'description'} ) {
			$anno = $node->{$nn}->{'description'};
		}

		for $l ( keys( %{$pathwaySize} ) ) {
			push @group,
			  '<group ref="'
			  . $pathwayMembership->{$nn}->{'pathway'}->{$l}->{'description'}
			  . '" name="'
			  . $pathwayMembership->{$nn}->{'pathway'}->{$l}->{'description'}
			  . '"/>'
			  if ( $active_groups{ $pathwayName->{$l} }
				and defined( $pathwayMembership->{$nn}->{'pathway'}->{$l} ) );
		}
		push @group,
		  '<group ref="Sub-Cell Location" name="'
		  . $GOlocation{ $pathwayMembership->{$nn}->{'go_code'} } . '"/>'
		  if defined( $pathwayMembership->{$nn}->{'go_code'} );

		for $l (@linkstubslist) {
			push @link_arr, '<ID name="'
			  . (
				( $weblink->{$l}->{'ID_to_ask'} eq 'fcname' )
				? $nn
				: $node->{$nn}->{ $weblink->{$l}->{'ID_to_ask'} }
			  )
			  . '" ref="'
			  . $l . '"/>';
		}

#;
#$timing .= '<br>_'.$lmx::ma_profile->{$main::profile_table{'lmx'}}->{$nn}->{$criteria{contrast}}.'_<br>';
#print '<br>'.$criteria{contrast}."\n" if $criteria{contrast};

		$node->{$nn}->{'hubbiness'} = 1
		  if !defined( $node->{$nn}->{'hubbiness'} );
		$NODE .= "\n"
		  . '<node name="'
		  . $node->{$nn}->{'showname'} . '" x="'
		  . $x . '" y="'
		  . $y
		  . '" color="'
		  . nodeColor( $nn, $current_species )
		  . '" shape="'
		  . $shape{ $node->{$nn}->{'node_type'} }
		  . '" size="'
		  . int( log( $node->{$nn}->{'hubbiness'} ) + 1 ) . '">' . "\n";
		$NODE .= xmlWrap( 'att', $anno ) if $java;
		$NODE .= xmlWrap( 'groups', join( "\n", @group ) )
		  if $java
		  and defined( $group[0] );
		$NODE .= xmlWrap( 'hlIDs', join( "\n", @link_arr ) ) if $java;
		$NODE .= '</node>';
	}
	$NODE .= '</nodes>' . "\n";
	return $NODE;
}

sub nodeColor { #custom node coloring, according to expression data etc.
	my ( $nn, $species ) = @_;
	my ( $value, %ref, %n, @cn );

	if ( 1 == 1 and $lmx and $repaint_nodes ) {
		if (
			defined( $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn} )
		  )
		{
			if ( $criteria{contrast} eq 'lmx1a_vs_phox2b' ) {
				$ref{'yes'} =
				  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
				  ->{'lmx1a'}->{'mean'};
				$ref{'no'} =
				  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
				  ->{'phox2b'}->{'mean'};
			}
			elsif ( $criteria{contrast} eq 'phox2b_vs_rest' ) {
				$ref{'yes'} =
				  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
				  ->{'phox2b'}->{'mean'};
				$ref{'no'} =
				  ( $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
					  ->{'lmx1a'}->{'mean'} +
					  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
					  ->{'wt'}->{'mean'} ) / 2;
			}
			elsif ( $criteria{contrast} eq 'lmx1a_vs_rest' ) {
				$ref{'yes'} =
				  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
				  ->{'lmx1a'}->{'mean'};
				$ref{'no'} = $ref{'no'} =
				  ( $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
					  ->{'phox2b'}->{'mean'} +
					  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
					  ->{'wt'}->{'mean'} ) / 2;
			}
			elsif ( $criteria{contrast} eq 'lmx1a_vs_wt' ) {
				$ref{'yes'} =
				  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
				  ->{'lmx1a'}->{'mean'};
				$ref{'no'} =
				  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
				  ->{'wt'}->{'mean'};
			}
			$value =
			  $lmx::ma_profile->{ $main::profile_table{'lmx'} }->{$nn}
			  ->{'totals'}->{ $criteria{contrast} };

#print join('<br>', ($nn, $node->{$nn}->{'showname'}, $criteria{contrast}, 'F: '.$value, 'MSe: '.$lmx::ma_profile->{$main::profile_table{'lmx'}}->{$nn}->{'mserror'}, $ref{'yes'}, $ref{'no'})).'<br>'.'<br>'; #  if defined($lmx::ma_profile->{$main::profile_table{'lmx'}}->{$nn});
		}
###############################################
###############################################
		elsif (
			1 == 1
			and defined(
				$lmx::ma_profile->{ $main::profile_table{'zfish'} }->{$nn}
			)
		  )
		{
			@cn = split( '_vs_', $criteria{contrast} );
			undef %ref;
			undef %n;
			if ( $criteria{contrast} =~ m/\_vs\_/i ) {
				while ( $cn[0] =~ m/([0-9])/g ) {
					$ref{'yes'} +=
					  $lmx::ma_profile->{ $main::profile_table{'zfish'} }->{$nn}
					  ->{ 'd' . $1 }->{'mean'};
					$n{'yes'}++;
				}
				while ( $cn[1] =~ m/([0-9])/g ) {
					$ref{'no'} +=
					  $lmx::ma_profile->{ $main::profile_table{'zfish'} }->{$nn}
					  ->{ 'd' . $1 }->{'mean'};
					$n{'no'}++;
				}
				$ref{'yes'} /= $n{'yes'} if $n{'yes'};
				$ref{'no'}  /= $n{'no'}  if $n{'no'};
			}
			elsif ( lc( $criteria{contrast} ) eq 'mstreat' ) {
				$ref{'yes'} +=
				  $lmx::ma_profile->{ $main::profile_table{'zfish'} }->{$nn}
				  ->{'tcdd'}->{'mean'};
				$ref{'no'} +=
				  $lmx::ma_profile->{ $main::profile_table{'zfish'} }->{$nn}
				  ->{'dmso'}->{'mean'};
			}
			$value =
			  $lmx::ma_profile->{ $main::profile_table{'zfish'} }->{$nn}
			  ->{'totals'}->{ $criteria{contrast} };

#print $ref{'yes'}.'+&nbsp;'.$ref{'no'}.'+&nbsp;'.$criteria{contrast}.$nn.'&nbsp;'.$value.'<br>';
		}
		else { return ( $node_color{'other'} ); }
	}
	else {
		return (
			( ( lc($ortho_render) eq 'yes' ) and $keep_query )
			? $color{ $ID{$species} }
			: $node_color{ $node->{$nn}->{'node_type'} }
		);
	}
	return 'Unexpected contrast'
	  if ( $criteria{contrast} =~ m/\_vs\_/i )
	  and ( !$ref{'yes'} or !$ref{'no'} );
	$value = -$value if ( $ref{'yes'} < $ref{'no'} );
	return ( colorinfo255( $value, \%maxLmxContrast ) );
	return 'NodeColorError';
}

sub prnSTUBS {  #a part of jSquid XML syntax
	my ( @linkstub, $i, $st );
	my $org = $submitted_species;
	for $i ( 0 .. $#linkstubslist ) {
		$linkstub[$i] = '<stub name="' . $linkstubslist[$i];
		if ( defined( $weblink->{ $linkstubslist[$i] }->{$org}->{start} ) ) {
			$st = $weblink->{ $linkstubslist[$i] }->{$org}->{start};
		}
		else { $st = $weblink->{ $linkstubslist[$i] }->{'all_species'} }

		$linkstub[$i] .= '" urlbegin="' . $st . '"/>';
	}
	return undef if !defined( $linkstub[0] );
	return xmlWrap( 'hyperlinkStubs', join( "\n", @linkstub ) );
}

sub prnSETTINGS {  #a part of jSquid XML syntax
	my ( $sett, $i );

	return undef if !defined(%initSettings);
	$sett = '<settings';
	for $i ( keys(%initSettings) ) {
		$sett .= " $i=\"$initSettings{$i}\"";
	}
	$sett .= '/>';

	return $sett;
}

sub printCONDITIONS { #prints conditions of the query (for the user's easier orientation how the page was obtained)
	my ( $ff, @spec, $cnd, $sign, $diff, $not_found );
	for $ss ( @{$render_list} ) { push @spec, $org{ $species{$ss} }; }

	for $ff ( keys( %{ $submitted_genes->{$submitted_species} } ) ) {
		if (
			defined(
				$submitted_genes->{$submitted_species}->{$ff}->{'fcnames'}
			)
		  )
		{
			for $ss (
				@{ $submitted_genes->{$submitted_species}->{$ff}->{'fcnames'} }
			  )
			{
				if ( lc($ff) ne lc( $node->{$ss}->{showname} ) ) {
					$diff .= '<tr><td>' . $ff . ':</td><td class="not_found">'
					  . (
						  $node->{$ss}->{showname}
						? $node->{$ss}->{showname}
						: $ss
					  )
					  . '</td></tr>' . "\n";
				}

#$timing .= '<br>'.$ss.'&nbsp;'.$found_genes->{$submitted_species}->{$ss}.'_<br>';
				if (
					!$found_genes->{$submitted_species}->{$ss}
					and ( $submitted_genes->{$submitted_species}->{ uc($ss) }
						->{'status'} ne 'ID not found' )
				  )
				{
					$diff .=
					    '<tr><td>' . $ff
					  . ':</td><td class="not_found">No links found</td></tr>';
					$not_found++;
				}
			}
		}
		else {
			$diff .=
			    '<tr><td>' . $ff
			  . ':</td><td class="not_found">'
			  . $submitted_genes->{$submitted_species}->{$ff}->{'status'}
			  . '</td></tr>' . "\n";
		}
	}
	if ( $diff or $not_found ) {
		$cnd .= '<table >' . "\n";
		$cnd .= $diff;
		$cnd .= '</table></span>' . "\n";
		$sign = $graf_path . 'plus.png" alt="Expand';
		print '<span class="explanation">' . "\n"
		  . '<a class="big_img"><img id="id_map_sign" onClick="return hideOrShow(\'id_map_sign\', \'id_map\')" src="'
		  . $sign
		  . '"/></a> Some of the submitted identifiers are either not found or shown under different names';
		print "\n" . '<div id="id_map" style="display: none;">' . "\n";
#########################################3
		print $cnd;
		print "\n" . '</div></span>' . "\n";
	}
	$cnd = '<ul>';
	$cnd .= '<li>Organism';
	$cnd .= 's' if ( lc($ortho_render) eq 'yes' );
	$cnd .= ': ' . join( ', ', @spec ) . '</li>';
	$cnd .=
	  '<li>Found links checked for coupling with '
	  . $q->param('context_genes') . '</li>'
	  if $context_genes[0];
	$cnd .= '<li>Confidence cutoff: <b>' . $q->param('coff') . '</b></li>';
	$cnd .= '<li>Network distance: <b>' . $q->param('order') . '</b> step';
	$cnd .= 's' if $q->param('order') > 1;
	$cnd .= '</li>';

	if ( $base ne 'all' ) {
		$cnd .=
		    '<li>Only evidence from '
		  . join( ', ', @spoe )
		  . ' was considered</li>'
		  if defined( $q->param('species_of_evidence') );
		$cnd .=
		    '<li>Only evidence of types '
		  . join( ', ', @tyoe )
		  . ' was considered</li>'
		  if defined( $q->param('types_of_evidence') );
	}
	if ($reduce) {
		$cnd .= '<li>Reduction: by ' . $algo_descr{$reduction};
		if ( $q->param('no_of_links') < 10000 ) {
			$cnd .=
			    ', selecting <b>'
			  . $desired_links_total
			  . '</b> most confident links at each step';
			$cnd .=
' and retaining, when available, at least <b>5</b> links per single query gene</li>'
			  if $q->param('qvotering');
		}
		$cnd .= '</li>';

	}
	$cnd .= '</ul>';
	$sign = $graf_path . 'plus.png" alt="Expand';
	print '<br><span class="explanation">' . "\n"
	  . '<br><a class="img"><img id="condition_sign" onClick="return hideOrShow(\'condition_sign\', \'condition\')" src="'
	  . $sign
	  . '"/></a>  Conditions of the query';

	print "\n" . '<div id="condition" style="display: none;">' . "\n";
	print $cnd;
	print "\n" . '</div></span>' . "\n";
}

sub printEXPLANATION { #prints conditions of the network reduction (for the user's easier orientation of why not all links are displayed)
	my ( $genename, $sp, $or, $it );

	$genename =
	  ( $#genes > 10 )
	  ? (
		    scalar(@genes) . ' '
		  . $org{$submitted_species}
		  . ' genes '
		  . join( ', ', @genes ) )
	  : ( $org{$submitted_species} . ' ' . join( ', ', @genes ) );
	$genename .= " plus $added_top_genes most differentially expressed genes "
	  if $added_top_genes;
	print '<br><font size="3" face="Verdana"><b>'
	  . 'Your query for '
	  . $genename
	  . ' resulted in a network of '
	  . scalar( keys( %{$data} ) )
	  . ' most probable links between '
	  . ( scalar( keys( %{ $found_genes->{$submitted_species} } ) ) )
	  . ' genes at confidence cutoff '
	  . fbs2pgk($coff)
	  . ' (FBS = '
	  . $coff
	  . ')</b></font><BR>' . "\n";
	if ( scalar( keys( %{$data} ) ) < $found_number ) {
		print
'<p class="explanation"><b>Note that more links were found at this confidence. They were removed by '
		  . $algo_descr{$reduction}
		  . '. </b><br>The selection at each expansion step:<br>' . "\n";
		for $sp ( keys( %{$cnts} ) ) {
			for $or ( sort { $a <=> $b } keys( %{ $cnts->{$sp} } ) ) {
				print 'Step ' . $or . ': '
				  . ( $cnts->{$sp}->{$or}->{after} )
				  . '&nbsp;most confident '
				  . $org{$sp}
				  . ' links were selected from '
				  . ( $cnts->{$sp}->{$or}->{before} )
				  . '&nbsp;<BR>' . "\n"
				  if $cnts->{$sp}->{$or}->{before} > $cnts->{$sp}->{$or}
				  ->{after};    #.' at cutoff '.($cnts->{$sp}->{$or}->{co})
			}
		}
	}
	print $algo_descr{'order'} . '<BR>' . "\n" if lc($reduction) eq 'order';
}

sub printJavaTIPS {
	my $versionlink = 'http://www.java.com/download';
	my $javalink    =
	  '<a href="' . $versionlink . '" target="_blank"> install JAVA</a>';
	print
'<p><font size="4" face="Verdana"><b>Welcome to the FunCoup world of protein networks!</font></p><font size="1" face="Verdana">Your browser is not running JAVA of the required version, and we thus can only show a static picture of the requested sub-network.<br> </p><p>However, if you '
	  . $javalink
	  . ' (you need JAVA Runtime Environment v.5 or later), the interactive mode with plenty of options would become available.<br>You can also study the supplementary tables open below.</b></font><p>'
	  . "\n";
}

sub prnLEGEND { #prints the node shape/color legend that is found in the jSquid applet menu under View->Node legend
	my ( $pw, $leg );

	my @list = ( 'query', 'other' );
	push @list, ('context') if $show_context;
	push @list, ( 'mirna', 'tf' ) if $use_nonconventional;
	push @list, 'lmx' if $lmx;
	for $pw (@list) {
		$leg .=
		    '<legendItem shape="'
		  . $shape{$pw}
		  . '" color="'
		  . $node_color{$pw}
		  . '" name="'
		  . $pw . '"/>' . "\n";
	}
	@list = ( sort { $a cmp $b } keys( %{$pathwaySize} ) );

	for $pw (@list) {
		$leg .=
		    '<legendItem shape="'
		  . $shape{ 'KEGG' . $pw }
		  . '" color="'
		  . $node_color{ 'KEGG' . $pw }
		  . '" name="'
		  . $pathwayName->{$pw} . '"/>' . "\n";
	}
	return "\n" . '<legend>' . "\n" . $leg . '</legend>' . "\n" if $leg;
	return undef;
}

sub printToXMLjsquid { #ultimately compiles the whol jSquid input XML code
	my ( $wheight, $wwidth, $ll ) = @_;
	my ( $sign, $dd, $nn, $p );
	my $old = 0;

	srand();

	for $dd ( keys( %{$data} ) ) {
		for $ee ( @{$ll} ) {
			$present{$ee} = 1 if $data->{$dd}->{$ee};
		}
	}

	print '<hr noshade size=2>';
	$sign = $graf_path . 'big_minus.png" alt="Expand';
	print "\n"
	  . '<a class="big_img"><img id="graph_sign" onClick="return hideOrShow(\'graph_sign\', \'graph\')" src="'
	  . $sign
	  . '"/></a><font size="4" face="Verdana">&nbsp;Graph</font>' . "\n";
	print '<div id="graph" style="display: block; ">';
	$XMLcode =
	    '<?xml version="1.0" encoding="UTF-8"?>' . "\n"
	  . '<jsquid x="500" y="400">' . "\n";
	$XMLcode .= prnSETTINGS()   if $java;
	$XMLcode .= prnLEGEND()     if $java;
	$XMLcode .= prnSTUBS()      if $java;
	$XMLcode .= prnNODEGROUPS() if $java;
	$XMLcode .= prnINTERACTION();
	$XMLcode .= prnEDGES($ll);
	$XMLcode .= prnNODES();
	$XMLcode .= '</jsquid>';

	if ($java) {
		print '<applet code="jsquid.JSquidApplet.class" archive="'
		  . $medusaLocation
		  . 'Medusa.jar, '
		  . $medusaLocation
		  . 'jSquid.jar" height="'
		  . $wheight
		  . '" width="'
		  . $wwidth . '">' . "\n"
		  if !$debug;

		if ($old) {
			print '<param name="XML" value=' . "\'\n";
			print $XMLcode. "\n\'\>";
			print '</applet>' . "\n";
		}
		else {
			$tmpfile = 'tmp.' . $$ . '.jsquid.xml';
			open TMPFILE, '> ' . $tmp_loc_path . $tmpfile;
			print '<param name="XMLFile" value=\'' . $tmp_web_path . $tmpfile;
			print TMPFILE $XMLcode;
			print '\'></applet>' . "\n";
			close TMPFILE;
		}
	}
	else {
		print '<table width="' . $wwidth . '"><tr><td>';
		printJavaTIPS();
		print '</td></tr></table>';
		$tmpfile = 'tmp.' . $$ . '.jsquid.xml';
		open TMPFILE, '> ' . $tmp_loc_path . $tmpfile;
		print TMPFILE $XMLcode;
		close TMPFILE;
		my $xmlcode = $XMLcode;
		print '<div>';
		print '<img src="'
		  . $picMakerLocation
		  . 'picmaker.cgi?file='.$tmpfile.'" alt="Tree"/>';
#		print '<form action="'
#		  . $picMakerLocation
#		  . ' picmaker . cgi " id=" static " method=" post " target=" _blank ">';
#		print
#'<textarea name=" xmlcode " id=" xmlbox " rows=" 0 " cols=" 0 " readonly=" YES
#		  ">'
#		  . $XMLcode
#		  . '</textarea>';
#		print '</form>';
		print '</div>';
#		print
#'<script type=" text / javascript ">document.getElementById(" static
#		  ").submit()</script>';
	}
	print " \n " . '</div>';
	print '<hr noshade size=2>';
	return;
}

sub printStructuredTable { #The link-by-link table down the network window
	my ($ll) = @_;

	my (
		%nodes,         $ee,              $dd,        $node1,
		$node2,         $bzc,             $x,         $y,
		$spr,           $s1,              $s2,        $nn,
		@link_list,     $current_species, $spec,      $sp,
		$or,            $it,              $max,       $fc_cl,
		$fbs_sum,       $ss,              $trow,      $value,
		$color,         @links,           $ww,        $l,
		$rowcolor,      $rn,              $show,      $infocolor,
		$caption,       $show_ortho,      $isAlready, $colDefinition,
		$fsize,         $display,         $sign,      $offerURL,
		$twidth,        $descr,           $sptr,      $Northolinks,
		$linknumber,    $colspan,         $ii,        $fbs_species_sum,
		$fbs_types_sum, @a,               $p,         @dpairs,
		$gene_content
	);
	$show_ortho = 0;
	$rowcolor   = '#DDA';
	$twidth     = '" 800 "';

	for $ss ( keys( %{$found_genes} ) ) {

		#print ('<br>', ($ss, sort {$a cmp $b} keys(%{$found_genes->{$ss}})));
		$current_species = $ss;
		print " Orphan: no species found $ss \: \!\n " if !$current_species;
		$sign = $graf_path . 'big_plus.png" alt = "Expand';

		print " \n "
		  . '<a class="big_img"><img id="pairs_sign'
		  . $ss
		  . '" onClick=" return hideOrShow(
			    \'pairs_sign' . $ss
			  . '\', \'pairs'
			  . $ss
			  . '\')" src="'
			  . $sign
			  . '"/></a><font size="4" face="Verdana">&nbsp;Network edges&nbsp;'
			  . (
				( lc($ortho_render) ne 'yes' )
				? ''
				: 'of <i>' . $org{$ss} . '</i>'
			  )
			  . '</font>' . "\n";
			  $display = ( $java and $jsquid_screen ) ? 'none' : 'block';
			  print '<div id="pairs' . $ss
			  . '" style="display: '
			  . $display . '; ">' . "\n";

			  print '<table class="structured_table">' . "\n";

#print "\n".$q->start_table({-class=>"tga", -border=>0, -cellpadding=>"1", -rules=>"none", -cellspacing=>"1", -width=>$twidth});
			  $colDefinition =
			  '<colgroup span="'
			  . ( scalar( keys(%evidenceOrder) ) - 1 ) . '">' . "\n";
			  $colDefinition .= '<col width="160">';
			  $colDefinition .= '<col width="85">';
			  for ( 4 .. ( scalar( keys(%evidenceOrder) ) - 1 ) ) {
				$colDefinition .= '<col width="30">';
			}
			$colDefinition   .= '<col width="75">';
			  $colDefinition .= '</colgroup>';
			  print $colDefinition. "\n";
			  $trow = '<tr class="structured_table str_table_header">' . "\n";
			  $trow .= '<td colspan="2">&nbsp;</td>' . "\n";
			  $trow .= '<td colspan="8">Data types</td>' . "\n";
			  $trow .= '<td colspan="7">Species</td>' . "\n";
			  $trow .= '<td>Data</td>';
			  $trow .= '</tr>' . "\n";
###    print $trow;
#print "\n".$q->start_table({-class=>"tga", -border=>0, -cellpadding=>"1", -rules=>"none", -cellspacing=>"1", -width=>$twidth});
#print $q->end_table();
			  $trow =
'<tr style="padding: 0; font-family: Courier New; font-weight: bold; font-size: 14px; color: #FFF;">'
			  . "\n";

			  for $ee (@evOrder) {
				if ($ee) {
					next if ( $ee =~ /prot1/i );
					$color = $hexcolor{ $ID{$ee} };
					if ( lc($color) eq lc( $hexcolor{ $ID{white} } ) ) {
						$color = $hexcolor{ $ID{black} };
					}
					$color =~ s/\"//g;
					$trow .=
					  '<td style="background-color: ' . $color . '">'
					  . $oltag{$ee} . '</td>';

				}
			}
			print $trow. '</tr>' . "\n" . '</table>';
##########################
			  $colspan = scalar( keys(%evidenceOrder) );
			  @dpairs  =
			  sort { $data->{$b}->{fbs} <=> $data->{$a}->{fbs} }
			  keys( %{$data} );
			  for $node1 (
				sort {
					( defined( $fcgenes->{$b} ) and $fcgenes->{$b} eq 'query' )
					  cmp( defined( $fcgenes->{$a} )
						  and $fcgenes->{$a} eq 'query' )
				}
				sort { $node->{$a}->{'showname'} cmp $node->{$b}->{'showname'} }
				keys( %{ $found_genes->{$ss} } )
			  )
			{
				next
				  if scalar( keys( %{ $found_pairs->{$ss}->{$node1} } ) ) < 1;
				undef $isAlready;
				$display = (
					(
						defined( $fcgenes->{$node1} )
						  and $fcgenes->{$node1} =~ m/query/i
					)
				) ? 'block' : 'none';
				$sign = $graf_path
				  . (
					(
						defined( $fcgenes->{$node1} )
						  and ( $fcgenes->{$node1} ne 'query' )
					) ? 'plus.png" alt="Expand' : 'minus.png" alt="Collapse'
				  );

				$linknumber = $Northolinks = 0;
				$linknumber =
				  (
					(
						scalar( keys( %{ $found_pairs->{$ss}->{$node1} } ) ) -
						  $Northolinks
					) > 0
				  )
				  ? (
					' ('
					  . (
						scalar( keys( %{ $found_pairs->{$ss}->{$node1} } ) ) -
						  $Northolinks
					  )
					  . ' out of '
					  . $node->{$node1}->{'hubbiness'}
					  . ' at <i>pfc</i>='
					  . $coff_class . ')'
				  )
				  : '';
				$node->{$node1}->{olLinkedTag} = olLinkedTag(
					$node->{$node1}->{'description'},
					'<span style=""> Interactors of '
					  . ( $node->{$node1}->{'showname'} . $linknumber )
					  . ':</span>',
					'b', '',
					$hexcolor{ $ID{white} },
					$hexcolor{ $ID{$current_species} },
					(
						extraLinks(
							$current_species, $node1,
							$node->{$node1}->{'showname'}
						),
						(
							defined( $pathwayMembership->{$node1} )
							? pathwayLinks( $current_species, $node1 )
							: undef
						)
					)
				);
				print '<a class="img"><img id="'
				  . $node->{$node1}->{'showname'}
				  . '" onClick="return hideOrShow(\''
				  . $node->{$node1}->{'showname'}
				  . '\', \''
				  . ( $node->{$node1}->{'showname'} . 'targets' )
				  . '\')" src="'
				  . $sign
				  . '"/></a>'
				  . $node->{$node1}->{olLinkedTag};
				print '<img src="'
				  . $graf_path
				  . 'shape_dmnd_yellow_small.GIF" alt="Your query" />'
				  if defined( $fcgenes->{$node1} )
				  and ( $fcgenes->{$node1} eq 'query' );
				print '<img src="'
				  . $graf_path
				  . 'shape_dmnd_purple_small.GIF" alt="Your context" />'
				  if defined( $fcgenes->{$node1} )
				  and ( $fcgenes->{$node1} eq 'context' );
				print "\n" . '<br>' . "\n"
				  . '<div id="'
				  . $node->{$node1}->{'showname'}
				  . 'targets" style="display: '
				  . $display . '; ">';
				print '<table class="structured_table">' . "\n";

#print $q->start_table({-class=>"structured_table", -border=>0, -cellpadding=>"1", -rules=>"none", -cellspacing=>"1"});
				print $colDefinition. "\n";
				for $p (@dpairs) {
					undef $fbs_sum;
					$dd = $data->{$p};
					next
					  if (  ( $dd->{'prot1'} ne $node1 )
						and ( $dd->{'prot2'} ne $node1 ) );

					#next if $isAlready->{$dd->{'prot1'}}->{$dd->{'prot2'}};
					$node2 =
					  ( $dd->{prot1} eq $node1 )
					  ? $dd->{'prot2'}
					  : $dd->{'prot1'};
					if ( $dd->{ortho} ) {
						$gene_content = $node->{$node2}->{'showname'};
					}
					else {
						$gene_content = olLinkedTag(
							$node->{$node2}->{'description'},
							$node->{$node2}->{'showname'},
							'b', '',
							$hexcolor{ $ID{white} },
							$hexcolor{ $ID{$current_species} },
							(
								extraLinks(
									$current_species,              $node2,
									$node->{$node2}->{'showname'}, $node1,
									$node->{$node1}->{'showname'}
								),
								(
									defined( $pathwayMembership->{$node2} )
									? pathwayLinks( $current_species, $node2 )
									: undef
								)
							)
						);

						#$gene_content = $node->{$node2}->{'showname'};

					}
					$trow = '<tr>';
					$trow .= '<td';

#$trow .= ' style="font-size: 8px;"' if length($node->{$node2}->{'showname'}) > 13;
					$trow .= '>' . $gene_content;
					if ($lmx) {
						$trow .= '&nbsp;'
						  . popChart( $profile_table{'lmx'}, $node1, $node2 )
						  if $current_species eq 'mmu';
						$trow .= '&nbsp;'
						  . popChart( $profile_table{'zfish'}, $node1, $node2 )
						  if $current_species eq 'dre';
					}
					$trow .= '</td>';

					if ( $dd->{ortho} ) {
						$trow .=
						    '<td align="center" colspan="' . $colspan
						  . '">ortholog</td>';
					}
					elsif ( !$dd->{fbs} ) {
						$trow .=
						    '<td align="center" colspan="' . $colspan
						  . '">confidence not estimated</td>';
					}
					else {
						if ( 1 == 1 ) {
							$fbs_sum->{spec} = $fbs_sum->{type} = $dd->{fbs};
						}
						else {
							for $ii ( 0 .. $#species_of_evidence ) {
								$fbs_sum->{spec} +=
								  $dd->{ $species_of_evidence[$ii] }
								  if
								  defined( $dd->{ $species_of_evidence[$ii] } );
							}
							for $ii ( 0 .. $#types_of_evidence ) {
								$fbs_sum->{type} +=
								  $dd->{ $types_of_evidence[$ii] }
								  if
								  defined( $dd->{ $species_of_evidence[$ii] } );
							}
						}
						$trow .= '<td style="font-weight: 800;">';
						$trow .= visualTag( fbs2pgk( $dd->{fbs} ),
							'confidence', 'final', $current_species, $node1,
							$node2, $dd->{fbs} )
						  . '</td>';
						for $ee (@evOrder) {
							if ( $ee =~ m/blast/i ) {

#$trow .= $q->td($q->font({face=>"Verdana", size=>"2"}, ($value ? sprintf("%.0f", $value) : '&nbsp;')));
								$trow .= '<td class="databox_cell">'
								  . datasetBox(
									$dd,
									$node->{$node1}->{'showname'},
									$node->{$node2}->{'showname'}
								  )
								  . '</td>' . "\n";
							}
							else {
								next if ( $ee =~ /fbs|prot/i );
								$value = $dd->{$ee};
								$color = $hexcolor{ $ID{$ee} };
								$color =~ s/\"//g;
								$color = '#000000' if !$color;
								$infocolor = '#FFFFFF';
								$trow .=
								  '<td bgcolor="'
								  . colorinfo( $value, \%maxPartialFBS ) . '">';
								$trow .= visualTag(
									$dd->{$ee},
									$ee,
									'partial',
									$current_species,
									$node1, $node2,
									(
										  $org{$ee}
										? $fbs_sum->{spec}
										: $fbs_sum->{type}
									),
									$dd->{ $current_species . '_phylosign' }
								);
								$trow .= '</td>' . "\n";
							}
						}
					}
					$rn++;
					print $trow. '</tr>' . "\n";
				}
				print '</table></div>' . "\n";
			}
			print '</div><hr noshade size=2>';
		}
		return undef;
	}

	sub printSingleTable {
		my ($ll) = @_;
		my (
			$current_species, $trow,  $td,
			$links,           $color, $g1,
			$display,         $sign,  $ss
		);

		$sign = $graf_path . 'big_plus.png" alt="Expand';
		for $ss ( keys( %{$found_genes} ) ) {
			$current_species = $ss;
			print "\n"
			  . '<a class="big_img"><img id="annot_sign'
			  . $ss
			  . '" onClick="return hideOrShow(\'annot_sign'
			  . $ss
			  . '\', \'annot'
			  . $ss
			  . '\')" src="'
			  . $sign
			  . '"/></a><font size="4" face="Verdana">&nbsp;Network nodes&nbsp;'
			  . (
				( lc($ortho_render) ne 'yes' )
				? ''
				: 'of <i>' . $org{$ss} . '</i>'
			  )
			  . '</font>' . "\n";

			$display = 'none';
			print '<div id="annot' . $ss
			  . '" style="display: '
			  . $display . '; ">';
			print '<table class="structured_table">' . "\n";
			print
'<colgroup span="5"><col width="110"><col width="160"><col width="350"><col width="120"><col width="60"></colgroup>'
			  . "\n";
			print
			  '<tr class="structured_table str_table_header"><td>Gene</td><td>'
			  . ( ( $current_species eq 'dre' ) ? 'Zfin ID' : 'ENSEMBL ID' )
			  . '</td><td>ENSEMBL annotation</td><td>Reference<br>accession</td><td></td></tr>'
			  . "\n";

#for $g1(sort {($fcgenes->{$b} eq 'query') cmp ($fcgenes->{$a} eq 'query')} sort {$node->{$a}->{'showname'} cmp $node->{$b}->{'showname'}} keys(%{$found_genes->{$ss}})) {
			for $g1 (
				sort {
					( defined( $fcgenes->{$b} )
						  and ( $fcgenes->{$b} eq 'query' ) )
					  cmp( defined( $fcgenes->{$a} )
						  and ( $fcgenes->{$a} eq 'query' ) )
				} sort { $node->{$a}->{'showname'} cmp $node->{$b}->{'showname'} }
				keys( %{ $found_genes->{$ss} } )
			  )
			{
				next if scalar( keys( %{ $found_pairs->{$ss}->{$g1} } ) ) < 1;
				$trow = '<tr>';

				$td = webLink( $node->{$g1}->{'showname'},
					$current_species, 'ENSEMBL' );
				$td = '<a href="' . $td . '" target="_blank" class="tlink" '
				  . (
					( length( $node->{$g1}->{'showname'} ) > 12 )
					? 'style="font-size: 9px"'
					: ''
				  )
				  . '>'
				  . $node->{$g1}->{'showname'} . '</a>'
				  if $td;
				$trow .= '<td>' . $td . '</td>';

				$td = webLink( $g1, $current_species, 'ENSEMBL' );
				$td =
				    '<a href="' . $td
				  . '" target="_blank" class="tlink"'
				  . ( ( length($g1) > 12 ) ? 'style="font-size: 9px"' : '' )
				  . '>'
				  . $g1 . '</a>'
				  if $td;
				$trow .= '<td>' . $td . '</td>';

				$trow .=
				  '<td align="LEFT">'
				  . $node->{$g1}->{'full_description'} . '</td>';

				$td = webLink(
					$node->{$g1}->{'sptr'},
					$current_species,
					(
						( $node->{$g1}->{'sptr'} =~ /^MGI\:/i )
						? 'MGI'
						: 'UniProt'
					)
				);
				$td = '<a href="' . $td . '" target="_blank" class="tlink" '
				  . (
					( length( $node->{$g1}->{'sptr'} ) > 12 )
					? 'style="font-size: 9px"'
					: ''
				  )
				  . '>'
				  . $node->{$g1}->{'sptr'} . '</a>'
				  if $td
				  and defined( $node->{$g1}->{'sptr'} );
				$trow .= '<td>' . $td . '</td>';

				$links = $node->{$g1}->{olLinkedTag};
				$links =~ s/Interactors.+[0-9\s]\)\:\</links\</;
				$links =~ s/tlink\"/databox_cell\"/;
				$trow .= '<td>' . $links . '</td>';
				print $trow. '</tr>';
			}
			print '</table></div><hr noshade size=2>' . "\n";
		}

		print "\n";
	}

	sub popChart { #an experimental procedure to plot expression in text mode pop-ups
		my (
			$tag,    $height, $hspace, $vspace,  $width,  $hh,    $ww,
			$nn,     $c,      $cc,     $co1,     $co2,    $id,    $x,
			$y,      $N,      $i,      $corrs,   %offset, $coord, @nodes,
			$filled, %marker, %color,  $hlegend, $size,   $label
		);

		my $table = shift @_;

		@nodes  = @_;
		$hspace = 8;
		$vspace = 10;

		$tag       = '<a onmouseover="return overlib(\'<b><font size=4>';
		$N         = 0;
		$marker{0} = '<font color=red>o</font>';
		$marker{1} = '<font color=blue>o</font>';
		$marker{2} = '<font color=red>x</font>';
		$marker{3} = '<font color=blue>x</font>';
		$color{0}  = 'red';
		$color{1}  = 'blue';
		$color{2}  = 'red';
		$color{3}  = 'blue';
		$label     = 'MA';
		if ( $table eq 'zfish_twoway' ) {

			for $nn (@nodes) {
				for $co2 ( 'TCDD', 'DMSO' ) {
					$offset{ $nn . '<=>' . lc($co2) } = $N++;
				}
			}
		}
		for $nn (@nodes) {
			return undef if !defined( $lmx::ma_profile->{$table}->{$nn} );
			if ( $table eq 'lmx1_oneway_pma' ) {
				$offset{$nn} = $N++;

				for $c ( 0 .. $#{ $lmx::ma_conditions_unique->{$table} } ) {
					for $cc (
						@{
							$lmx::ma_profile->{$table}->{$nn}->{'raw'}
							  ->{ $lmx::ma_conditions_unique->{$table}->[$c] }
						}
					  )
					{
						$y = sprintf(
							"%d",
							(
								$vspace * (
									(
										$cc - $lmx::ma_profile->{$table}->{$nn}
										  ->{'totals'}->{'min'}
									) / $lmx::ma_profile->{$table}->{$nn}
									  ->{'totals'}->{'range'}
								)
							)
						);
						$x = $hspace * $c + $offset{$nn};
						$coord->{x}->[$x]->{$nn}++;
						$coord->{y}->[$y]->{$nn}++;
						$coord->{xy}->{$x}->{$y}->{$nn}++;
					}
				}
			}
			elsif ( $table eq 'zfish_twoway' ) {

				for $c ( @{ $lmx::ma_conditions->{$table} } ) {
					undef $co1;
					undef $co2;
					( $co1, $co2 ) = ( $1, $2 )
					  if $c =~ m/^[0-9a-z]+\_([0-9a-z]+)\_([0-9a-z]+)$/i;
					$co1    =~ s/d//i;
					$co1--;

					for $cc (
						@{ $lmx::ma_profile->{$table}->{$nn}->{'raw'}->{$c} } )
					{

#print join('&nbsp;-&nbsp;', ($nn, $lmx::ma_conditions_unique->{$table}->[$c], $cc, $lmx::ma_profile->{$table}->{$nn}->{'totals'}->{'min'}, $lmx::ma_profile->{$table}->{$nn}->{'totals'}->{'max'}, $lmx::ma_profile->{$table}->{$nn}->{'totals'}->{'range'})).'<br>';
						$y = sprintf(
							"%d",
							(
								$vspace * (
									(
										$cc - $lmx::ma_profile->{$table}->{$nn}
										  ->{'totals'}->{'min'}
									) / $lmx::ma_profile->{$table}->{$nn}
									  ->{'totals'}->{'range'}
								)
							)
						);
						$x = $hspace * $co1 + $offset{ $nn . '<=>' . $co2 };
						$coord->{x}->[$x]->{ $nn . '<=>' . $co2 }++;
						$coord->{y}->[$y]->{ $nn . '<=>' . $co2 }++;
						$coord->{xy}->{$x}->{$y}->{ $nn . '<=>' . $co2 }++;

   #    print join('&nbsp;-&nbsp;', ($nn.'<=>'.$co2, $co1, $cc, $x, $y)).'<br>';
					}
				}
			}
		}
		$height = $vspace;
		$width  = $hspace * scalar( @{ $lmx::ma_conditions_unique->{$table} } );
		for ( $hh = $height ; $hh > -1 ; $hh-- ) {
			$tag .=
			    '<font size=2>'
			  . sprintf( "%-+3d", ( $hh - $height / 2 ) )
			  . '</font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';

			#    print join('&nbsp;-&nbsp;', keys(%offset)).'<br>';

			for $ww ( 0 .. $width ) {
				$filled = 0;
				for $nn ( keys(%offset) ) {

					#for $nn(@nodes) {
					if ( defined( $coord->{xy}->{$ww}->{$hh}->{$nn} ) ) {
						$size = 1;
						$size = 2 if $coord->{xy}->{$ww}->{$hh}->{$nn} > 1;
						$size = 3 if $coord->{xy}->{$ww}->{$hh}->{$nn} > 2;
						$size = 4 if $coord->{xy}->{$ww}->{$hh}->{$nn} > 3;
						$size = 5 if $coord->{xy}->{$ww}->{$hh}->{$nn} > 4;
						$tag .=
						    '<font size=' . $size . '>'
						  . $marker{ $offset{$nn} }
						  . '</font>';
						$filled = 1;
					}
				}
				$tag .= '&nbsp;' if !$filled;

				#$tag .= '-' if !$filled;
			}
			$tag .= '<br>';
		}
		for $c ( 0 .. $#{ $lmx::ma_conditions_unique->{$table} } ) {
			$hlegend .=
			  $lmx::ma_conditions_unique->{$table}->[$c]
			  . '&nbsp;' x
			  ( $hspace - length( $lmx::ma_conditions_unique->{$table}->[$c] )
			  );
		}
		$i = pair_sign( $nodes[0], $nodes[1] );
		if ( $data->{$i}->{'spearman_rc'} or $data->{$i}->{'pearson_lc'} ) {
			$corrs .= 'Pearson LC=' . $data->{$i}->{'pearson_lc'} . ';&nbsp;'
			  if $data->{$i}->{'pearson_lc'};
			$corrs .= 'Spearman RC=' . $data->{$i}->{'spearman_rc'} . ';'
			  if $data->{$i}->{'spearman_rc'};
			$label = '<font color="red">' . $label . '</font>';
		}
		else {
			$corrs = 'No significant correlation';
		}
		$corrs = '&nbsp;&nbsp;&nbsp;(' . $corrs . ')';
		$tag .= '<hr color=black>';
		$tag .= '&nbsp;' x 6;
		$tag .= $hlegend;
		$tag .= '<hr color=green>';
		for $nn ( sort { $a cmp $b } keys(%offset) ) {
			$id = $nn;
			undef $co2;
			( $id, $co2 ) = ( $1, $2 ) if $nn =~ m/^(.+)\<\=\>(.+)$/i;
			$tag .=
			    $marker{ $offset{$nn} }
			  . ':&nbsp;'
			  . $node->{$id}->{'showname'}
			  . ( $co2 ? ',&nbsp;' . $co2 : '' ) . ';'
			  . '<br>';    #('&nbsp;' x 3);
		}
		$tag .= '<br></font></b>';

		#$tag .= 'AAAAAA';
		$tag .= '\', WRAP';
		$tag .= ', VAUTO';
		$tag .= ', HAUTO';

		#$tag .= ', TEXTCOLOR, \'#000000\'';
		$tag .= ', BGCOLOR, \'#000000\'';
		$tag .= ', FGCOLOR, \'#FFFFFF\'';
		$tag .= ', TEXTFONT, \'Courier New\'';
		$tag .=
", CAPTION, \'MA profiles of $node->{$nodes[0]}->{'showname'} and $node->{$nodes[1]}->{'showname'} $corrs \'";
		$tag .= ');" onmouseout="return nd();">&nbsp;';
		$tag .= $label;
		$tag .= '</a>';
		return $tag;
	}

	sub error_head {
		print $q->header( -title => 'FunCoup error' );

		#  print $q->start_html();
		#  print $q->h1('FunCoup error');
	}

	sub error_foot {
		print $q->p() . "\n";
		print 'Please try again.' . "\n";
		print $q->end_html();
		exit(0);
	}

	sub print_empty_dialog {
		error_head();
		print $q->p( { class => 'error' },
			'The database is empty please fill it with some data!' )
		  . "\n";
		error_foot();
	}

	sub print_no_id_dialog {
		error_head();
		print $q->p(
			{ class => 'error' },
"The database does not contain the identifier(s) you have submitted. Please try other synonyms.
\n"
		);
		print
"It is always a good idea to verify it at <A HREF=\"http\:\/\/www.ensembl.org\/index.html\"\>ensembl.org</A>\n";
		error_foot();
	}

	sub print_noquery_dialog {
		error_head();
		print $q->p( { class => 'error' },
			'The query input field was empty please submit a gene/protein!' )
		  . "\n";
		error_foot();
	}

	sub print_bug_bug {
		error_head();
		print $q->p(
			{ class => 'error' },
			[
				'Software error! Please notify ',
				$q->a(
					{ -href => 'mailto:andale@sbc.su.se' },
					'Andrey Alexeyenko'
				),
				'Sorry!'
			]
		);
		error_foot();
	}

	sub print_not_a_number {
		my $str = shift @_;
		error_head();
		print $q->p("The $str&nbsp; is not a number.");
		error_foot();
	}

	sub pgk2fbs ($) { #confidence value to FBS
		my ($x) = @_;
		my @borders;

		if ( $x > 1 or $x <= 0 ) { die "Invalid Pgk value submitted\n"; }
		@borders = ( 0.3, 0.8, 0.99 );
		if ( $x < $borders[0] ) {
			return (
				sprintf( "%.1f", ( 7.4672 + 2.6819 * ( log($x) / log(10) ) ) )
			);
		}
		elsif ( $x >= $borders[0] and $x < $borders[1] ) {
			return ( sprintf( "%.1f", ( 4.7847 + 4.2614 * $x ) ) );
		}
		elsif ( $x >= $borders[1] and $x < $borders[2] ) {

			return (
				sprintf(
					"%.1f",
					(
						-514.4723 + 1808.7846 * $x - 2091.4733 * $x**2 +
						  808.9313 * $x**3
					)
				)
			);
		}
		elsif ( $x >= $borders[2] ) {
			return ( sprintf( "%.1f", ( -394.1839 + 410.2869 * $x ) ) );
		}
		else { die "Submitted Pgk value out of range...\n"; }
	}

	sub fbs2pgk ($) {  #FBS to confidence value
		my ($x) = @_;
		my ( @borders, $pgk );

		#if ($x > 50) {die "Invalid FBS value submitted\n";}
		if ( $x < 1 ) { return (undef); }
		@borders = ( 6, 7.5, 13 );
		if ( $x < $borders[0] ) {
			$pgk = sprintf( "%.2f",
				( -0.1348 + 0.1344 * $x - 0.0446 * $x**2 + 0.0056 * $x**3 ) );
		}
		elsif ( $x >= $borders[0] and $x < $borders[1] ) {
			$pgk = sprintf( "%.2f", ( -1.1636 + 0.2409 * $x ) );
		}
		elsif ( $x >= $borders[1] and $x < $borders[2] ) {
			$pgk = sprintf( "%.2f",
				( -6.0879 + 1.8064 * $x - 0.1542 * $x**2 + 0.0044 * $x**3 ) );
		}
		elsif ( $x >= $borders[2] ) {
			$pgk = sprintf( "%.2f", ( 0.9967 + 0.0002 * $x ) );
		}
		else { die "Submitted FBS value out of range...\n"; }
		$pgk = '1.00' if $pgk > 1;
		return ( ( $pgk >= 0 ) ? $pgk : undef );
	}

	sub offerURL { #web link to be saved to retrieve this same network later (given the database has not changed)
		my (@genes) = @_;

		my ( $par, $offerURL );
		for $par ( $q->param() ) {
			next if lc($par) eq 'genes';
			if ( $base ne 'all' ) {
				next if $par eq 'species_of_evidence';
				next if $par eq 'type_of_evidence';
			}
			$offerURL .= join( '=', ( $par, $q->param($par) ) ) . ';';
		}

		$offerURL .= 'genes=' . join( '%0D%0A', @genes ) . ';';
		if ( $base ne 'all' ) {
			$offerURL .= 'spoe=' . join( '%0D%0A', @spoe ) . ';'
			  if defined( $q->param('species_of_evidence') );
			$offerURL .= 'tyoe=' . join( '%0D%0A', @tyoe ) . ';'
			  if defined( $q->param('types_of_evidence') );
		}
		$offerURL =~ s/\s/\%20/g;
		$offerURL =~ s/order\=[0-9]/order\=1/g;

		return ($offerURL);
	}

	sub selfLink {
		my ($paramLine) = @_;

		#    $timing .= $q->virtual_host.'<br>';
		#    $timing .= $q->script_name.'<br>';
		$q->script_name =~ m/(cgi.+\.cgi)/i;
		return 'http://' . $q->virtual_host . '/' . $1 . '?' . $paramLine;
	}

	sub webLink {
		my ( $ID, $spec, $DB ) = @_;

		return undef if !$weblink->{$DB}->{$spec}->{start} or !$ID;
		$ID =~ s/^(MGI)\:/$1\%3A/i;
		my $wl = $weblink->{$DB}->{$spec}->{start} . $ID;
		$wl .= $weblink->{$DB}->{$spec}->{end}
		  if defined( $weblink->{$DB}->{$spec}->{end} );
		return $wl;
	}

	sub colorinfo { #color format conversion
		my ( $value, $maxScore ) = @_;
		my ( $red, $green, $blue );

		$green = $red = $blue = 'FF';
		$blue = $red =
		  ( $value > $maxScore->{pos} )
		  ? '00'
		  : sprintf( "%02x", 255 * ( 1 - $value / $maxScore->{pos} ) )
		  if $value > 0;
		$blue = $green =
		  ( $value < $maxScore->{neg} )
		  ? '00'
		  : sprintf( "%02x", 255 * ( 1 - $value / $maxScore->{neg} ) )
		  if $value < 0;
		return '#' . $red . $green . $blue;
	}

	sub colorinfo255 { #color format conversion
		my ( $value, $maxScore ) = @_;
		my ( $red, $green, $blue );
		$green = $red = $blue = '255';
		$blue = $green =
		  ( $value > $maxScore->{pos} )
		  ? '0'
		  : sprintf( "%u", 255 * ( 1 - $value / $maxScore->{pos} ) )
		  if $value > 0;
		$blue = $red =
		  ( $value < $maxScore->{neg} )
		  ? '0'
		  : sprintf( "%u", 255 * ( 1 - $value / $maxScore->{neg} ) )
		  if $value < 0;
		return join( ',', ( $red, $green, $blue ) );
	}

	sub removeJunk {
		my ($text) = @_;
		$text =~ s/\'//g;
		return $text;
	}

	sub olLinkedTag { #pop-up box
		my ( $caption, $text, $b, $i, $fgc, $bgc, @links ) = @_;
		my ( $tag, $hh, $pic );

		$tag .= '<a href="" title="Lookup"';
		$tag .= ' class="tlink"';
		$tag .= ' style="font-size: 9px;"'
		  if ( length($text) > 12 and $text !~ m/interactor/i );
		$tag .=
		  ' onclick="return overlib(\'&nbsp;&nbsp;&nbsp;<b>Lookup</b>\:<br>';
		$tag .= '<ul class=menupic>';
		for $hh (@links) {
			next if !$hh->{text};
			undef $pic;
			$pic = 'double_net' if $hh->{text} =~ m/^Context.+FunCoup/i;
			$pic = 'single_net' if $hh->{text} =~ m/^Sub.+in\sFunCoup/i;
			$pic = 'ensembl'    if $hh->{text} =~ m/ensembl/i;
			$pic = 'uniprot'    if $hh->{text} =~ m/uniprot/i;
			$pic = 'hpa'        if $hh->{text} =~ m/antibody/i;
			$pic = 'mgi'        if $hh->{text} =~ m/^MGI$/;
			$pic = 'kegg'       if $hh->{text} =~ m/KEGG/i;
			$pic = 'pubmed'     if $hh->{href} =~ m/pubmed/i;
			$pic = 'inparanoid' if $hh->{text} =~ m/inparan/i;
			$pic = 'ihop'       if $hh->{text} =~ m/iHOP/;
			$tag .= '<a href=\\\'';
			$tag .= $hh->{href};
			$tag .= '\\\' TARGET=\\\'_blank\\\'>';
			$tag .= '<li class=' . $pic . '><' . $b . '>' if $b;
			$tag .= '<' . $i . '>' if $i;
			$tag .= removeJunk( $hh->{text} );
			$tag .= '</' . $i . '>' if $i;
			$tag .= '</' . $b . '>' if $b;
			$tag .= '</li></a>';
		}
		$tag .= '</ul>';
		$tag .=
		    '\', CAPTION, \'' . $caption
		  . '\', STICKY, FGCOLOR, \'#FFFFFF\', MOUSEOFF, BELOW, CLOSETEXT, \'X\', WRAP, CELLPAD, 5, 15, 4, 5);" onmouseout="return nd();">';
		$tag .= $text;
		$tag .= '</a>';

		return $tag;
	}

	sub datasetBox { #pop-up box (rightmost column of the link-bylink table)
		my ( $d, $g1, $g2 ) = @_;
		my ( $dd, $t, $ty, $url, $spec, $type, $score, $caption, $pad );

		$caption = "Raw scores for $g1 - $g2 and their orthologs";

		$t .= '<a href="" ';
		$t .= ' onclick="return overlib(\'';
		$t .= '<table border=1 class=datasetbox_table>';
		$t .= '<tr class=dataset_header style=\\\'font-size: 9px\\\'>';
		$t .= '<td>Species</td>';
		$t .= '<td>Data<br>type</td>';
		$t .=
'<td>Dataset<br><a href=\\\'http://funcoup.sbc.su.se/inputdata.html\\\' TARGET=\\\'_blank\\\'>(complete list of input data)</a></td>';
		$t .=
'<td>Score<br><a href=\\\'http://funcoup.sbc.su.se/funcoupmetrics.pdf\\\' TARGET=\\\'_blank\\\' style=\\\'font-size: 14px\\\'>?</a></td>';
		$t .= '<td>Value</td>';
		$t .= '</tr>';

		for $dd ( sort { $a cmp $b } keys( %{$funcoupweb::dataset} ) ) {
			if ( $d->{$dd} ) {
				$pad = ( $d->{$dd} =~ m/^\-/ ) ? '' : '&nbsp;';
				$spec = ( $dd =~ m/^([a-z]{3})\_/ ) ? $1 : 'no species found';
				if ( $dd =~ m/hpa/i ) { $type = 'hpa'; }
				else {
					for $ty (@types_of_evidence) {
						$type = $ty
						  if ( $dd =~ m/$ty/i );
					}
				}
				for $ty ( keys(%funcoupweb::metrics) ) {
					$score = $funcoupweb::metrics{$ty} if ( $dd =~ m/$ty/i );
				}
				if (    $dd =~ m/pears.+gse/i
					and $funcoupweb::dataset->{$dd}->{url} =~ m/[0-9]{3,5}/ )
				{
					$url =
					    $funcoupweb::dataset->{links}->{geo}
					  . $funcoupweb::dataset->{$dd}->{url};
				}
				elsif ( $funcoupweb::dataset->{$dd}->{url} =~ m/[0-9]{5,}/ ) {
					$url =
					    $funcoupweb::dataset->{links}->{pubmed}
					  . $funcoupweb::dataset->{$dd}->{url};
				}
				else { $url = $funcoupweb::dataset->{$dd}->{url}; }
				$t .= '<tr>';
				$t .=
				    '<td class=\\\'' . $spec
				  . '_style padd spec_type\\\'>'
				  . $spec . '</td>';
				$t .=
				    '<td class=\\\'' . $type
				  . '_style padd spec_type\\\'>'
				  . $funcoupweb::lbl{$type} . '</td>';
				$t .= '<td class=padd>' . $funcoupweb::dataset->{$dd}->{name};
				$t .=
				    ' <a class=dataset_a href=\\\'' . $url
				  . '\\\' TARGET=\\\'_blank\\\'>('
				  . $funcoupweb::dataset->{$dd}->{tag} . ')</a>'
				  if $funcoupweb::dataset->{$dd}->{tag};
				$t .= '</td>';

				$t .= '<td class=\\\'padd score_cell\\\'>' . $score . '</td>';
				$t .=
				  '<td class=\\\'value_cell padd\\\'>' . $pad
				  . $d->{$dd} . '</td>';
				$t .= '</tr>';
			}
		}
		$t .= '</table>';
		$t .=
		    '\', CAPTION, \'' . $caption
		  . '\', STICKY, BGCOLOR, \'#DDDDDD\', FGCOLOR, \'#FFFFFF\', CAPCOLOR, \'#000000\', MOUSEOFF, BELOW, CLOSETEXT, \'X\', WRAP, CELLPAD, 5, 15, 4, 5);" onmouseout="return nd();">data</a>';
		return ($t);
	}

	sub visualTag { #quick pop-up datatype- or species-specific color box
		my ( $value, $source, $kind_of_score, $current_species, $prot1, $prot2,
			$fbs, $raw )
		  = @_;
		my ( $tag, $s, $hh, $label, $box, $text );

		if ( !$value ) {
			$text = '&nbsp;&nbsp;&nbsp;';
			$box  = 'No evidence from '
			  . (
				$label{$source}
				? lc( $label{$source} )
				: '<i>' . $org{$source} . '</i>'
			  );
		}
		else {
			if ( $kind_of_score eq 'final' ) {
				$text = $value;
				$box .= $label{$source} . $value;
				$box .= ';<br>' . $kind_of_score . ' Bayesian score = ' . $fbs;
			}
			elsif ( $kind_of_score eq 'partial' ) {
				for $s ( 1 .. $#FBSscale ) {
					if (    ( $value >= $FBSscale[ $s - 1 ]->{upper_value} )
						and ( $value < $FBSscale[$s]->{upper_value} ) )
					{
						$label = $FBSscale[$s]->{label};
					}
				}
				$label = $FBSscale[0]->{label}
				  if $value < $FBSscale[0]->{upper_value};
				$text = sprintf( "%d",
					( ( 100 * $value / $fbs ) + ( $value > 0 ? 0.5 : -0.5 ) ) );

				#$text = int(((100 * $value / $fbs) + 0.5));
				$box .= $label;
				$box .= ' evidence from ';
				$box .=
				  $label{$source}
				  ? lc( $label{$source} )
				  : '<i>' . $org{$source} . '</i>';
				$box .=
				  ';<br>' . $kind_of_score . ' Bayesian score = ' . $value;
				$box .=
				    ", which is "
				  . ( ( $text >= 0 ) ? '' : 'negative ' )
				  . abs($text)
				  . '% of the total';
				$text .= '%';
				$text = '&nbsp;&nbsp;&nbsp;';
			}
			else { die "Type of score undefined...\n"; }
		}
		$text = removeJunk($text);

		if ( $source eq 'phylo' ) {
			return olTaggedPhylo(
				$text, $box, '', '',
				$hexcolor{ $ID{white} },
				$hexcolor{ $ID{$source} },
				1, $current_species, $prot1, $prot2, $raw
			);
		}
		elsif ( $source eq 'ppi' ) {
			return olTaggedPPI(
				$text, $box, '', '',
				$hexcolor{ $ID{white} },
				$hexcolor{ $ID{$source} },
				1, $current_species, $prot1, $prot2, $raw
			);
		}
		else {
			return olTagged(
				$text, $box, '', '',
				$hexcolor{ $ID{white} },
				$hexcolor{ $ID{$source} }, 1
			);
		}
	}

	sub olTagged {
		my ( $text, $box, $b, $i, $fgc, $bgc, $colorfont ) = @_;
		my ($tag);

		if ( ( lc($bgc) eq lc( $hexcolor{ $ID{white} } ) || !$bgc )
			and lc($fgc) eq lc( $hexcolor{ $ID{white} } ) )
		{
			$fgc = $hexcolor{ $ID{black} };
		}
		$fgc =~ s/\"/\'/g if $fgc;
		$bgc =~ s/\"/\'/g if $bgc;
		$tag .= '<a onmouseover="return overlib(\'';
		$tag .= '<' . $b . '>' if $b;
		$tag .= '<' . $i . '>' if $i;
		$tag .= removeJunk($box);
		$tag .= '</' . $i . '>' if $i;
		$tag .= '</' . $b . '>' if $b;
		$tag .= '\', WRAP';
		$tag .= ', TEXTCOLOR, ' . $fgc if $fgc;
		$tag .= ', FGCOLOR, ' . $bgc if $bgc;
		$tag .= ', BGCOLOR, ' . $bgc if $bgc;
		$tag .= ');" onmouseout="return nd();">' . $text . '</a>';

#$tag = $colorfont ? ('<font face="Verdana" size="1" color="#000000">'.$tag.'</font>') : $tag;
#$tag = $colorfont ? ('<b><font face="Verdana" size="1" color="#000000">&nbsp;&nbsp;</font></b>') : $tag;
		return $tag;
	}

	sub olTaggedPhylo { #special pop-up box format to display phylogenetic evidence with pics
		my ( $text, $box, $B, $i, $fgc, $bgc, $colorfont, $current_species,
			$prot1, $prot2, $raw )
		  = @_;
		my ( $tag, $clade );

		if ( ( lc($bgc) eq lc( $hexcolor{ $ID{white} } ) || !$bgc )
			and lc($fgc) eq lc( $hexcolor{ $ID{white} } ) )
		{
			$fgc = $hexcolor{ $ID{black} };
		}
		$fgc =~ s/\"/\'/g if $fgc;
		$bgc =~ s/\"/\'/g if $bgc;
		$tag .= '<a onmouseover="return overlib(\'';
		$tag .= removeJunk($box);
		if ( $current_species eq $raw ) {
			$tag .=
			    '.<br>Orthologs of '
			  . $node->{$prot1}->{'showname'} . ' and '
			  . $node->{$prot2}->{'showname'}
			  . ' are not found simultaneously in any of the profiled eukaryotic genomes.';
		}
		else {
			$tag .=
			    '.<br>Orthologs of '
			  . $node->{$prot1}->{'showname'} . ' and '
			  . $node->{$prot2}->{'showname'}
			  . ' are found in:<br>';
			$tag .= '<table>';
			for $clade (
				sort { $cladeImage->{$a}->{num} <=> $cladeImage->{$b}->{num} }
				split( '_', $raw )
			  )
			{
				$tag .=
				    '<tr><td><img src='
				  . $graf_path
				  . $cladeImage->{$clade}->{img} . '.GIF'
				  . ' /></td><td>'
				  . $cladeImage->{$clade}->{lbl}
				  . '</td></tr>';
			}
			$tag .= '</table>';
		}
		$tag .= '\', WRAP';
		$tag .= ', TEXTCOLOR, ' . $fgc if $fgc;
		$tag .= ', FGCOLOR, ' . $bgc if $bgc;
		$tag .= ', BGCOLOR, ' . $bgc if $bgc;
		$tag .= ');" onmouseout="return nd();">' . $text . '</a>';

#$tag = $colorfont ? ('<font face="Verdana" size="1" color="#000000">'.$tag.'</font>') : $tag;
		return $tag;
	}

	sub olTaggedPPI { #special pop-up box format to display PPI evidence with web links
		my ( $text, $box, $B, $i, $fgc, $bgc, $colorfont, $current_species,
			$prot1, $prot2, $raw )
		  = @_;
		my ( $tag, $clade, $hh );

		if ( ( lc($bgc) eq lc( $hexcolor{ $ID{white} } ) || !$bgc )
			and lc($fgc) eq lc( $hexcolor{ $ID{white} } ) )
		{
			$fgc = $hexcolor{ $ID{black} };
		}
		$fgc =~ s/\"/\'/g if $fgc;
		$bgc =~ s/\"/\'/g if $bgc;
		$tag .= '<a onmouseover="return overlib(\'';
		$tag .= removeJunk($box);
		if ( defined( $pairwiseSupplementary->{$prot1}->{$prot2} ) ) {
			$tag .=
";<br><br>The following PPI evidence exists about a link between the $tag{$current_species} $node->{$prot1}->{'showname'} and $node->{$prot2}->{'showname'}\:\<ul\ class\=ppi_list>";
			for $hh ( @{ $pairwiseSupplementary->{$prot1}->{$prot2} } ) {
				$tag .= '<li>' . $hh->{text} . '</li>';
			}
			$tag .= '</ul>';
		}

		$tag .= '\', WRAP';
		$tag .= ', MOUSEOFF, BELOW, WIDTH, 500, STICKY, TEXTCOLOR, ' . $fgc
		  if $fgc;
		$tag .= ', FGCOLOR, ' . $bgc if $bgc;
		$tag .= ', BGCOLOR, ' . $bgc if $bgc;
		$tag .= ');" onmouseout="return nd();">' . $text . '</a>';

#$tag = $colorfont ? ('<font face="Verdana" size="1" color="#000000">'.$tag.'</font>') : $tag;
		return $tag;
	}

	sub extraLinks { #gene-specific pop-up box to display various links
		my ( $current_species, $gene, $geneName, $gene2, $geneName2 ) = @_;
		my ( $ww,              $l,    @links,    $ppi,   $geneID );

		$l = 0;
		for $ww ( keys( %{$weblink} ) ) {
			$geneID = $gene;
			next
			  if ( $ww =~ /Antibody\ssta/ )
			  and ( !$extra->{$gene}->{'HPA'} );
			if ( $ww =~ /iHOP|uniprot/i ) {
				next
				  if (  !$extra->{$gene}->{'uniprot'}
					and !$node->{$gene}->{'sptr'} );
				$geneID = $node->{$gene}->{'sptr'};
				$geneID = $extra->{$gene}->{'uniprot'}
				  if !$node->{$gene}->{'sptr'};
			}
			if ( defined( $weblink->{$ww}->{$current_species}->{start} ) ) {
				$links[$l]->{href} =
				  $weblink->{$ww}->{$current_species}->{start} . $geneID;
				$links[$l]->{href} .= $weblink->{$ww}->{$current_species}->{end}
				  if defined( $weblink->{$ww}->{$current_species}->{end} );
				$links[ $l++ ]->{text} = $ww;
			}
		}
		if ($gene2) {
			$links[$l]->{href} = selfLink( offerURL( $gene, $gene2 ) );
			$links[ $l++ ]->{text} =
			  "Context sub-network of $geneName and $geneName2 in FunCoup";
		}
		$links[$l]->{href} = selfLink( offerURL($gene) );
		$links[ $l++ ]->{text} =
		    'Sub-network of '
		  . $geneName
		  . ( $gene2 ? ' alone' : '' )
		  . ' in FunCoup';
		if (    defined($gene)
			and defined($gene2)
			and defined( $pairwiseSupplementary->{$gene}->{$gene2} ) )
		{
			for $ppi ( @{ $pairwiseSupplementary->{$gene}->{$gene2} } ) {
				next if $ppi->{text} !~ m/href\=/;
				$links[$l]->{href} = pubmedLink( $ppi->{pmid} );
				$links[$l]->{text} = $1 if $ppi->{text} =~ m/\>(.+)\<\/a\>/;
				$l++;
			}
		}
		return @links;
	}

	sub pubmedLink {
		my ($id) = @_;
		return
		  'http://www.ncbi.nlm.nih.gov/sites/entrez?db=pubmed&cmd=search&term='
		  . $id
		  if $id =~ m/^[0-9]{5}/;
	}

	sub pathwayLinks {
		my ( $current_species, $gene ) = @_;
		my ( $pp, $l, @links );

		#my($qw) = '"';

		$l = 0;
		for $pp ( keys( %{ $pathwayMembership->{$gene}->{'kegg_id'} } ) ) {
			$links[$l]->{href} = $kegg_id_url . $pp;
			$links[ $l++ ]->{text} = 'KEGG orthology entry ' . $pp;
		}
		for $pp ( keys( %{ $pathwayMembership->{$gene}->{'pathway'} } ) ) {
			$links[$l]->{href} = $kegg_url;
			$links[$l]->{href} =~ s/SSS/$current_species/;
			$links[$l]->{href} =~ s/MMMMM/$pp/;
			$links[ $l++ ]->{text} =
			    'The enzyme '
			  . $pathwayMembership->{$gene}->{'pathway'}->{$pp}->{'ec'} . ' in '
			  . $org{$current_species}
			  . ' KEGG pathway \\\''
			  . $pathwayMembership->{$gene}->{'pathway'}->{$pp}->{'description'}
			  . '\\\'';
		}
		return @links;
	}

	sub pair_sign { #creates a "footprint" for gene pairs
		return undef if ( scalar(@_) != 2 );
		return join( '<=>', sort { $a cmp $b } @_ );
	}

	sub define_data {
		my ( $i, @cl, $cc, $itagClose, $itag, $oo );

		$uniprot_table     = 'uniprot_sptr_2_funcoup_reference_7eukaryotes';
		$pathway_table     = 'kegg_pathways';
		$GO_table          = 'fcgene2go';
		$nonconventional   = 'nonconventional_links';
		$extra_data        = 'extra_data';
		$ppi_refs          = 'ppi_refs';
		$optnames          = 'optnames1';
		$fcgene2go         = 'fcgene2go';
		@types_of_evidence =
		  ( 'ppi', 'pearson', 'coloc', 'phylo', 'mirna', 'tf', 'hpa',
			'domain' );
		@species_of_evidence =
		  ( 'hsa', 'mmu', 'rno', 'dre', 'dme', 'cel', 'sce', 'ath' );
		@nonconfidence = (
			'dataset',  'blast_score', 'ortho', 'gene_nei',
			'mirna_ol', 'mirna_tg',    'tf_2gene'
		);
		push @nonconfidence,
		  (
			  ( $submitted_species eq 'mouse' )
			? ( 'lmx', 'lmx2' )
			: ( 'zfish', 'zfish2' )
		  )
		  if $lmx;

		%initSettings = (
			"distributeOnInit" => 'true',
			"showMedusaStyle"  => 'false',
			"showNodeLabels"   => 'true',
			"showEdgeLabels"   => 'false',
			"showNodeSize"     => 'true',
			"showUniformNodes" => 'false',
			"showEdgeConf"     => 'true',
			"showGroupLabels"  => 'false'
		);

		@{ $defined_FC_types{'hsa'} } =
		  ( 'fbs_ppi_mt', 'fbs_met_mt', 'fbs_sig_mt', 'fbs_up_complex' );
		@{ $defined_FC_types{'gga'} } =
		  ( 'fbs_allpat', 'fbs_met_mt', 'fbs_sig_mt', );
		@{ $defined_FC_types{'mmu'} } =
		  ( 'fbs_ppi_mt', 'fbs_met_mt', 'fbs_sig_mt' );
		@{ $defined_FC_types{'rno'} } = ( 'fbs_met_mt', 'fbs_sig_mt' );
		@{ $defined_FC_types{'dme'} } =
		  ( 'fbs_ppi_mt', 'fbs_met_mt', 'fbs_sig_mt' );
		@{ $defined_FC_types{'cel'} } =
		  ( 'fbs_up_complex', 'fbs_ppi_mt', 'fbs_met_mt', 'fbs_sig_mt' );
		@{ $defined_FC_types{'sce'} } =
		  ( 'fbs_up_complex', 'fbs_ppi_mt', 'fbs_met_mt', 'fbs_sig_mt' );
		@{ $defined_FC_types{'ath'} } = ( 'fbs_met_mt', 'fbs_sig_mt' );
		@{ $defined_FC_types{'dre'} } = ('fbs_allpat');
		@{ $defined_FC_types{'cin'} } = ( 'fbs_kegg_hc', 'fbs_kegg_signal_hc' );
		$species{'human'}       = 'hsa';
		$species{'mouse'}       = 'mmu';
		$species{'rat'}         = 'rno';
		$species{'chicken'}     = 'gga';
		$species{'zfish'}       = 'dre';
		$species{'fly'}         = 'dme';
		$species{'worm'}        = 'cel';
		$species{'yeast'}       = 'sce';
		$species{'Arabidopsis'} = 'ath';
		$species{'Ciona'}       = 'cin';
		$species{'hsa'}         = 'hsa';
		$species{'mmu'}         = 'mmu';
		$species{'rno'}         = 'rno';
		$species{'gga'}         = 'gga';
		$species{'dme'}         = 'dme';
		$species{'dre'}         = 'dre';
		$species{'cel'}         = 'cel';
		$species{'sce'}         = 'sce';
		$species{'ath'}         = 'ath';
		$species{'cin'}         = 'cin';

		$org{'cin'} = 'Ciona';
		$org{'hsa'} = 'human';
		$org{'mmu'} = 'mouse';
		$org{'rno'} = 'rat';
		$org{'gga'} = 'chicken';
		$org{'dre'} = 'zfish';
		$org{'dme'} = 'fly';
		$org{'cel'} = 'worm';
		$org{'sce'} = 'yeast';
		$org{'ath'} = 'Arabidopsis';
		$itag      = ( $output eq 'webgraph' ) ? '<i>'  : '';
		$itagClose = ( $output eq 'webgraph' ) ? '</i>' : '';
############################
		$org{'cin'} = 'C. intestinalis';
		$org{'hsa'} = 'H. sapiens';
		$org{'mmu'} = 'M. musculus';
		$org{'gga'} = 'G. gallus';
		$org{'dre'} = 'D. rerio';
		$org{'rno'} = 'R. norvegicus';
		$org{'dme'} = 'D. melanogaster';
		$org{'cel'} = 'C. elegans';
		$org{'sce'} = 'S. cerevisiae';
		$org{'ath'} = 'A. thaliana';

		$tag{'no species found'} = 'no species found';
		$tag{'cin'}              = 'Ciona';
		$tag{'hsa'}              = 'human';
		$tag{'mmu'}              = 'mouse';
		$tag{'rno'}              = 'rat';
		$tag{'gga'}              = 'chicken';
		$tag{'dre'}              = 'zfish';
		$tag{'dme'}              = 'fly';
		$tag{'cel'}              = 'worm';
		$tag{'sce'}              = 'yeast';
		$tag{'ath'}              = 'Arabidopsis';
		$tag{'fbs'}              = 'Summary score';
		$tag{'coloc'}            = 'Sub-cellular co-localization';
		$tag{'phylo'}            = 'Similarity of phylogenetic profiles';
		$tag{'ppi'}              = 'Protein-protein interactions';
		$tag{'pearson'}          = 'mRNA co-expression';
		$tag{'mirna'}            = 'Co-regulation by miRNA';
		$tag{'tf'}               = 'Co-regulation by transcription factors';
		$tag{'hpa'}              = 'Protein co-expression';
		$tag{'domain'}           = 'Co-interacting domains';
		$tag{'mirna_ol'}         = 'miRNA and protein genes overlap';
		$tag{'mirna_tg'}         = 'miRNA targets protein gene';
		$tag{'tf_2gene'}         = 'TF targets protein gene';
		$tag{'gene_nei'}         = 'Proximity on chromosome';
		$tag{'dataset'}          = 'The published data set';
		$tag{'lmx'}              = 'Lmx1a vs. (Phox2b + Wt)'
		  if $criteria{contrast} eq 'lmx1a_vs_rest';
		$tag{'lmx'} = 'Lmx1a vs. Phox2b'
		  if $criteria{contrast} eq 'lmx1a_vs_phox2b';
		$tag{'lmx'} = 'Lmx1a vs. Wt' if $criteria{contrast} eq 'lmx1a_vs_wt';
		$tag{'lmx'} = 'Phox2b vs. (Lmx1a + Wt)'
		  if $criteria{contrast} eq 'phox2b_vs_rest';
		$tag{'lmx'} = 'microarray' if !$tag{'lmx'};

		$tag{'zfish'} = 'Dioxin-enabled';
		$tag{'zfish'} = 'Developmental'
		  if defined( $criteria{pairwise} )
		  and ( $criteria{pairwise} eq 'development' );
		$tag{'zfish'} = 'Dioxin-resistant'
		  if defined( $criteria{pairwise} )
		  and ( $criteria{pairwise} eq 'dioxinres' );
		$tag{'zfish2'} = 'Dioxin-sensitive';

		#$tag{''} = '';
		$tag{'prot1'}       = '1st protein';
		$tag{'prot2'}       = '2nd protein';
		$tag{'blast_score'} = 'Sequence similarity';

		#$tag{''} = '';

		$FBScol{'all'}      = 'fbs_max';
		$FBScol{'signal'}   = 'fbs_sig_mt';
		$FBScol{'kegg2004'} = 'fbs_met_mt';
		$FBScol{'ppi'}      = 'fbs_ppi_mt';
		$FBScol{'complex'}  = 'fbs_up_complex';
###########################

		$sty{'cin'}     = 'Ciona';
		$sty{'hsa'}     = 'human';
		$sty{'mmu'}     = 'mouse';
		$sty{'rno'}     = 'rat';
		$sty{'gga'}     = 'chicken';
		$sty{'dre'}     = 'zfish';
		$sty{'dme'}     = 'fly';
		$sty{'cel'}     = 'worm';
		$sty{'sce'}     = 'yeast';
		$sty{'ath'}     = 'Arabidopsis';
		$sty{'fbs'}     = 'Summary score';
		$sty{'coloc'}   = 'Sub-cellular co-localization';
		$sty{'phylo'}   = 'Similarity of phylogenetic profiles';
		$sty{'ppi'}     = 'Protein-protein interactions';
		$sty{'pearson'} = 'mRNA co-expression';

		$sty{'mirna'}  = $tag{'mirna'};
		$sty{'tf'}     = $tag{'tf'};
		$sty{'hpa'}    = $tag{'hpa'};
		$sty{'domain'} = $tag{'domain'};
		$sty{'lmx'}    = $tag{'lmx'};
		$sty{'lmx2'}   = $tag{'lmx2'};
		$sty{'zfish'}  = $tag{'zfish'};
		$sty{'zfish2'} = $tag{'zfish2'};

		$sty{'mirna_ol'} = 'miRNA and protein genes overlap';
		$sty{'mirna_tg'} = 'miRNA targets protein gene';
		$sty{'tf_2gene'} = 'TF targets protein gene';
		$sty{'gene_nei'} = 'Proximity on chromosome';
		$sty{'dataset'}  = 'Published link';

		$sty{'fbs_allpat'}         = 'Functional coupling';
		$sty{'fbs_up_complex'}     = 'Protein complex';
		$sty{'fbs_ppi_mt'}         = 'Protein-protein interaction';
		$sty{'fbs_met_mt'}         = 'Metabolic';
		$sty{'fbs_sig_mt'}         = 'Signaling';
		$sty{'fbs_kegg_hc'}        = 'Metabolic';
		$sty{'fbs_kegg_signal_hc'} = 'Signaling';

		$sty{'prot1'}       = '1st protein';
		$sty{'prot2'}       = '2nd protein';
		$sty{'blast_score'} = 'Paralogs';
		$sty{'ortho'}       = 'Orthologs';

		$ev{'signal'}                                   = 'signal';
		$ev{'ppi'}                                      = 'ppi';
		$ev{'nonsig'}                                   = 'nonsig';
		$ev{'kegg2004'}                                 = 'kegg2004';
		$ev{'complex'}                                  = 'complex';
		$ev{'ciona_lc'}                                 = 'ciona_lc';
		$ev{'ciona_hc'}                                 = 'ciona_hc';
		$ev{'ciona_signal_lc'}                          = 'ciona_signal_lc';
		$ev{'ciona_signal_hc'}                          = 'ciona_signal_hc';
		$ev{'Final Bayesian score'}                     = 'fbs';
		$ev{'Physical interactions'}                    = 'ppi';
		$ev{'Co-expression'}                            = 'pearson';
		$ev{'Similarity of phylogenetic profiles'}      = 'phylo';
		$ev{'Sub-cellular co-localization'}             = 'coloc';
		$ev{'miRNA (co)regulation'}                     = 'mirna';
		$ev{'(Co)regulation by transcription factors'}  = 'tf';
		$ev{'Protein expression (Human Protein Atlas)'} = 'hpa';
		$ev{'Co-interacting domains'}                   = 'domain';

		$ev{'mirna_ol'} = $sty{'mirna_ol'};
		$ev{'mirna_tg'} = $sty{'mirna_tg'};
		$ev{'tf_2gene'} = $sty{'tf_2gene'};
		$ev{'gene_nei'} = $sty{'gene_nei'};
		$ev{'dataset'}  = $sty{'dataset'};

		$ev{'Paralogs'}         = 'blast_score';
		$ev{'Orthologs'}        = 'ortho';
		$algo_descr{'noislets'} =
'an algorithm prioritizing stronger links, preferring closer neighbors of the query';
		$algo_descr{'maxcoverage'} =
'an algorithm prioritizing stronger links and ignoring their relative position';
		$algo_descr{'aracne_simple'} =
'the ARACNE algorithm that, out of the 3 loop-like links, cancels the weakest one - and never removes nodes';
		$algo_descr{'aracne_ppi'} =
'a modification of the ARACNE algorithm where the weakest of each 3 links is cancelled unless it is supported with an evidence of physical interaction';
		$algo_descr{'score'} =
		  "retaining only the $desired_links_total strongest links";
		$algo_descr{'order'} =
'Links beweeen the neighbors of your query genes are not shown to reduce the network size.';
		$algo_descr{'noislets'} =
'algorithm <a href="http://funcoup.sbc.su.se/algo.html#noislets" target="_blank"><b>(1)</b></a>';
		$algo_descr{'maxcoverage'} =
'algorithm <a href="http://funcoup.sbc.su.se/algo.html#maxcoverage" target="_blank"><b>(2)</b></a>';
		$algo_descr{'aracne_simple'} =
'algorithm <a href="http://funcoup.sbc.su.se/algo.html#aracne_simple" target="_blank"><b>(3)</b></a>';
		$algo_descr{'aracne_ppi'} =
'algorithm <a href="http://funcoup.sbc.su.se/algo.html#aracne_ppi" target="_blank"><b>(4)</b></a>';
		$algo_descr{'score'} =
'algorithm <a href="http://funcoup.sbc.su.se/algo.html" target="_blank"><b>(5)</b></a>';
		$algo_descr{'order'} =
'algorithm <a href="http://funcoup.sbc.su.se/algo.html" target="_blank"><b>(6)</b></a>';
		$algo_descr{''} = '';

		#	$ev{'Signaling links'} = 'signal';
		#	$ev{'Metabolic links'} = 'kegg2004';
#NEW NETWORK TABLES CREATED IN SQL MUST BE DEFINED HERE:
		$network->{'hsa'}->{'all'} = 'human_version_1';
		$network->{'mmu'}->{'all'} = 'mouse_version_1';
		$network->{'rno'}->{'all'} = 'rat_version_1';
		$network->{'dre'}->{'all'} = 'zfish_version4';
		$network->{'dre'}->{'all'} = 'zfish_version_x';
		$network->{'gga'}->{'all'} = 'chicken_version_x';
		$network->{'cin'}->{'all'} = 'ciona_version_1';
		$network->{'dme'}->{'all'} = 'fly_version_1';
		$network->{'cel'}->{'all'} = 'worm_version_1';
		$network->{'sce'}->{'all'} = 'yeast_version_1';      #_narrow
		$network->{'ath'}->{'all'} = 'thaliana_version_1';

		$linkname{'kegg2004'} = 'metabolic';
		$linkname{'ppi'}      = 'physical interaction';
		$linkname{'complex'}  = 'the same protein complex';
		$linkname{'signal'}   = 'signaling';

		$ID{ppi}      = '2';
		$ID{kegg2004} = '3';
		$ID{signal}   = '4';
		$ID{nonsig}   = '5';

		$ID{lc}        = '2';
		$ID{hc}        = '3';
		$ID{signal_lc} = '4';
		$ID{signal_hc} = '5';

		$ID{fbs_allpat} = $ID{fbs} = '1';
		$ID{ppi}        = '2';
		$ID{pearson}    = '3';
		$ID{coloc}      = '4';
		$ID{phylo}      = '5';
		$ID{hsa}        = '6';
		$ID{mmu}        = '7';
		$ID{rno}        = '8';
		$ID{dme}        = '9';
		$ID{cel}        = '11';
		$ID{sce}        = '10';
		$ID{ath}        = '12';
		$ID{invisible}  = '13';
		$ID{neighbor_link} = '14';
		$ID{blast_score}   = '15';
		$ID{ortho}         = '16';
		$ID{cin}           = '17';
		$ID{signal}        = '18';
		$ID{kegg2004}      = '19';
		$ID{complex}       = '21';
		$ID{violet}        = '20';
		$ID{white}         = '22';
		$ID{black}         = '23';
		$ID{dre}           = '24';
		$ID{prot2}         = '25';
		$ID{prot1}         = '26';
		$ID{confidence}    = '27';
		$ID{mirna}         = '28';
		$ID{tf}            = '29';
		$ID{hpa}           = '30';
		$ID{domain}        = '31';

		$ID{fbs_up_complex}     = 32;
		$ID{fbs_ppi_mt}         = 33;
		$ID{fbs_kegg_hc}        = $ID{fbs_met_mt} = 34;
		$ID{fbs_kegg_signal_hc} = $ID{fbs_sig_mt} = 35;

		$ID{mirna_ol} = 36;
		$ID{mirna_tg} = 37;
		$ID{gene_nei} = 38;
		$ID{tf_2gene} = 39;
		$ID{dataset}  = 40;
		$ID{lmx}      = 41;
		$ID{zfish}    = 42;
		$ID{lmx2}     = 43;
		$ID{zfish2}   = 44;
		$ID{gga}      = 45;

		$color{ $ID{white} } = '255,255,255';
		$color{ $ID{black} } = '0,0,0';
		$color{ $ID{fbs} }   = '120,120,120';

		#$color{$ID{ppi}} = '230,216,174';
		$color{ $ID{ppi} } = '255,0,0';

		#	$color{$ID{pearson}} = '0,255,127';
		$color{ $ID{pearson} }  = '0,0,255';
		$color{ $ID{kegg2004} } = '0,0,255';
		$color{ $ID{coloc} }    = '140,0,140';
		$color{ $ID{phylo} }    = '128,0,0';
		$color{ $ID{mirna} }    = '0,80,80';
		$color{ $ID{tf} }       = '80,80,0';
		$color{ $ID{hpa} }      = '80,150,0';
		$color{ $ID{domain} }   = '0,0,128';

		$color{ $ID{mirna_ol} } = '0,80,200';
		$color{ $ID{mirna_tg} } = '0,160,80';
		$color{ $ID{gene_nei} } = '80,0,80';
		$color{ $ID{tf_2gene} } = '160,160,0';
		$color{ $ID{dataset} }  = '160,0,160';
		$color{ $ID{lmx} }      = '255,150,0';
		$color{ $ID{lmx2} }     = '0,150,255';
		$color{ $ID{zfish} }    = '200,100,0';
		$color{ $ID{zfish} }    = '0,200,0'
		  if defined( $criteria{pairwise} )
		  and ( $criteria{pairwise} eq 'development' );
		$color{ $ID{zfish} } = '80,120,80'
		  if defined( $criteria{pairwise} )
		  and ( $criteria{pairwise} eq 'dioxinres' );

		$color{ $ID{zfish2} } = '0,100,200';

		$color{ $ID{signal} }         = '0,128,0';
		$color{ $ID{hsa} }            = '255,0,128';
		$color{ $ID{mmu} }            = '180,0,200';
		$color{ $ID{rno} }            = '170,20,80';
		$color{ $ID{gga} }            = '160,80,20';
		$color{ $ID{dre} }            = '64,64,160';
		$color{ $ID{dme} }            = '64,160,160';
		$color{ $ID{cin} }            = '120,120,255';
		$color{ $ID{sce} }            = '128,128,0';
		$color{ $ID{cel} }            = '255,128,64';
		$color{ $ID{ath} }            = '50,255,50';
		$color{ $ID{invisible} }      = '255,255,255';
		$color{ $ID{neighbor_link} }  = '255,255,0';
		$color{ $ID{blast_score} }    = '0,127,255';
		$color{ $ID{violet} }         = '150,90,150';
		$color{ $ID{fbs_up_complex} } = '120,120,0';
		$color{ $ID{fbs_ppi_mt} }     = '255,0,0';
		$color{ $ID{fbs_met_mt} }     = '0,0,255';
		$color{ $ID{fbs_sig_mt} }     = '0,255,0';
		$color{ $ID{ortho} }          = '0,200,80';
		$color{query}                 = '255,255,0';
		$color{context}               = '255,128,255';
		$color{ $ID{prot2} }          = '0,0,0';
		$color{ $ID{prot1} }          = '0,0,0';
		$color{ $ID{confidence} }     = '0,0,0';

		#	$color{'0'} = '120,120,120';
		$color{'0'} = '0,0,0';

		$bzc{ $ID{kegg2004} }       = 0.5;
		$bzc{ $ID{complex} }        = -0.5;
		$bzc{ $ID{signal} }         = -1.0;
		$bzc{ $ID{fbs_up_complex} } = -0.5;
		$bzc{ $ID{fbs_ppi_mt} }     = 0.5;
		$bzc{ $ID{fbs_met_mt} }     = -1;
		$bzc{ $ID{fbs_sig_mt} }     = 1;

		$dash{ $ID{ortho} }       = '7,4';
		$dash{ $ID{blast_score} } = '6,3';
		$dash{ $ID{gene_nei} }    = '2,2';
		$dash{ $ID{zfish} }       = $dash{ $ID{lmx} } = $dash{ $ID{zfish2} } =
		  $dash{ $ID{lmx2} }      = '4,2';

		$bzc{ $ID{fbs} }      = '0.0';
		$bzc{ $ID{tf_2gene} } = 3.1;
		$bzc{ $ID{gene_nei} } = 2.5;
		$bzc{ $ID{hpa} }      = 2.0;
		$bzc{ $ID{coloc} }    = 1.5;
		$bzc{ $ID{tf} }       = 1.0;
		$bzc{ $ID{pearson} }  = 0.5;
		$bzc{ $ID{ppi} }      = -0.5;
		$bzc{ $ID{mirna} }    = -1.0;
		$bzc{ $ID{phylo} }    = -1.5;
		$bzc{ $ID{domain} }   = -2.0;
		$bzc{ $ID{mirna_ol} } = -2.5;
		$bzc{ $ID{dataset} }  = 0.0;
		$bzc{ $ID{zfish} }    = $bzc{ $ID{lmx} } = -1.8;
		$bzc{ $ID{zfish2} }   = $bzc{ $ID{lmx2} } = 1.8;
		$bzc{ $ID{mirna_tg} } = -3.0;

		$bzc{ $ID{hsa} }           = -1.5;
		$bzc{ $ID{mmu} }           = -2.0;
		$bzc{ $ID{rno} }           = -2.5;
		$bzc{ $ID{cin} }           = -1;
		$bzc{ $ID{dme} }           = 1.5;
		$bzc{ $ID{dre} }           = 3.0;
		$bzc{ $ID{gga} }           = 2.9;
		$bzc{ $ID{cel} }           = 2.0;
		$bzc{ $ID{sce} }           = 2.5;
		$bzc{ $ID{ath} }           = -3.0;
		$bzc{ $ID{invisible} }     = 0;
		$bzc{ $ID{neighbor_link} } = 0;
		$bzc{ $ID{blast_score} }   = -3.5;
		$bzc{ $ID{violet} }        = 3.5;
		$bzc{ $ID{ortho} }         = 0.0;
############
		#$bzc{$ID{mmu}} = -1.5;
		#$bzc{$ID{rno}} = -1.5;
		#$color{$ID{mmu}} = '255,0,128';
		#$color{$ID{rno}} = '255,0,128';
##############
		#	$shape{'0'} = 0;
		#	$shape{'0'} = 2;
		#	$shape{'0'} = 3;
####1: square, 2: triangle, 3: diamond##########
		my $dmnd = 3;
		my $crcl = 0;
		my $trng = 2;
		my $squa = 1;
		$node_color{'query'}   = '255,255,0';
		$node_color{'context'} = '255,128,255';

		#$node_color{'query'} = '100,100,100';
		$shape{'query'}   = $dmnd;
		$shape{'context'} = $dmnd;
		$i                = 1;

		#$node_color{$i} = '120,120,120'; $shape{$i++} = $crcl;
		$node_color{'0'} = $node_color{'other'} = '120,120,120';
		$shape{'0'}      = $shape{'other'}      = $crcl;

		#$node_color{$i} = '127,127,127'; $shape{$i++} = $trng;
		my ( $sh, $Nshapes, %Ncolors, $cr, $cg, $cb, @PWlist, %PWhash );
		%PWhash = (
			"KEGG00010",
			"Glycolysis / Gluconeogenesis",
			"KEGG00020",
			"Citrate cycle (TCA cycle)",
			"KEGG00030",
			"Pentose phosphate pathway",
			"KEGG00031",
			"Inositol metabolism",
			"KEGG00040",
			"Pentose and glucuronate interconversions",
			"KEGG00051",
			"Fructose and mannose metabolism",
			"KEGG00052",
			"Galactose metabolism",
			"KEGG00053",
			"Ascorbate and aldarate metabolism",
			"KEGG00061",
			"Fatty acid biosynthesis",
			"KEGG00062",
			"Fatty acid elongation in mitochondria",
			"KEGG00071",
			"Fatty acid metabolism",
			"KEGG00072",
			"Synthesis and degradation of ketone bodies",
			"KEGG00100",
			"Biosynthesis of steroids",
			"KEGG00120",
			"Bile acid biosynthesis",
			"KEGG00130",
			"Ubiquinone biosynthesis",
			"KEGG00140",
			"C21-Steroid hormone metabolism",
			"KEGG00150",
			"Androgen and estrogen metabolism",
			"KEGG00190",
			"Oxidative phosphorylation",
			"KEGG00193",
			"ATP synthesis",
			"KEGG00195",
			"Photosynthesis",
			"KEGG00196",
			"Photosynthesis - antenna proteins",
			"KEGG00220",
			"Urea cycle and metabolism of amino groups",
			"KEGG00230",
			"Purine metabolism",
			"KEGG00232",
			"Caffeine metabolism",
			"KEGG00240",
			"Pyrimidine metabolism",
			"KEGG00251",
			"Glutamate metabolism",
			"KEGG00252",
			"Alanine and aspartate metabolism",
			"KEGG00253",
			"Tetracycline biosynthesis",
			"KEGG00260",
			"Glycine, serine and threonine metabolism",
			"KEGG00271",
			"Methionine metabolism",
			"KEGG00272",
			"Cysteine metabolism",
			"KEGG00280",
			"Valine, leucine and isoleucine degradation",
			"KEGG00281",
			"Geraniol degradation",
			"KEGG00290",
			"Valine, leucine and isoleucine biosynthesis",
			"KEGG00300",
			"Lysine biosynthesis",
			"KEGG00310",
			"Lysine degradation",
			"KEGG00330",
			"Arginine and proline metabolism",
			"KEGG00340",
			"Histidine metabolism",
			"KEGG00350",
			"Tyrosine metabolism",
			"KEGG00351",
			"1,1,1-Trichloro-2,2-bis(4-chlorophenyl)ethane (DDT) degradation",
			"KEGG00360",
			"Phenylalanine metabolism",
			"KEGG00361",
			"gamma-Hexachlorocyclohexane degradation",
			"KEGG00362",
			"Benzoate degradation via hydroxylation",
			"KEGG00363",
			"Bisphenol A degradation",
			"KEGG00380",
			"Tryptophan metabolism",
			"KEGG00400",
			"Phenylalanine, tyrosine and tryptophan biosynthesis",
			"KEGG00401",
			"Novobiocin biosynthesis",
			"KEGG00410",
			"beta-Alanine metabolism",
			"KEGG00430",
			"Taurine and hypotaurine metabolism",
			"KEGG00440",
			"Aminophosphonate metabolism",
			"KEGG00450",
			"Selenoamino acid metabolism",
			"KEGG00460",
			"Cyanoamino acid metabolism",
			"KEGG00471",
			"D-Glutamine and D-glutamate metabolism",
			"KEGG00472",
			"D-Arginine and D-ornithine metabolism",
			"KEGG00480",
			"Glutathione metabolism",
			"KEGG00500",
			"Starch and sucrose metabolism",
			"KEGG00510",
			"N-Glycan biosynthesis",
			"KEGG00511",
			"N-Glycan degradation",
			"KEGG00512",
			"O-Glycan biosynthesis",
			"KEGG00513",
			"High-mannose type N-glycan biosynthesis",
			"KEGG00520",
			"Nucleotide sugars metabolism",
			"KEGG00521",
			"Streptomycin biosynthesis",
			"KEGG00523",
			"Polyketide sugar unit biosynthesis",
			"KEGG00530",
			"Aminosugars metabolism",
			"KEGG00531",
			"Glycosaminoglycan degradation",
			"KEGG00532",
			"Chondroitin sulfate biosynthesis",
			"KEGG00533",
			"Keratan sulfate biosynthesis",
			"KEGG00534",
			"Heparan sulfate biosynthesis",
			"KEGG00540",
			"Lipopolysaccharide biosynthesis",
			"KEGG00550",
			"Peptidoglycan biosynthesis",
			"KEGG00561",
			"Glycerolipid metabolism",
			"KEGG00562",
			"Inositol phosphate metabolism",
			"KEGG00563",
			"Glycosylphosphatidylinositol(GPI)-anchor biosynthesis",
			"KEGG00564",
			"Glycerophospholipid metabolism",
			"KEGG00565",
			"Ether lipid metabolism",
			"KEGG00590",
			"Arachidonic acid metabolism",
			"KEGG00591",
			"Linoleic acid metabolism",
			"KEGG00592",
			"alpha-Linolenic acid metabolism",
			"KEGG00600",
			"Glycosphingolipid metabolism",
			"KEGG00601",
			"Glycosphingolipid biosynthesis - lactoseries",
			"KEGG00602",
			"Glycosphingolipid biosynthesis - neo-lactoseries",
			"KEGG00603",
			"Glycosphingolipid biosynthesis - globoseries",
			"KEGG00604",
			"Glycosphingolipid biosynthesis - ganglioseries",
			"KEGG00620",
			"Pyruvate metabolism",
			"KEGG00623",
			"2,4-Dichlorobenzoate degradation",
			"KEGG00624",
			"1- and 2-Methylnaphthalene degradation",
			"KEGG00625",
			"Tetrachloroethene degradation",
			"KEGG00626",
			"Nitrobenzene degradation",
			"KEGG00627",
			"1,4-Dichlorobenzene degradation",
			"KEGG00628",
			"Fluorene degradation",
			"KEGG00629",
			"Carbazole degradation",
			"KEGG00630",
			"Glyoxylate and dicarboxylate metabolism",
			"KEGG00631",
			"1,2-Dichloroethane degradation",
			"KEGG00632",
			"Benzoate degradation via CoA ligation",
			"KEGG00633",
			"Trinitrotoluene degradation",
			"KEGG00640",
			"Propanoate metabolism",
			"KEGG00641",
			"3-Chloroacrylic acid degradation",
			"KEGG00642",
			"Ethylbenzene degradation",
			"KEGG00643",
			"Styrene degradation",
			"KEGG00650",
			"Butanoate metabolism",
			"KEGG00660",
			"C5-Branched dibasic acid metabolism",
			"KEGG00670",
			"One carbon pool by folate",
			"KEGG00680",
			"Methane metabolism",
			"KEGG00710",
			"Carbon fixation",
			"KEGG00720",
			"Reductive carboxylate cycle (CO2 fixation)",
			"KEGG00730",
			"Thiamine metabolism",
			"KEGG00740",
			"Riboflavin metabolism",
			"KEGG00750",
			"Vitamin B6 metabolism",
			"KEGG00760",
			"Nicotinate and nicotinamide metabolism",
			"KEGG00770",
			"Pantothenate and CoA biosynthesis",
			"KEGG00780",
			"Biotin metabolism",
			"KEGG00785",
			"Lipoic acid metabolism",
			"KEGG00790",
			"Folate biosynthesis",
			"KEGG00791",
			"Atrazine degradation",
			"KEGG00830",
			"Retinol metabolism",
			"KEGG00860",
			"Porphyrin and chlorophyll metabolism",
			"KEGG00900",
			"Terpenoid biosynthesis",
			"KEGG00901",
			"Indole and ipecac alkaloid biosynthesis",
			"KEGG00902",
			"Monoterpenoid biosynthesis",
			"KEGG00903",
			"Limonene and pinene degradation",
			"KEGG00904",
			"Diterpenoid biosynthesis",
			"KEGG00905",
			"Brassinosteroid biosynthesis",
			"KEGG00910",
			"Nitrogen metabolism",
			"KEGG00920",
			"Sulfur metabolism",
			"KEGG00930",
			"Caprolactam degradation",
			"KEGG00940",
			"Stilbene, coumarine and lignin biosynthesis",
			"KEGG00941",
			"Flavonoid biosynthesis",
			"KEGG00944",
			"Flavone and flavonol biosynthesis",
			"KEGG00950",
			"Alkaloid biosynthesis I",
			"KEGG00960",
			"Alkaloid biosynthesis II",
			"KEGG00970",
			"Aminoacyl-tRNA biosynthesis",
			"KEGG00980",
			"Metabolism of xenobiotics by cytochrome P450",
			"KEGG01030",
			"Glycan structures - biosynthesis 1",
			"KEGG01031",
			"Glycan structures - biosynthesis 2",
			"KEGG01032",
			"Glycan structures - degradation",
			"KEGG01040",
			"Biosynthesis of unsaturated fatty acids",
			"KEGG01051",
			"Biosynthesis of ansamycins",
			"KEGG01055",
			"Biosynthesis of vancomycin group antibiotics",
			"KEGG02010",
			"ABC transporters - General",
			"KEGG02020",
			"Two-component system - General",
			"KEGG03010",
			"Ribosome",
			"KEGG03020",
			"RNA polymerase",
			"KEGG03022",
			"Basal transcription factors",
			"KEGG03030",
			"DNA polymerase",
			"KEGG03050",
			"Proteasome",
			"KEGG03060",
			"Protein export",
			"KEGG03090",
			"Type II secretion system",
			"KEGG03320",
			"PPAR signaling pathway",
			"KEGG04010",
			"MAPK signaling pathway",
			"KEGG04012",
			"ErbB signaling pathway",
			"KEGG04020",
			"Calcium signaling pathway",
			"KEGG04060",
			"Cytokine-cytokine receptor interaction",
			"KEGG04070",
			"Phosphatidylinositol signaling system",
			"KEGG04080",
			"Neuroactive ligand-receptor interaction",
			"KEGG04110",
			"Cell cycle",
			"KEGG04111",
			"Cell cycle - yeast",
			"KEGG04115",
			"p53 signaling pathway",
			"KEGG04120",
			"Ubiquitin mediated proteolysis",
			"KEGG04130",
			"SNARE interactions in vesicular transport",
			"KEGG04140",
			"Regulation of autophagy",
			"KEGG04150",
			"mTOR signaling pathway",
			"KEGG04210",
			"Apoptosis",
			"KEGG04310",
			"Wnt signaling pathway",
			"KEGG04320",
			"Dorso-ventral axis formation",
			"KEGG04330",
			"Notch signaling pathway",
			"KEGG04340",
			"Hedgehog signaling pathway",
			"KEGG04350",
			"TGF-beta signaling pathway",
			"KEGG04360",
			"Axon guidance",
			"KEGG04370",
			"VEGF signaling pathway",
			"KEGG04510",
			"Focal adhesion",
			"KEGG04512",
			"ECM-receptor interaction",
			"KEGG04514",
			"Cell adhesion molecules (CAMs)",
			"KEGG04520",
			"Adherens junction",
			"KEGG04530",
			"Tight junction",
			"KEGG04540",
			"Gap junction",
			"KEGG04610",
			"Complement and coagulation cascades",
			"KEGG04612",
			"Antigen processing and presentation",
			"KEGG04614",
			"Renin-angiotensin system",
			"KEGG04620",
			"Toll-like receptor signaling pathway",
			"KEGG04630",
			"Jak-STAT signaling pathway",
			"KEGG04640",
			"Hematopoietic cell lineage",
			"KEGG04650",
			"Natural killer cell mediated cytotoxicity",
			"KEGG04660",
			"T cell receptor signaling pathway",
			"KEGG04662",
			"B cell receptor signaling pathway",
			"KEGG04664",
			"Fc epsilon RI signaling pathway",
			"KEGG04670",
			"Leukocyte transendothelial migration",
			"KEGG04710",
			"Circadian rhythm",
			"KEGG04720",
			"Long-term potentiation",
			"KEGG04730",
			"Long-term depression",
			"KEGG04740",
			"Olfactory transduction",
			"KEGG04742",
			"Taste transduction",
			"KEGG04810",
			"Regulation of actin cytoskeleton",
			"KEGG04910",
			"Insulin signaling pathway",
			"KEGG04912",
			"GnRH signaling pathway",
			"KEGG04914",
			"Progesterone-mediated oocyte maturation",
			"KEGG04916",
			"Melanogenesis",
			"KEGG04920",
			"Adipocytokine signaling pathway",
			"KEGG04930",
			"Type II diabetes mellitus",
			"KEGG04940",
			"Type I diabetes mellitus",
			"KEGG04950",
			"Maturity onset diabetes of the young",
			"KEGG05010",
			"Alzheimer's disease",
			"KEGG05020",
			"Parkinson's disease",
			"KEGG05030",
			"Amyotrophic lateral sclerosis (ALS)",
			"KEGG05040",
			"Huntington's disease",
			"KEGG05050",
			"Dentatorubropallidoluysian atrophy (DRPLA)",
			"KEGG05060",
			"Prion disease",
			"KEGG05120",
			"Epithelial cell signaling in Helicobacter pylori infection",
			"KEGG05210",
			"Colorectal cancer",
			"KEGG05211",
			"Renal cell carcinoma",
			"KEGG05212",
			"Pancreatic cancer",
			"KEGG05213",
			"Endometrial cancer",
			"KEGG05214",
			"Glioma",
			"KEGG05215",
			"Prostate cancer",
			"KEGG05216",
			"Thyroid cancer",
			"KEGG05217",
			"Basal cell carcinoma",
			"KEGG05218",
			"Melanoma",
			"KEGG05219",
			"Bladder cancer",
			"KEGG05220",
			"Chronic myeloid leukemia",
			"KEGG05221",
			"Acute myeloid leukemia",
			"KEGG05222",
			"Small cell lung cancer",
			"KEGG05223",
			"Non-small cell lung cancer",
			"KEGG05310",
			"Asthma"
		);

		@PWlist = ( sort { $a cmp $b } keys(%PWhash) );

		#$Nshapes = 9;
		$node_color{mirna} = '0,120,120';
		$shape{mirna}      = 9;
		$node_color{tf}    = '120,120,0';
		$shape{tf}         = 7;
		$node_color{lmx}   = $color{ $ID{lmx} };
		$shape{lmx}        = $shape{zfish} = 1;
		$node_color{lmx2}  = $color{ $ID{lmx2} };
		$shape{lmx2}       = $shape{zfish2} = 1;

		$Ncolors{red} = $Ncolors{green} = $Ncolors{blue} = 3;
		for $cr ( 0 .. $Ncolors{red} ) {
			for $cg ( 0 .. $Ncolors{green} ) {
				for $cb ( 0 .. $Ncolors{blue} ) {
					next if ( $lmx and !$cb );

					#next if ($cr == 3 and $cg == 3 and $cb == 0);
					for $sh ( 0, 1, 2, 4, 5, 6, 8 ) {
						next if ( $lmx and $sh == 1 );
						$i = shift(@PWlist);
						goto LINE16 if !$i;
						$node_color{$i} = int( $cr * 255 / 3 );
						$node_color{$i} .= ',' . int( $cg * 255 / 3 );
						$node_color{$i} .= ',' . int( $cb * 255 / 3 );
						$shape{$i} = $sh;
					}
				}
			}
		}

	  LINE16: $img{'query'} = $graf_path . 'shape_dmnd_yellow_small.GIF';
		$img{'context'} = $graf_path . 'shape_dmnd_purple_small.GIF';
		$img{'a KEGG pathway member'} =
		  $graf_path . 'shape_trng_grey_small.GIF';
		$img{'other'} = $graf_path . 'shape_crcl_grey_small.GIF';

		#$img{''} = 'https://www.sbc.su.se/~andale/pic/line_patt1.jpg';
		for $cc ( keys(%color) ) {
			@cl = split( ',', $color{$cc} );
			$hexcolor{$cc} = '"#'
			  . sprintf( "%02x", $cl[0] )
			  . sprintf( "%02x", $cl[1] )
			  . sprintf( "%02x", $cl[2] ) . '"';
		}
		$GOlocation{'GO:0005634'}  = 'Nucleus';
		$GOlocation{'GO:0005739'}  = 'Mitochondrion';
		$GOlocation{'GO:0005783'}  = 'ER';
		$GOlocation{'GO:0005794'}  = 'Golgi';
		$GOlocation{'GO:0005737'}  = 'Cytoplasm';
		$GOlocation{'GO:0016020'}  = 'Membrane';
		$GOlocation{'GO:0005576'}  = 'Extracell';
		$GOlocation{'GO:0005615'}  = 'Extracellular';
		$dataImage->{'double_net'} = 'double.GIF';
		$dataImage->{'single_net'} = 'single.GIF';
		$dataImage->{'ensembl'}    = 'e-bang.GIF';
		$dataImage->{'inparanoid'} = 'inp.GIF';
		$dataImage->{'hpa'}        = 'hpa.GIF';
		$dataImage->{'pubmed'}     = 'pmed.GIF';
		$dataImage->{'kegg'}       = 'kegg28.GIF';
		$dataImage->{'ihop'}       = 'ihop.png';

		$cladeImage->{ver}->{img} = 'rat';
		$cladeImage->{hsa}->{img} = 'human';
		$cladeImage->{gga}->{img} = 'chicken';
		$cladeImage->{mmu}->{img} = 'mouse';
		$cladeImage->{rno}->{img} = 'rat';

		$cladeImage->{fun}->{img} = 'yeast';
		$cladeImage->{cal}->{img} = 'candida';
		$cladeImage->{spo}->{img} = 'pombe';

		$cladeImage->{cbr}->{img} = 'briggsae';
		$cladeImage->{nem}->{img} = 'worm';

		$cladeImage->{ins}->{img} = 'fly';
		$cladeImage->{aga}->{img} = 'mosquito';

		$cladeImage->{pla}->{img} = 'thaliana';

		$cladeImage->{ver}->{lbl} = 'mammals';
		$cladeImage->{hsa}->{lbl} = 'human';
		$cladeImage->{gga}->{lbl} = 'chicken';
		$cladeImage->{mmu}->{lbl} = 'M. musculus';
		$cladeImage->{rno}->{lbl} = 'R. norvegicus';

		$cladeImage->{fun}->{lbl} = 'fungi';
		$cladeImage->{cal}->{lbl} = 'C. albicans';
		$cladeImage->{spo}->{lbl} = 'S. pombe';

		$cladeImage->{cbr}->{lbl} = 'C. briggsae';
		$cladeImage->{nem}->{lbl} = 'round worms';

		$cladeImage->{ins}->{lbl} = 'insects';
		$cladeImage->{aga}->{lbl} = 'A .gambiae';

		$cladeImage->{pla}->{lbl} = 'plants';

		$cladeImage->{ver}->{num} = '1';
		$cladeImage->{gga}->{num} = '-1';
		$cladeImage->{hsa}->{num} = '0';
		$cladeImage->{mmu}->{num} = '2';
		$cladeImage->{rno}->{num} = '3';

		$cladeImage->{fun}->{num} = '9';
		$cladeImage->{cal}->{num} = '10';
		$cladeImage->{spo}->{num} = '11';

		$cladeImage->{cbr}->{num} = '7';
		$cladeImage->{nem}->{num} = '6';

		$cladeImage->{ins}->{num} = '4';
		$cladeImage->{aga}->{num} = '5';

		$cladeImage->{pla}->{num} = '8';

		#cladeCaption

		$kingdom{'hsa'} = 'ani';
		$kingdom{'gga'} = 'ani';
		$kingdom{'mmu'} = 'ani';
		$kingdom{'rno'} = 'ani';
		$kingdom{'cin'} = 'ani';
		$kingdom{'dre'} = 'ani';
		$kingdom{'dme'} = 'ani';
		$kingdom{'ame'} = 'ani';
		$kingdom{'aga'} = 'ani';
		$kingdom{'cel'} = 'ani';
		$kingdom{'cbr'} = 'ani';
		$kingdom{'sce'} = 'fun';
		$kingdom{'spo'} = 'fun';
		$kingdom{'cal'} = 'fun';
		$kingdom{'osa'} = 'pla';
		$kingdom{'ath'} = 'pla';

		#$kingdom{''} = '';
		$class{'hsa'} = 'mam';
		$class{'mmu'} = 'mam';
		$class{'rno'} = 'mam';
		$class{'gga'} = 'ver';
		$class{'cin'} = 'ver';
		$class{'dre'} = 'pis';
		$class{'fru'} = 'pis';
		$class{'tni'} = 'pis';
		$class{'dme'} = 'ins';
		$class{'ame'} = 'ins';
		$class{'aga'} = 'ins';
		$class{'cel'} = 'nem';
		$class{'cbr'} = 'nem';
		$class{'sce'} = 'fun';
		$class{'cal'} = '';
		$class{'spo'} = '';
		$class{'osa'} = 'mct';
		$class{'ath'} = 'dct';

		@{ $clade_memb{'ani'} } =
		  ( 'hsa', 'mmu', 'rno', 'dre', 'gga', 'dme', 'cel' );
		@{ $clade_memb{'ver'} } = ( 'hsa', 'mmu', 'rno', 'dre', 'gga' );
		@{ $clade_memb{'mam'} } = ( 'hsa', 'mmu', 'rno' );
		@{ $clade_memb{'ins'} } = ('dme');
		@{ $clade_memb{'nem'} } = ('cel');
		@{ $clade_memb{'fun'} } = ('sce');
		@{ $clade_memb{'pla'} } = ('ath');

		#@{$clade_memb{''}} = ('', '', '', '');

		$label{'confidence'} = 'Probabilistic confidence score of the link \= ';
		$label{'fbs'}   = 'Summary score (a.k.a. final Bayesian score, FBS)';
		$label{'fbs'}   = 'Probabilistic confidence score';
		$label{'coloc'} = 'Sub-cellular co-localization';
		$label{'phylo'} =
		  'Similarity of phylogenetic profiles across eukaryotes';
		$label{'ppi'}     = 'Protein-protein interactions';
		$label{'pearson'} = 'Co-expression';
		$label{'mirna'}   = $tag{'mirna'};
		$label{'tf'}      = $tag{'tf'};
		$label{'hpa'}     = $tag{'hpa'};
		$label{'domain'}  = $tag{'domain'};

		#
		$label{'mirna_ol'}    = $tag{'mirna_ol'};
		$label{'mirna_tg'}    = $tag{'mirna_tg'};
		$label{'tf_2gene'}    = $tag{'tf_2gene'};
		$label{'gene_nei'}    = $tag{'gene_nei'};
		$label{'dataset'}     = $tag{'dataset'};
		$label{'lmx'}         = $tag{'lmx'};
		$label{'lmx2'}        = $tag{'lmx2'};
		$label{'prot1'}       = $tag{'prot1'};
		$label{'prot2'}       = $tag{'prot2'};
		$label{'blast_score'} = 'Sequence similarity, bits';

		$i                               = -1;
		$FBSscale[ ++$i ]->{upper_value} = -2.5;
		$FBSscale[$i]->{label}           = 'Strong negative';
		$FBSscale[ ++$i ]->{upper_value} = -0.5;
		$FBSscale[$i]->{label}           = 'Weak negative';
		$FBSscale[ ++$i ]->{upper_value} = 0.75;
		$FBSscale[$i]->{label}           = 'Insignificant';
		$FBSscale[ ++$i ]->{upper_value} = 1.5;
		$FBSscale[$i]->{label}           = 'Weak positive';
		$FBSscale[ ++$i ]->{upper_value} = 3.0;
		$FBSscale[$i]->{label}           = 'Moderate positive';
		$FBSscale[ ++$i ]->{upper_value} = 1000;
		$FBSscale[$i]->{label}           = 'Strong positive';

		undef $i;
		$maxPartialFBS{pos}      = 7;
		$maxPartialFBS{neg}      = -4;
		$maxLmxContrast{pos}     = 10;
		$maxLmxContrast{neg}     = -10;
		$DBtag->{ENSEMBL}->{hsa} = 'Homo_sapiens';
		$DBtag->{ENSEMBL}->{cel} = 'Caenorhabditis_elegans';
		$DBtag->{ENSEMBL}->{gga} = 'Gallus_gallus';
		$DBtag->{ENSEMBL}->{dre} = 'Danio_rerio';
		$DBtag->{ENSEMBL}->{mmu} = 'Mus_musculus';
		$DBtag->{ENSEMBL}->{cin} = 'Ciona_intestinalis';
		$DBtag->{ENSEMBL}->{rno} = 'Rattus_norvegicus';
		$DBtag->{ENSEMBL}->{dme} = 'Drosophila_melanogaster';
		$DBtag->{ENSEMBL}->{sce} = 'Saccharomyces_cerevisiae';
##########################################################

		for $oo ( keys(%org) ) {
			$weblink->{ENSEMBL}->{$oo}->{start} =
			    'http://www.ensembl.org/'
			  . $DBtag->{ENSEMBL}->{$oo}
			  . '/geneview?gene='
			  if defined( $DBtag->{ENSEMBL}->{$oo} );
			$weblink->{ENSEMBL}->{$oo}->{end}   = '';
			$weblink->{ENSEMBL}->{$oo}->{start} =
			  'http://www.ensembl.org/Homo_sapiens/searchview?species=;idx=;q='
			  if !defined( $weblink->{ENSEMBL}->{$oo}->{start} );

			$weblink->{iHOP}->{$oo}->{start} =
			  'http://www.ihop-net.org/UniPub/iHOP/in?dbrefs_1=UNIPROT__AC|';
			$weblink->{iHOP}->{$oo}->{end} = '';

			$weblink->{UniProt}->{$oo}->{start} =
			  'http://beta.uniprot.org/uniprot/';
			$weblink->{InParanoid}->{$oo}->{start} =
'http://inparanoid.sbc.su.se/cgi-bin/gene_search.cgi?idtype=geneid&amp;all_or_selection=all&amp;specieslist=1&amp;scorelimit=0.05&amp;.submit=Submit+Query&amp;.cgifields=specieslist&amp;.cgifields=idtype&amp;.cgifields=all_or_selection&amp;id=';
			$weblink->{InParanoid}->{$oo}->{end} = '';
		}
		for $oo ( 'mmu', 'rno' ) {
			$weblink->{MGI}->{$oo}->{start} =
			  'http://www.informatics.jax.org/searches/accession_report.cgi?id='
			  ;    #MGI%3A99783
		}
		$weblink->{'Antibody staining by Human Protein Atlas'}->{'hsa'}
		  ->{start} =
		  'http://www.proteinatlas.org/tissue_profile.php?ensembl_gene_id=';
		$weblink->{'Antibody staining by Human Protein Atlas'}->{'hsa'}->{end} =
		  '';

		$weblink->{ENSEMBL}->{'all_species'} =
		  'http://www.ensembl.org/Homo_sapiens/searchview?species=;idx=;q=';
		$weblink->{InParanoid}->{'all_species'} =
'http://inparanoid.sbc.su.se/cgi-bin/gene_search.cgi?idtype=geneid&amp;all_or_selection=all&amp;specieslist=1&amp;scorelimit=0.05&amp;.submit=Submit+Query&amp;.cgifields=specieslist&amp;.cgifields=idtype&amp;.cgifields=all_or_selection&amp;id=';
		$weblink->{ENSEMBL}->{'ID_to_ask'}    = 'fcname';
		$weblink->{InParanoid}->{'ID_to_ask'} = 'fcname';

		for $oo ( keys(%org) ) {
			$oltag{$oo} = olTagged(
				$oo, $org{$oo}, 'b', 'i',
				$hexcolor{ $ID{white} },
				$hexcolor{ $ID{$oo} }
			);

			#$oltag{$oo} = $oo;
		}

		#'gene_nei', 'mirna_ol', 'mirna_tg', 'tf_2gene'
		for $oo (
			'fbs',   'coloc', 'pearson', 'phylo',
			'mirna', 'tf',    'hpa',     'domain',
			'prot1', 'prot2', 'ppi',     'blast_score'
		  )
		{
			$oltag{$oo} = olTagged(
				$funcoupweb::lbl{$oo}, $label{$oo}, 'b', '',
				$hexcolor{ $ID{white} },
				$hexcolor{ $ID{$oo} }
			);

			#$oltag{$oo} = $funcoupweb::lbl{$oo};
		}
		$border           = 0;
		$inparanoid_table = 'inparanoid_map_12eukaryotes';
		$i                = 0;
		%evidenceOrder    = (
			'prot1'       => $i++,
			'prot2'       => $i++,
			'fbs'         => $i++,
			'ppi'         => $i++,
			'pearson'     => $i++,
			'coloc'       => $i++,
			'phylo'       => $i++,
			'mirna'       => $i++,
			'tf'          => $i++,
			'hpa'         => $i++,
			'domain'      => $i++,
			'hsa'         => $i++,
			'mmu'         => $i++,
			'rno'         => $i++,
			'dme'         => $i++,
			'cel'         => $i++,
			'sce'         => $i++,
			'ath'         => $i++,
			'blast_score' => $i++
		);
		@evOrder =
		  sort { $evidenceOrder{$a} <=> $evidenceOrder{$b} }
		  keys(%evidenceOrder);

		#'dre' => $i++,
		$i = 0;

#$olDeclaration = '<script type="text/javascript" src="http://www.bosrup.com/web/overlib/overlib.js"><!-- overLIB (c) Erik Bosrup --><script language="JavaScript"></script>';
		$olDeclaration =
		    '<script type="text/javascript" src="'
		  . $jslocation
		  . 'overlib.js"><!-- overLIB (c) Erik Bosrup --><script language="JavaScript"></script>';
		$overDivDeclaration =
'<div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>';
		$scriptDeclaration = "\n"
		  . '<script type="text/javascript" src="'
		  . $jslocation
		  . 'fcout.js"><!-- fcout (c) Andrey Alexeyenko 2007 --></script>';

		$fc_url{20} =
'Run=Run;evidPrintCoff=1.00;order=1;no_of_links=20;reduce_by=noislets;coff=0.10;show_names=Names;output=webgraph;wheight=640;wwidth=800;qvotering=quota;';
		$kegg_url =
'http://www.genome.jp/dbget-bin/get_pathway?org_name=SSS&amp;mapno=MMMMM';
		$kegg_id_url = 'http://www.genome.jp/dbget-bin/www_bget?ko+';
		return;
	}

