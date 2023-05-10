// cookie format is:
// "Key=Value|Signature|Timestamp|ValidPeriod; expires=ExpirationDate; path=Path"
// where:
// Key - name of the cookie
// Value - value
// Signature - unique hash-based signature
// Timestamp - generation time as a timestamp
// ValidPeriod - for how many hours cookie is valid
// cookie example:
// "username=Uname|Signature|Timestamp|ExpTime; expires=ExpirationDate; path=Path"

function setCookie(cname, cvalue, cvaltime)
{
	var date = new Date();
	// setting cookie expiration time: ntime hours
	// expiration time in ms
	date.setTime(date.getTime()+(cvaltime*60*60*1000));
	var expires = "expires=" + date.toUTCString();
	var ctimestamp = date.getTime();
	var csign = hash(cname, cvalue, ctimestamp, cvaltime);
	// we use secure cookies, so "secure" flag is set
	document.cookie = cname + "=" + cvalue + "|" + csign + "|" + ctimestamp + "|"+ cvaltime + "; secure;" + expires + "; path=/";
}


function usetCookie(cname, cvalue, cvaltime)
{
	var date = new Date();
	date.setTime(date.getTime()+(cvaltime*60*60*1000));
	var expires = "expires=" + date.toUTCString();
	document.cookie = cname + "=" + cvalue + "|" + cvaltime + "; secure;" + expires + "; path=/";
}

function deleteCookie(cname) {
	document.cookie = cname + "=;expires=Thu, 01 Jan 1970 00:00:01 GMT;";
}

// returns value, signature, timestamp and cvaltime of cookie with the given cname. For unsigned cookies - only value and cvaltime
function getCookie(cname) {
    var name = cname + "=";
    var decodedCookie = decodeURIComponent(document.cookie);
    var ca = decodedCookie.split('; ');
    for(var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) == 0) {
            return c.substring(name.length, c.length);
        }
    }
    return "";
}

function checkCookie(cname) {
	// change this variable! Probably, "body"?
    var id=getCookie(cname);
    if (id != "") {
		// cookie exists
		// because we use signed cookies, we have to split the returned value and take the 0th element
		var cvalue = (id.split("|"))[0];
		var csign = (id.split("|"))[1];
		var ctimestamp = (id.split("|"))[2];
		var cvaltime = (id.split("|"))[3];
		// verify cookie
		var verified = verify_cookie(cname, cvalue, csign, ctimestamp, cvaltime);
		if (verified) {
			return new Array(cvalue, cvaltime);
		} else {
			alert("Cookie " + cname + " was changed. Deleting all cookies.");
			erase_all_cookies();
			return false;
		}
    } else {
		return false;}
}

// function for signature verification
function verify_cookie(cname, cvalue, csign, ctimestamp, cvaltime)
{
	 // if timestamp is >cvaltime hours greater than current time - somebody has changed cookie expiration time
	 var now = new Date();
	 if (now.getTime() + cvaltime*60*60*1000 < ctimestamp) {
		return false;
	} else {
		// timestamp is correct, verify hash
		return (csign) == hash(cname, cvalue, ctimestamp, cvaltime);
	}
}

// delete all cookies - in case of obfuscation
function erase_all_cookies()
{
	document.cookie.split(";").forEach(function(c) { document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=; expires=" + new Date().toUTCString() + "; path=/"); });
	// reload the document to make "allow cookies" dialog enabled
	location.reload();
}

// delete all cookies except for cookies_accepted
function erase_all_but_accept_cookies() {
	document.cookie.split("; ").forEach(function(c) {
		var s = c.substring(0, c.indexOf("="));
		if (s != "cookies_accepted") {
			document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=; expires=" + new Date().toUTCString() + "; path=/");} 
	});
}

// delete all previous cookies - e.g. if user worked as an anonymous user, and later decided to log in. Or in the case of logoff.
function erase_user_cookies()
{
	document.cookie.split("; ").forEach(function(c) {
		// only these cookies have to be deleted
		var deletelist = ["username", "session_id", "project_id"];
		var s = c.substring(0, c.indexOf("="));
		if (deletelist.indexOf(s) != -1) {
			document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=; expires=" + new Date().toUTCString() + "; path=/");} 
	});
}

// generating random id - for unregistered users
// n is the number of symbols
function random_id(n)
{
	var ID = "";
	// alphabet is a set of allowed symbols for generating id
    var Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    for( var i=0; i < n; i++ )
        ID += Alphabet.charAt(Math.floor(Math.random() * Alphabet.length));
    return ID;
}

function hash(cname, cvalue, ctimestamp, cvaltime)
{
	var xmlhttp = new XMLHttpRequest();
	var csign;
	// use synchronous call for we have to wait
	xmlhttp.open("GET", "cgi/csalt.cgi?cname="+encodeURIComponent(cname)+"&cvalue="+encodeURIComponent(cvalue)+"&ctimestamp="+encodeURIComponent(ctimestamp)+"&cvaltime="+encodeURIComponent(cvaltime), false);
	xmlhttp.onreadystatechange = function() {
    if (this.readyState == 4 && this.status == 200) {
      csign = this.responseText;}
	}
	xmlhttp.send();
	return csign;
}

function checkCookiesAccepted()
{
	var cookiesEnabled = getCookie("cookies_accepted");
	if (cookiesEnabled) {
		var cookieWarningMessage = document.getElementById("cookiewarning");
		cookieWarningMessage.style.display = 'none';
		return true}
	return false;
}

// this function hides cookiewarning message and sets a special cookies_accepted cookie
function acceptCookies()
{
	if (navigator.cookieEnabled) {
		var cookieWarningMessage = document.getElementById("cookiewarning");
		cookieWarningMessage.style.display = 'none';
		// this cookie is valid for 1 week
		usetCookie("cookies_accepted", "true", 168);
		usetCookie("username", "Anonymous", 168);}
	else {
		alert("Your browser does not support cookies or cookies are turned off. Please check your settings");}
}

// function for getting a signature - used in session functions
function getSignature()
{
	// we're sure that the cookie is set
	var cookie=getCookie("username");
	var cvalue = (cookie.split("|"))[0];
	var csign = (cookie.split("|"))[1];
	var ctimestamp = (cookie.split("|"))[2];
	var cvaltime = (cookie.split("|"))[3];
	var verified = verify_cookie("username", cvalue, csign, ctimestamp, cvaltime);
	if (verified) {
		return csign;}
	else {
		erase_all_cookies();
		return false;}
}

// this function exists only for lowering number of external connections
function set_sid(sid, sessionlength)
{
	usetCookie("session_id", sid, sessionlength);
}