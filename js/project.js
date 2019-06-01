function check_permission(uname, sid, oldsignature, newsignature, sessionlength, projectid)
{
	var permission_status;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/check_permission.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength)+"&project_id="+encodeURIComponent(projectid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			permission_status = this.responseText;}
		}
	xmlhttp.send();
	return permission_status;
}

function new_project(uname, projectid, sid, oldsignature, newsignature, sessionlength)
{
	var operation_status;
	var xmlhttp = new XMLHttpRequest();
	if (typeof sid !== "undefined") {
		xmlhttp.open("GET", "cgi/create_project.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength)+"&project_id="+encodeURIComponent(projectid), false);
	}
	else {
		xmlhttp.open("GET", "cgi/create_project.cgi?username="+encodeURIComponent('Anonymous')+"&project_id="+encodeURIComponent(projectid), false);
	}
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			operation_status = this.responseText;}
		}
	xmlhttp.send();
	return operation_status;
}

function project_members(uname, sid, signature, projectid)
{
	var members;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/project_members.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid)+"&project_id="+encodeURIComponent(projectid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			members = this.responseText;}
		}
	xmlhttp.send();
	return members;
}

function add_project_member(uname, oldsignature, sid, newsignature, sessionlength, project_id, newmember, memberlevel)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/add_project_member.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength)+"&project_id="+encodeURIComponent(project_id)+"&new_member="+encodeURIComponent(newmember)+"&member_level="+encodeURIComponent(memberlevel), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}
	
function remove_member(member, projectid, uname, oldsignature, sid, newsignature, sessionlength)
{
	var remove_status;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/delete_member.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature) +"&session_length="+encodeURIComponent(sessionlength) + "&project_id="+encodeURIComponent(projectid)+"&member="+encodeURIComponent(member), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			remove_status = this.responseText;}
		}
	xmlhttp.send();
	return remove_status;
}

function make_public(projectid, uname, oldsignature, sid, newsignature, sessionlength)
{
	var public_status;
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/make_public.cgi?username=" + encodeURIComponent(uname) + "&signature=" + encodeURIComponent(oldsignature) + "&session_id=" + encodeURIComponent(sid) + "&new_signature=" + encodeURIComponent(newsignature) + "&session_length=" + encodeURIComponent(sessionlength) +"&project_id="+encodeURIComponent(projectid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			public_status = this.responseText;}
		}
	xmlhttp.send();
	return public_status;
}

function user_projects(uname, oldsignature, sid, newsignature, sessionlength)
{
	var projects;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/user_projects.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			projects = this.responseText;}
		}
	xmlhttp.send();
	return projects;
}

function user_projects_simple(uname, oldsignature, sid)
{
	var projects;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/user_projects_simple.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			projects = this.responseText;}
		}
	xmlhttp.send();
	return projects;
}

function sent_invitations(uname, signature, sid)
{
	var projects;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/sent_invitations.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			projects = this.responseText;}
		}
	xmlhttp.send();
	return projects;
}

function received_invitations(uname, signature, sid)
{
	var projects;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/received_invitations.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			projects = this.responseText;}
		}
	xmlhttp.send();
	return projects;
}

function change_project_notifications_status(projectid, uname, oldsignature, sid, newsignature, sessionlength)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/change_project_notifications_status.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength) +"&project_id="+encodeURIComponent(projectid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function invite_project_member(uname, oldsignature, sid, newsignature, sessionlength, project_id, newmember, memberlevel)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/invite_project_member.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength)+"&project_id="+encodeURIComponent(project_id)+"&new_member="+encodeURIComponent(newmember)+"&member_level="+encodeURIComponent(memberlevel), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function cancel_invitation(uname, oldsignature, sid, newsignature, sessionlength, project_id, newmember)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/cancel_invitation.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength)+"&project_id="+encodeURIComponent(project_id)+"&member="+encodeURIComponent(newmember), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function accept_invitation(uname, oldsignature, sid, newsignature, sessionlength, project_id)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/accept_invitation.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength)+"&project_id="+encodeURIComponent(project_id), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function reject_invitation(uname, oldsignature, sid, newsignature, sessionlength, project_id)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/reject_invitation.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(oldsignature)+"&session_id="+encodeURIComponent(sid)+"&new_signature="+encodeURIComponent(newsignature)+"&session_length="+encodeURIComponent(sessionlength)+"&project_id="+encodeURIComponent(project_id), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function project_info(uname, signature, sid, project_id)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/project_info.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(signature)+"&session_id="+encodeURIComponent(sid)+"&project_id="+encodeURIComponent(project_id), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function project_anonymous(project_id)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/anonymous_project.cgi?project_id="+encodeURIComponent(project_id), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function get_full_project_link(hash)
{
	var response;
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/decipher_link.cgi?shared="+encodeURIComponent(hash), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	return response;
}

function generate_share_link(jid)
{
	var response;
	var loggedin = getCookie("username");
	var uname = (loggedin.split("|"))[0];
	var sid = ((getCookie("session_id")).split("|"))[0];
	var sessionlength = (loggedin.split("|"))[3];
	var oldsignature = getSignature();
	setCookie("username", uname, sessionlength);
	var newsignature = ((getCookie("username")).split("|"))[1];
	var newsid = verify_prolong_session(uname, oldsignature, sid, newsignature, sessionlength);
	usetCookie("session_id", newsid, sessionlength);
	var xmlhttp = new XMLHttpRequest();
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/get_link.cgi?username="+encodeURIComponent(uname)+"&signature="+encodeURIComponent(newsignature)+"&session_id="+encodeURIComponent(newsid)+"&jid="+encodeURIComponent(jid), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			response = this.responseText;}
		}
	xmlhttp.send();
	if (response != "failed") {
		response = "https://www.evinet.org/share.html#" + response;}
	return response;
}

function generate_links_for_all_jobs() {
	var urls = [];
	var jobs;
	var project_id = (getCookie("project_id").split("|"))[0];
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "cgi/get_jobs.cgi?project_id="+encodeURIComponent(project_id), false);
	xmlhttp.onreadystatechange = function() {
			if (this.readyState == 4 && this.status == 200) {
			jobs = this.responseText;}
	}
	xmlhttp.send();
	jobs = jobs.split("|");
	jobs = jobs.slice(0, jobs.length-1);
	for (i in jobs) {
		urls.push(generate_share_link(jobs[i]));
	}
	return urls;
}