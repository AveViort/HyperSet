// this file contains misc tools which cannot be assigned to other categories

function report_event(source, level, description, options) {
	var xmlhttp = new XMLHttpRequest();
	var stat;
	xmlhttp.open("GET", "cgi/report_event.cgi?source=" + encodeURIComponent(source) +
		"&level=" + encodeURIComponent(level) + 
		"&description=" + encodeURIComponent(description) + 
		"&options=" + encodeURIComponent(options) + 
		"&user_agent=" + encodeURIComponent(navigator.userAgent), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			stat = this.responseText;}
		}
	xmlhttp.send();
	return stat;
}

// use this function to clear sessionStorage, all cookies (except for cookiesAccepted) and reload the page
function clean_reload() {
	sessionStorage.clear();
	erase_all_but_accept_cookies();
	location.reload();
}