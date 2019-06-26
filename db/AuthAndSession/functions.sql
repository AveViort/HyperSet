-- function for hashing passwords
CREATE FUNCTION hash_cycle(pass text, salt text, n integer DEFAULT 100) RETURNS text AS $$
DECLARE
hash text;
BEGIN
-- we are going to store passwords as text, not bytea, so encode is used
-- additionally, hmac function receives text, not bytea
hash := encode(hmac(pass, salt, 'sha256'), 'hex');
FOR i IN 1..n-1 LOOP
hash := encode(hmac(hash, salt, 'sha256'), 'hex');
END LOOP;
RETURN hash;
END;
$$ LANGUAGE plpgsql;
 
-- function for checking if hash of the entered password is equal to hash of the valid password
CREATE OR REPLACE FUNCTION check_hash(uname text, pass text, n integer DEFAULT 100) RETURNS text AS $$
DECLARE
luname text;
hashed_pass text;
-- here and further I use ‘dsalt’ (dynamic salt) because ‘salt’ is a column name
dsalt text;
valid_hash text;
session_id text;
act_status boolean;
BEGIN
-- only lowercase is allowed
SELECT LOWER(uname) INTO luname;
SELECT salt INTO dsalt FROM users WHERE username LIKE luname;
SELECT password INTO valid_hash FROM users WHERE username LIKE luname;
hashed_pass := hash_cycle(pass, dsalt, n);
-- session can be prepared only if hash is valid and account is activated
SELECT activated INTO act_status FROM users WHERE username LIKE luname;
IF ((hashed_pass = valid_hash) AND (act_status)) THEN
SELECT CURRENT_TIME INTO session_id;
session_id := encode(hmac(session_id, dsalt, 'sha256'), 'hex');
dsalt := gen_salt('bf');
FOR i IN 1..25 LOOP
session_id := encode(hmac(session_id, dsalt, 'sha256'), 'hex');
END LOOP;
-- insert incorrect ip as a marker of prepared session
INSERT INTO sessions (username, sid, ip) VALUES (luname, session_id, '550.0.0.0');
RETURN session_id;
ELSE
RETURN 'Fail';
END IF;
END;
$$ LANGUAGE plpgsql;
 
CREATE OR REPLACE FUNCTION open_session(uname text, signature text, session_id text, ipaddr text, session_length integer) RETURNS text AS $$
DECLARE
luname text;
stimestamp timestamp;
BEGIN
SELECT LOWER(uname) INTO luname;
IF EXISTS (SELECT * FROM sessions WHERE ((sid LIKE session_id) AND (username LIKE luname)) AND (ip LIKE '550.0.0.0')) THEN
SELECT LOCALTIMESTAMP INTO stimestamp;
UPDATE sessions SET ip=ipaddr, started=stimestamp, expires=stimestamp + session_length*interval'1 HOUR', sign = signature WHERE ((sid LIKE session_id) AND (username LIKE luname));
RETURN 'Success';
ELSE
RETURN 'Forbidden';
END IF;
END;
$$ LANGUAGE plpgsql;
 
-- function for testing speed
CREATE FUNCTION hash_speed(pass text, n integer DEFAULT 100) RETURNS void AS $$
DECLARE
dsalt text;
BEGIN
FOR i IN 1..n LOOP
-- dynamic salt using Blowfish algorithm
dsalt := gen_salt('bf');
PERFORM hash_cycle(pass, dsalt);
END LOOP;
END;
$$ LANGUAGE plpgsql;
 
CREATE OR REPLACE FUNCTION add_user(uname text, pass text) RETURNS boolean AS $$
DECLARE
dsalt text;
hash text;
BEGIN
IF EXISTS (SELECT * FROM users WHERE username LIKE uname)THEN
RETURN FALSE;
ELSE
dsalt := gen_salt('bf');
hash := hash_cycle(pass, dsalt);
INSERT INTO users (username, password, salt, registered, activated, notifications) VALUES (uname, hash, dsalt, (SELECT LOCALTIMESTAMP), FALSE, 0);
RETURN TRUE;
END IF;
END;
$$ LANGUAGE plpgsql;
 
