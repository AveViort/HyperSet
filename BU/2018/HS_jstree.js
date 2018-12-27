// tree data
var data;
data = [{
  text: "Pathways",
  data: {},
  children: [{
    text: "GO_Process",
    data: {},
    children:[
      {text: "GO_BP1", data: {genes: 1, groups: 20}},
      {text: "GO_CC", data: {genes: 2, groups: 31}},
      {text: "GO_MF", data: {genes: 99, groups: 34}},
      ],
    'state': {'opened': true}
  }, {
    text: "KEGG",
    data: {},
    children:[
      {text: "KEGG_signalling", data: {genes: '.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{KEGG_signalling}}->{ngenes}.' , groups: 8 }},
      {text: "KEGG_disease", data: {genes: '.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{KEGG_disease}}->{ngenes}.', groups: 22}},
      {text: "KEGG_basic", data: {genes: '.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{KEGG_basic}}->{ngenes}.', groups: 32}},
      {text: "KEGG_all", data: {genes: '.$HSconfig::fgsDescription->{$sp}->{$HSconfig::fgsAlias -> {$sp}->{KEGG_all}}->{ngenes}.', groups: 18}}]
  }],
  'state': {'opened': true}
}];

// load jstree
$("div#fgs-jstree").jstree({
  plugins: ["checkbox","table","dnd"],
  core: {
    data: data
  },

//configure tree table

table: {
    columns: [
      { header: "Source"},
      { value: "genes", header: "No. of genes", format: function(v) {if (v){ return v }}},
      { value: "groups", header: "No. of groups"}
    ],
    resizable: true,
    draggable: true,
    contextmenu: true,
    width: 500,
    height: 300
  }
});
