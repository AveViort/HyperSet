// this file contains event manager for druggable.html
// unlike most other JS files, it cannot be used with other projects
// however, the architecture is universal (mimicing Erlang server), so it can be copied into other projects

window.addEventListener("message", (event) => {
	var CurrentDate = new Date();
	switch(event.data) {
		case "show_progressbar":
			console.log("Showing progressbar " + CurrentDate.getHours() + ":" + CurrentDate.getMinutes() + ":" + CurrentDate.getSeconds());
			$("#progressbar").progressbar({		value: false	});	
			$("#progressbar").css({"visibility": "visible"});
			break;
		case "hide_progressbar":
			console.log("Hiding progressbar " + CurrentDate.getHours() + ":" + CurrentDate.getMinutes() + ":" + CurrentDate.getSeconds());
			$("#progressbar").css({"visibility": "hidden"});
			break;
		default:
			console.log("Unknown message received");
			console.log(event);
	}
}
);