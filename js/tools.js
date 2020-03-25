// this file contains misc tools which cannot be assigned to other categories

function report_event(source, level, description, options, message) {
	var xmlhttp = new XMLHttpRequest();
	var stat;
	xmlhttp.open("GET", "cgi/report_event.cgi?source=" + encodeURIComponent(source) +
		"&level=" + encodeURIComponent(level) + 
		"&description=" + encodeURIComponent(description) + 
		"&options=" + encodeURIComponent(options) + 
		"&message=" + encodeURIComponent(message) + 
		"&user_agent=" + encodeURIComponent(navigator.userAgent), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			stat = this.responseText;}
		}
	xmlhttp.send();
	return stat;
}

function toggle_event_acknowledgement_status(pass, timestamp, level, ack_status) {
	var xmlhttp = new XMLHttpRequest();
	var stat;
	xmlhttp.open("GET", "cgi/toggle_event_acknowledgement.cgi?pass=" + pass + 
		"&timestamp=" + timestamp +
		"&level=" + encodeURIComponent(level) + 
		"&status=" + encodeURIComponent(ack_status), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			stat = this.responseText;}
		}
	xmlhttp.send();
	return stat;
}

function delete_event(pass, timestamp, source, level, description, options, user_agent) {
	var xmlhttp = new XMLHttpRequest();
	var stat;
	xmlhttp.open("GET", "cgi/delete_event.cgi?pass=" + pass + 
		"&timestamp=" + timestamp +
		"&source=" + encodeURIComponent(source) +
		"&level=" + encodeURIComponent(level) + 
		"&description=" + encodeURIComponent(description) + 
		"&options=" + encodeURIComponent(options) + 
		"&user_agent=" + encodeURIComponent(user_agent), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			stat = this.responseText;}
		}
	xmlhttp.send();
	return stat;
}

// not all browsers support Error().stack, they can return undefined
// if so - replace it with message
function check_error_stack(ErrorStack) {
	if (ErrorStack==undefined) {
		return "Browser does not support error stack"
	}
	else {
		return ErrorStack;
	}
}

// use this function to clear sessionStorage, all cookies (except for cookiesAccepted) and reload the page
function clean_reload() {
	sessionStorage.clear();
	erase_all_but_accept_cookies();
	location.reload();
}