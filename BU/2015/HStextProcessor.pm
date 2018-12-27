package HStextProcessor;

#use DBI;
use CGI qw(:standard);
#use CGI::Carp qw(fatalsToBrowser);
use strict;
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
our $safe_filename_characters = "a-zA-Z0-9_.-";

our(%purgeTitle, %postfix, %filterList);
%postfix = (
'padj' => 'fdr',
'fcdn' => lc('fpkm_Log2FC'),
'fcup' => lc('fpkm_Log2FC'),
'fdr'  => lc('Padj')
);
%filterList = (
'fdr'  => 'lt', 
'fcdn' => 'lt', 
'fcup' => 'gt'
);
$purgeTitle{'vs_'} = 1;

sub title2values {
my($title, $postfix) = @_;

if ($title =~ m/(X[0-9].+)\_(X[0-9].+)\_$postfix/i) {
return($1, $2);
}
else {
return undef;
}}


sub textTable2dataTables_JS {
my($table, $dir, $id, $noHeader) = @_;
my( $tp, $i, $row, @ar);
#print $table.'SHOW'.$dir.'<br>';
open IN, $dir.'/'.$table;
if (!$noHeader) {
my $header = <IN>;
readHeader ($header, $table) ;
}
my $cn .= '<table id='.$id.' class="display" cellspacing="0" width="100%">'."\n";
for $tp(('thead', 'tfoot')) {
$cn .= '<'.$tp.'><tr>'."\n";
for $i(sort {$a <=> $b} keys(%{$main::nm->{$table}})) {
$cn .= '<th>'.$main::nm->{$table}->{$i}.'</th>'."\n";
}
$cn .= '</'.$tp.'></tr>'."\n";
}
$cn .= '<tbody>';
while ($row = <IN>) {
chomp($row);
@ar = split("\t", $row);
$cn .= '<tr>'."\n";
for $i(0..$#ar) {
$cn .= '<td>'.$ar[$i].'</td>';
}
$cn .= '</tr>'."\n";
}
$cn .= '</tbody>
    </table>';
	
	$cn .= '<script   type="text/javascript">$("#'.$id.'").DataTable();</script>';
return $cn;
}

sub id2title {
my($id, $postfix) = @_;
my( $pp);
my $TITLE_DELIMITER = '_';
my $title = join($TITLE_DELIMITER, ($id, $postfix));
for $pp(keys(%purgeTitle)) {
$title =~ s/$pp//;
}
return($title);
}

sub readHeader ($$) {
my($head, $tbl) = @_;
my(@arr, $aa);
#open IN, $tbl or die "$!";
#$head = <IN>;
#close IN;
chomp($head);

@arr = split("\t", $head);
for $aa(0..$#arr) {
$arr[$aa] =~  s/^[0-9]+\://i;
$arr[$aa] =~  s/\./\_/gi;
$arr[$aa] = lc($arr[$aa]);
$main::pl->{$tbl}->{$arr[$aa]} = $aa;
$main::nm->{$tbl}->{$aa} = $arr[$aa];
}
return undef;
}

1;
__END__



