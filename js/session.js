function prepare_session(uname, pass)
{
	var login_status;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/p.cgi?username="+encodeURIComponent(uname)+"&password="+encodeURIComponent(pass), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			login_status = this.responseText;}
		}
	xmlhttp.send();
	return login_status;
}
function open_session(uname, signature, sid, session_length)
{
	var session_status;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/open_session.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid)+"&session_length="+encodeURIComponent(session_length), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			session_status = this.responseText;}
			}
	xmlhttp.send();
	return session_status;
}

function verify_prolong_session(uname, oldsignature, sid, newsignature, session_length)
{
	var session_status;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/verify_session.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+ "&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(session_length), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			session_status = this.responseText;}
			}
	xmlhttp.send();
	return session_status;
}

function close_session(uname, signature, sid)
{
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/close_session.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid), true);
	xmlhttp.send();
}

// function returns number of parameters from cookies
// action=true means that some action has been performed -> we potentionally need to prolong session (set some new cookies)
// action=false returns only current values 
function get_name_sid_sign_length(action)
{
	var response;
	var loggedin = getCookie("username");
	var username = (loggedin.split("|"))[0];
	var sid = ((getCookie("session_id")).split("|"))[0];
	var sessionlength = (loggedin.split("|"))[3];
	var signature = getSignature();
	if (action == true) {
		setCookie("username", username, sessionlength);
		// no need to use getSignature() because we have just set this cookie
		var newsignature = ((getCookie("username")).split("|"))[1];
		response = [username, sid, signature, sessionlength, newsignature];}
	else {
		response = [username, sid, signature, sessionlength];}
	return response;
}

// returns number of notifications
// if number of notifications > 0 - open settings
function notifications_queue(uname, signature, sid)
{
	var notifications;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/notifications_queue.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			notifications = this.responseText;}
			}
	xmlhttp.send();
	return notifications;
}