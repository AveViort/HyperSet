importScripts('drugs.js');

self.addEventListener("message", function(e) {
    //console.log(e.data);
	var ids = get_correlation_features_and_genes(e.data[0], e.data[1], e.data[2], e.data[3], e.data[4]);
	postMessage(ids);
}, false);

// precaution - terminate after 1 minute 
//setTimeout(self.close(), 60000);