-- verify and prolong session
CREATE OR REPLACE FUNCTION verify_prolong_session(uname text, oldsignature text, session_id text, newsignature text, session_length integer) RETURNS text AS $$
DECLARE
stimestamp timestamp;
exptime timestamp;
dsalt text;
newkey text; 
BEGIN
-- check if session exists
IF EXISTS (SELECT * FROM sessions WHERE ((sid LIKE session_id) AND (username LIKE uname) AND (sign LIKE oldsignature))) THEN
SELECT LOCALTIMESTAMP into stimestamp;
-- I had to put it as a separate string
SELECT expires INTO exptime FROM sessions WHERE ((sid LIKE session_id) AND (username LIKE uname) AND (sign LIKE oldsignature));
-- if session has expired - delete it
IF (stimestamp > exptime) THEN
-- in theory, sid is unique enough, but I use two values to be on the safe side
DELETE FROM sessions WHERE ((sid LIKE session_id) AND (username LIKE uname));
RETURN 'Session_expired';
ELSE
-- we can’t use hmac with timestamp directly, have to cast it to text
newkey := stimestamp;
newkey := encode(hmac(newkey, session_id, 'sha256'), 'hex');
dsalt := gen_salt('bf');
FOR i IN 1..25 LOOP
newkey := encode(hmac(newkey, dsalt, 'sha256'), 'hex');
END LOOP;
UPDATE sessions SET expires=stimestamp + session_length*interval'1 HOUR', sign = newsignature, sid = newkey WHERE ((sid LIKE session_id) AND (username LIKE uname));
RETURN newkey;
END IF;
ELSE
RETURN 'Nonexisting_session';
END IF;
END;
$$ LANGUAGE plpgsql;
 
-- function for checking session existence without prolongation
-- returns boolean. Cannot be used in verify_prolong session
-- because it doesn’t explain reasons
CREATE OR REPLACE FUNCTION session_valid(uname text, signature text, session_id text) RETURNS boolean AS $$
DECLARE
stimestamp timestamp;
BEGIN
SELECT LOCALTIMESTAMP into stimestamp;
IF (EXISTS (SELECT * FROM sessions WHERE (username LIKE uname) AND (sign LIKE signature) AND (sid LIKE session_id) AND (expires > stimestamp))) OR (uname = 'Anonymous') THEN
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;
 
CREATE OR REPLACE FUNCTION close_session(uname text, signature text, session_id text) RETURNS void AS $$
BEGIN
DELETE FROM sessions WHERE ((sid LIKE session_id) AND (username LIKE uname) AND (sign LIKE signature));
END;
$$ LANGUAGE plpgsql;
 
-- function for erasing old sessions
-- see /var/lib/pgsql/cleansessions.sql
-- and crontab of user postgres
CREATE OR REPLACE FUNCTION clean_sessions() RETURNS void AS $$
DECLARE
stimestamp timestamp;
BEGIN
SELECT LOCALTIMESTAMP into stimestamp;
-- delete all sessions which are expired
DELETE FROM sessions WHERE expires<stimestamp;
END;
$$ LANGUAGE plpgsql;
 
-- function for checking if the account for user username is active
CREATE OR REPLACE FUNCTION user_active (uname text) RETURNS boolean AS $$
BEGIN
-- returns TRUE only if the account is not activated and no mails were sent
RETURN (NOT (SELECT activated FROM users WHERE username LIKE uname) AND ((SELECT notifications FROM users WHERE username LIKE uname) = 0));
END;
$$ LANGUAGE plpgsql;
 
CREATE OR REPLACE FUNCTION activate_account (key text) RETURNS boolean AS $$
DECLARE
uname text;
BEGIN
IF EXISTS (SELECT * FROM users WHERE custom LIKE key) THEN
SELECT username INTO uname FROM users WHERE custom LIKE key;
-- we have to check activation twice to avoid possible DDOS (to lower its chance) 
UPDATE users SET activated=TRUE, notifications=0, custom='' WHERE username LIKE uname;
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;
 
-- function for activation key generation
CREATE OR REPLACE FUNCTION get_activation_key(uname text) RETURNS text AS $$
DECLARE
key text;
dsalt text;
hash text;
BEGIN
-- is it possible to write it as one string?
SELECT salt INTO dsalt FROM users WHERE username LIKE uname;
SELECT password INTO hash FROM USERS WHERE username LIKE uname;
key := encode(hmac(uname, hash, 'sha256'), 'hex');
key := encode(hmac(hash, key, 'sha256'), 'hex');
FOR i IN 1..20 LOOP
key := encode(hmac(key, dsalt, 'sha256'), 'hex');
END LOOP;
UPDATE users SET custom=key WHERE username LIKE uname;
RETURN key;
END;
$$ LANGUAGE plpgsql;
 
