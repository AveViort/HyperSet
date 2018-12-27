#!/usr/bin/perl

my $pfl = "vennGenes1455813985.pm";

 if (2 > 1){
 require $pfl;
 import $pfl;
# $pfl -> import;
 }

#if (-e "gene_list.pm" && -e "new_venn_tab.R"){
#    print "yes\n";
#}

my %gn_list = %{$GeneList::gList};

#print $gn_list{'++'}[0]."\n";

for my $cn ( keys %gn_list ){
    print "$cn\n";
    print join("\n", $gn_list{$cn}[0],$gn_list{$cn}[10])."\n";
}






