importScripts('drugs.js');

var synonyms = get_synonyms();
postMessage(synonyms);