function activate_account(key)
{
	var activation_status;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/activate_account.cgi?activation_key="+encodeURIComponent(key), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			activation_status = this.responseText;}
		}
	xmlhttp.send();
	return activation_status;
}

function forgot_password(uname)
{
	var reset_status;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/send_reset_letter.cgi?username="+encodeURIComponent(uname), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			reset_status = this.responseText;}
		}
	xmlhttp.send();
	return reset_status;
}

function reset_password(uname, newpass, key)
{
	var reset_status;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/reset_password.cgi?username="+encodeURIComponent(uname)+"&password="+encodeURIComponent(newpass)+"&key="+encodeURIComponent(key), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			reset_status = this.responseText;}
		}
	xmlhttp.send();
	if (reset_status == 1) {
		return "success";}
	else {
		return "failure";}
}

function change_password(uname, oldpass, newpass, oldsignature, sid, newsignature, sessionlength)
{
	var change_status;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/change_password.cgi?username="+encodeURIComponent(uname)+"&old_password="+encodeURIComponent(oldpass)+"&new_password="+encodeURIComponent(newpass)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			change_status = this.responseText;}
		}
	xmlhttp.send();
	return change_status;
}

function notifications_status(uname, signature, sid)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/receive_notifications.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function change_global_notifications_status(uname, oldsignature, sid, newsignature, sessionlength)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/change_global_notifications_status.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}