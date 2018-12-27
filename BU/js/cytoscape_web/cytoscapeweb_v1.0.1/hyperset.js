//\/////
//\  hyperset library 0.01 
//\  Copyright Andrey Alexeyenko 2012. All rights reserved.

$(document).ready(function() {
 
 $("input").click(function(){
 var ccl = $(this).attr("class")
 ccls = ccl.split(" ")
 cl = ccls[0]
 var id = $(this).attr("id")
// alert(cl);
 //  $("#"+id).prop("checked", "true");
   $("td"+"."+cl).toggleClass("active");
  //  $("td").toggleClass("active");
//$(".contrast_choice").toggleClass("active");
  });
});