CREATE OR REPLACE FUNCTION activation_mail_sent(uname text) RETURNS void AS $$
BEGIN
UPDATE users SET notifications=1 WHERE username LIKE uname;
END;
$$ LANGUAGE plpgsql;
 
-- check if password reset is allowed
CREATE OR REPLACE FUNCTION check_reset_notifications(uname text) RETURNS boolean AS $$
BEGIN
-- avoid spam - send only if we have already sent less than 3 mails
RETURN ((SELECT notifications FROM users WHERE username LIKE uname) < 3);
END;
$$ LANGUAGE plpgsql;
 
-- function for forgotten password key generation
CREATE OR REPLACE FUNCTION get_reset_key(uname text) RETURNS text AS $$
DECLARE
key text;
dsalt text;
hash text;
regdate text;
mails_sent integer;
BEGIN
SELECT salt INTO dsalt FROM users WHERE username LIKE uname;
SELECT password INTO hash FROM users WHERE username LIKE uname;
SELECT registered INTO regdate FROM users WHERE username LIKE uname;
key := encode(hmac(uname, regdate, 'sha256'), 'hex');
FOR i IN 1..50 LOOP
key := encode(hmac(key, dsalt, 'sha256'), 'hex');
END LOOP;
key := encode(hmac(hash, key, 'sha256'), 'hex');
FOR i IN 1..25 LOOP
key := encode(hmac(key, hash, 'sha256'), 'hex');
END LOOP;
SELECT notifications INTO mails_sent FROM users WHERE username LIKE uname;
UPDATE users SET notifications=mails_sent+1 WHERE username LIKE uname;
RETURN key;
END;
$$ LANGUAGE plpgsql;

