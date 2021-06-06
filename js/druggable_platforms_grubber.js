importScripts('drugs.js');

var synonyms = get_druggable_platforms();
postMessage(synonyms);