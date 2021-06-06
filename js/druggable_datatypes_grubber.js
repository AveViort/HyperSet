importScripts('drugs.js');

var synonyms = get_druggable_datatypes();
postMessage(synonyms);