-- function for restoring forgotten password (when user can't log in)
CREATE OR REPLACE FUNCTION reset_password(uname text, newpass text, resetkey text) RETURNS boolean AS $$
DECLARE
valid_key text;
dsalt text;
new_hash text;
actstatus boolean;
BEGIN
SELECT activated INTO actstatus FROM users WHERE username LIKE uname;
valid_key := get_reset_key(uname);
IF ((resetkey = valid_key) AND (actstatus = TRUE)) THEN
dsalt := gen_salt('bf');
new_hash := hash_cycle(newpass, dsalt);
UPDATE users SET password=new_hash, salt=dsalt, notifications = 0 WHERE username LIKE uname;
DELETE FROM sessions WHERE username LIKE uname;
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;

-- function for changing password (user logged in into account)
CREATE OR REPLACE FUNCTION change_password(uname text, oldpass text, newpass text, session_id text) RETURNS boolean AS $$
DECLARE
old_hash text;
correct_hash text;
new_hash text;
dsalt text;
BEGIN
SELECT salt INTO dsalt FROM users WHERE username LIKE uname;
old_hash := hash_cycle(oldpass, dsalt);
SELECT password INTO correct_hash FROM users WHERE username LIKE uname;
IF (old_hash=correct_hash) THEN
dsalt := gen_salt('bf');
new_hash := hash_cycle(newpass, dsalt);
UPDATE users SET password=new_hash, salt=dsalt WHERE username LIKE uname;
-- also - close all old sessions
DELETE FROM sessions WHERE (username LIKE uname) AND (sid<>session_id);
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;

-- switch status of global notifications and apply it to all user projects
CREATE OR REPLACE FUNCTION change_notifications_status(uname text) RETURNS boolean AS $$
DECLARE
old_value boolean;
BEGIN
SELECT notifications_accepted INTO old_value FROM users WHERE username LIKE uname;
UPDATE users SET notifications_accepted = NOT old_value WHERE username LIKE uname;
UPDATE projects SET receive_notifications = NOT old_value WHERE owner LIKE uname;
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
 
-- function for checking if user is among project users
CREATE OR REPLACE FUNCTION is_owner(uname text, project_id text) RETURNS boolean AS $$
BEGIN
-- anyone can access to anonymous projects
IF EXISTS (SELECT * FROM projects WHERE (projectid LIKE project_id) AND ((owner LIKE uname) OR (owner LIKE 'Anonymous'))) THEN
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;
 
-- function for checking if the user can access the project
CREATE OR REPLACE FUNCTION check_permission(uname text, session_id text, oldsignature text, newsignature text, session_length integer, project_id text) RETURNS text AS $$
DECLARE
newkey text;
lproject_id text;
BEGIN
SELECT LOWER(project_id) INTO lproject_id;
IF (uname <>'Anonymous') THEN
newkey := verify_prolong_session(uname, oldsignature, session_id, newsignature, session_length);
IF ((newkey = 'Session_expired') OR (newkey = 'Nonexisting_session')) THEN
RETURN 'Denied';
END IF;
ELSE newkey := '';
END IF;
IF (SELECT is_owner(uname, lproject_id)) THEN
RETURN ('Allowed:' || newkey);
ELSE
RETURN ('Denied:' || newkey);
END IF;
END;
$$ LANGUAGE plpgsql;
 
-- function for creating a new project
-- uname is the creator’s username
CREATE OR REPLACE FUNCTION add_project(project_id text, uname text) RETURNS void AS $$
DECLARE
notifications boolean;
lproject_id text;
BEGIN
IF (uname<>'Anonymous') THEN
SELECT notifications_accepted INTO notifications FROM users WHERE username LIKE uname;
ELSE
notifications := FALSE;
END IF;
-- project names should be lowercase
SELECT LOWER(project_id) INTO lproject_id;
-- user who created project is administrator by default
INSERT INTO projects VALUES (lproject_id, uname, 3, notifications);
END;
$$ LANGUAGE plpgsql;


-- check if project exists
-- because projects table is not open for anyone
CREATE OR REPLACE FUNCTION project_exists(project_id text) RETURNS boolean AS $$
DECLARE
status boolean;
BEGIN
IF EXISTS (SELECT * FROM projects WHERE projectid LIKE project_id) THEN
status := TRUE;
ELSE
status := FALSE;
END IF;
RETURN status;
END;
$$ LANGUAGE plpgsql;

-- check if project is anonymous (see HS.js)
-- because projects table is not open for anyone
CREATE OR REPLACE FUNCTION project_anonymous(project_id text) RETURNS boolean AS $$
DECLARE
status boolean;
BEGIN
IF EXISTS (SELECT * FROM projects WHERE (projectid LIKE project_id) AND (owner LIKE 'Anonymous')) THEN
status := TRUE;
ELSE
status := FALSE;
END IF;
RETURN status;
END;
$$ LANGUAGE plpgsql;
 
-- add an owner to the existing project
-- owner_uname is the existing owner’s username
-- newowner_uname is the new owner’s username
CREATE OR REPLACE FUNCTION add_project_member(project_id text, owner_uname text, newmember_uname text, member_role integer) RETURNS boolean AS $$
DECLARE
ac_level integer;
BEGIN
-- check if user owner_uname has rights to add new owners and new member has been registered and activated
IF (EXISTS (SELECT * FROM projects WHERE (projectid LIKE project_id) AND (owner LIKE owner_uname) AND (access_level=3))) AND (EXISTS (SELECT * FROM users WHERE (username LIKE newmember_uname) AND (activated=TRUE))) THEN
-- if user already has rights - change rights. Also, rights for administrator cannot be changed
-- if user has administrator privelegies - return FALSE to prevent sending letters
-- also we forbid changing rights to the same state (e.g. "Read-only" to "Read-only")
IF EXISTS (SELECT * FROM projects WHERE (projectid LIKE project_id) AND (owner LIKE newmember_uname)) THEN
SELECT access_level INTO ac_level FROM projects WHERE (projectid LIKE project_id) AND (owner LIKE newmember_uname);
IF ((ac_level <> 3) AND (ac_level<>member_role)) THEN
UPDATE projects SET access_level=member_role WHERE (projectid LIKE project_id) AND (owner LIKE newmember_uname);
ELSE
RETURN FALSE;
END IF;
ELSE
-- if user does not have rights to access project - add user to project
INSERT INTO projects VALUES (project_id, newmember_uname, member_role);
END IF;
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;

-- invite member to the existing project
CREATE OR REPLACE FUNCTION invite_project_member(project_id text, owner_uname text, newmember_uname text, member_role integer) RETURNS boolean AS $$
DECLARE
ac_level integer;
res boolean;
BEGIN
res = false;
-- check if user owner_uname has rights to add new owners and new member has been registered and activated
IF (EXISTS (SELECT * FROM projects WHERE (projectid LIKE project_id) AND (owner LIKE owner_uname) AND (access_level=3))) AND (EXISTS (SELECT * FROM users WHERE (username LIKE newmember_uname) AND (activated=TRUE))) THEN
-- if user already has rights - change rights. Also, rights for administrator cannot be changed
-- if user has administrator privelegies - return FALSE to prevent sending letters
-- also we forbid changing rights to the same state (e.g. "Read-only" to "Read-only")
IF EXISTS (SELECT * FROM projects WHERE (projectid LIKE project_id) AND (owner LIKE newmember_uname)) THEN
SELECT access_level INTO ac_level FROM projects WHERE (projectid LIKE project_id) AND (owner LIKE newmember_uname);
IF ((ac_level <> 3) AND (ac_level<>member_role)) THEN
UPDATE projects SET access_level=member_role WHERE (projectid LIKE project_id) AND (owner LIKE newmember_uname);
res = TRUE;
ELSE
res = FALSE;
END IF;
ELSE
-- check if user has already been invited
IF EXISTS (SELECT * FROM project_invitations WHERE (projectid LIKE project_id) AND (member LIKE newmember_uname)) THEN
-- if exists - return false (user has already been invited
res = FALSE;
ELSE 
-- if user has not been invited - invite
INSERT INTO project_invitations VALUES (project_id, newmember_uname, owner_uname, LOCALTIMESTAMP, member_role);
res = TRUE;
END IF;
END IF;
ELSE
res = FALSE;
END IF;
RETURN res;
END;
$$ LANGUAGE plpgsql;

-- return all user projects names and levels
CREATE OR REPLACE FUNCTION user_projects(uname text) RETURNS setof text AS $$
DECLARE
res text;
BEGIN
FOR res IN SELECT (projectid, receive_notifications, access_level) FROM projects WHERE owner LIKE uname
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- user's sent project invitations
CREATE OR REPLACE FUNCTION user_sent_invitations(uname text) RETURNS setof text AS $$
DECLARE
res text;
BEGIN
FOR res IN SELECT (projectid, member, invitation_sent, access_level) FROM project_invitations WHERE invited_by LIKE uname
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- user's received project invitations
CREATE OR REPLACE FUNCTION user_received_invitations(uname text) RETURNS setof text AS $$
DECLARE
res text;
BEGIN
FOR res IN SELECT (projectid, invited_by, invitation_sent, access_level) FROM project_invitations WHERE member LIKE uname
LOOP
RETURN NEXT res;
END LOOP;
END;
$$ LANGUAGE plpgsql;

-- return all project members and their access levels
CREATE OR REPLACE FUNCTION project_members(uname text, project_id text) RETURNS setof text AS $$
DECLARE
res text;
BEGIN
-- only project administrators can view members
IF EXISTS (SELECT * FROM projects WHERE (owner LIKE uname) AND (projectid LIKE project_id) AND (access_level=3)) THEN
FOR res IN SELECT (owner, access_level) FROM projects WHERE projectid LIKE project_id
LOOP
RETURN NEXT res;
END LOOP;
END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_project_member(member text, project_id text, administrator text) RETURNS boolean AS $$
BEGIN
-- just in case - check if we have this user in project. Of course, we can delete 0 records, but we need to show error message "You don't have rights or user doesn’t exist in this project"
-- also it's impossible to delete another administrator 
IF ((EXISTS(SELECT * FROM projects WHERE (owner LIKE member) AND (projectid LIKE project_id) AND (access_level<>3))) AND (EXISTS (SELECT * FROM projects WHERE (owner LIKE administrator) AND (projectid LIKE project_id) AND (access_level=3)))) THEN
DELETE FROM projects WHERE owner LIKE member AND projectid LIKE project_id;
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_public(project_id text, administrator text) RETURNS boolean AS $$
BEGIN
-- project can be made public only once, so we verify if (Anonymous, 1) exists already for the project
IF (EXISTS (SELECT * FROM projects WHERE (owner LIKE administrator) and (projectid LIKE project_id) AND (access_level=3)) AND NOT (EXISTS (SELECT * FROM projects WHERE (owner LIKE 'Anonymous') AND (projectid LIKE project_id)))) THEN
INSERT INTO projects VALUES (project_id, 'Anonymous', 1);
RETURN TRUE;
ELSE
RETURN FALSE;
END IF;
END;
$$ LANGUAGE plpgsql;

-- change notifications status for one project
CREATE OR REPLACE FUNCTION change_project_notifications_status(uname text, project_id text) RETURNS boolean AS $$
DECLARE
old_value boolean;
BEGIN
SELECT receive_notifications INTO old_value FROM projects WHERE (owner LIKE uname) AND (projectid LIKE project_id);
UPDATE projects SET receive_notifications = NOT old_value WHERE (owner LIKE uname) AND (projectid LIKE project_id);
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- accept invitation and join the project
CREATE OR REPLACE FUNCTION accept_invitation(uname text, project_id text) RETURNS boolean AS $$
DECLARE
notifications boolean;
role integer;
BEGIN
SELECT notifications_accepted INTO notifications FROM users WHERE username LIKE uname;
SELECT access_level INTO role FROM project_invitations WHERE (member LIKE uname) AND (projectid LIKE project_id);
INSERT INTO projects VALUES (project_id, uname, role, notifications);
DELETE FROM project_invitations WHERE (member LIKE uname) AND (projectid LIKE project_id);
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- reject invitation and delete it
-- this function is also used for cancelling invitations
CREATE OR REPLACE FUNCTION reject_invitation(uname text, project_id text) RETURNS boolean AS $$
BEGIN
DELETE FROM project_invitations WHERE (member LIKE uname) AND (projectid LIKE project_id);
RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- create a unique hash (part of a shareable link) for JID
-- if hash already exists - return existing hash
-- if uname is not an owner - return "failed"
CREATE OR REPLACE FUNCTION get_shareable_link(uname text, sjid text) RETURNS text AS $$
DECLARE
hash text;
stimestamp text;
project text;
BEGIN
SELECT projectid INTO project FROM projectarchives WHERE jid LIKE sjid; 
IF (EXISTS (SELECT * FROM projects WHERE (owner LIKE uname) AND (access_level>1) AND (projectid LIKE project))) THEN
IF (EXISTS (SELECT share_hash FROM projectarchives WHERE (jid LIKE sjid) AND (share_hash <> ''))) THEN
SELECT share_hash INTO hash FROM projectarchives WHERE (jid LIKE sjid) AND (share_hash<>'');
ELSE
SELECT CURRENT_TIME INTO stimestamp;
hash := encode(hmac(sjid, stimestamp, 'sha256'), 'hex');
WHILE (EXISTS (SELECT * FROM projectarchives WHERE share_hash LIKE hash)) LOOP
SELECT CURRENT_TIME INTO stimestamp;
hash := encode(hmac(sjid, stimestamp, 'sha256'), 'hex');
END LOOP;
UPDATE projectarchives SET share_hash=hash WHERE jid LIKE sjid;
END IF;
ELSE
hash := 'failed';
END IF;
RETURN hash;
END;
$$ LANGUAGE plpgsql;

-- check if user can perform an action
-- only users with level 2 or 3 can perform some actions
-- used in: 
CREATE OR REPLACE FUNCTION permission_granted (uname text, project_id text) RETURNS boolean AS $$
DECLARE
response boolean;
BEGIN
IF (project_id = '') THEN
response := FALSE;
ELSE
IF (EXISTS(SELECT * FROM projects WHERE (owner LIKE uname) AND (projectid LIKE project_id) AND (access_level > 1))) THEN
response := TRUE;
ELSE
response := FALSE;
END IF;
END IF;
RETURN response;
END;
$$ LANGUAGE plpgsql;

-- check number of notifications
CREATE OR REPLACE FUNCTION notifications_queue (uname text, signature text, session_id text) RETURNS integer AS $$
DECLARE
session_status boolean;
notifications integer;
BEGIN
IF (SELECT session_valid(uname, signature, session_id)) THEN
SELECT COUNT (projectid) INTO notifications FROM project_invitations WHERE (member LIKE uname);
ELSE
notifications := 0;
END IF;
RETURN notifications;
END;
$$ LANGUAGE plpgsql;

-- more secure hash
CREATE FUNCTION enforced_hash_cycle(pass text, salt text, n integer DEFAULT 100) RETURNS text AS $$
DECLARE
hash text;
BEGIN
hash := encode(hmac(pass, salt, 'sha256'), 'hex');
FOR i IN 1..10 LOOP
hash := encode(hmac(hash, pass, 'sha256'), 'hex');
END LOOP;
hash := encode(hmac(hash, hash, 'sha256'), 'hex');
FOR i IN 1..n-1 LOOP
hash := encode(hmac(hash, salt, 'sha256'), 'hex');
END LOOP;
RETURN hash;
END;
$$ LANGUAGE plpgsql;
 
CREATE FUNCTION enforced_hash_speed(pass text, n integer DEFAULT 100) RETURNS void AS $$
DECLARE
dsalt text;
BEGIN
FOR i IN 1..n LOOP
-- dynamic salt using Blowfish algorithm
dsalt := gen_salt('bf');
PERFORM enforced_hash_cycle(pass, dsalt);
END LOOP;
END;
$$ LANGUAGE plpgsql;
