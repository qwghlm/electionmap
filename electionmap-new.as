/* ELECTORAL MAP

version 1.5
Handles 2005 and 2001 data sets now

(c) Chris Applegate 2004-05
Licensed under the GPL

*/

stop();

// Constant, etc.
// Names of the parties
partyNames = ["Labour","Conservative","Lib Dem","SNP","Plaid Cymru"];

// Abbreviated names of the parties
partyNamesShort = ["Lab","Con","Lib Dem","SNP","PC","Ind","Speaker","Res"];

// Colours are produced by adding the sum of vectors on a HSV colour diagaram
// V = 1 in this case
// Hue and saturation are worked out in polar form - hue as angle, saturation as range

// Red, blue , green (Lib Dem), orange (SNP), yellow-green (PC), purple (turnout) represented in polar form
theta = [0, 4*Math.PI/3, 2*Math.PI/3, Math.PI/6, 5*Math.PI/12, 14*Math.PI/9];

// ... but to add them we need to work in cartesians, so we pre-calculate sin/cos funtions to work out the components
sinTheta = [];
cosTheta = [];
for (var j=0; j<6; j++) {
	sinTheta[j] = Math.sin(theta[j]);
	cosTheta[j] = Math.cos(theta[j]);
}
electionYear = 2005;

clipsArray = [];


// Which party/parties to display on the map
// All numbers are powers of two & can thus be combined
// though in practice we only combine the big three
// 1,2,4 = 1st, 2nd, 3rd party
// 8 = SNP & Plaid Cyrmu
// 16 = Turnout
//
// We initially have the big three
selectedParty = 7;

// Application state
appState = "loadingmap";

/* PROGRAM RUNNING */
// Running function that loads data and monitors state
this.onEnterFrame = function() {

	// Load the map
	if (appState == "loadingmap") {
		// Work out the percentage loaded
		var n;
		if (map.getBytesTotal() > 512) {
			n = Math.round(100 * map.getBytesLoaded()/map.getBytesTotal());
		}
		else n = 0;
		loadInfo.bar._xscale = n;

		if (n < 100) {
			loadInfo.message.text = "Loading Map..." + n + "%";
		}
		else {
			loadInfo.message.text = "Loaded Map. Now Loading Data...";
			loadInfo.bar._xscale = 0;
			doMapBounds();
			loadElectionData();
			appState = "loadingdata";
		}

	}

	// Load the constituency data
	else if (appState == "loadingdata") {
		var n;
		if (electionData.getBytesTotal() > 512) {
			n = Math.round(100 * electionData.getBytesLoaded()/electionData.getBytesTotal());
		}
		else n = 0;

		loadInfo.bar._xscale = n;
		loadInfo.message.text = "Loading Data..." + n + "%";
	}

	// Split the CSV data lines into an array of constituency data
	else if (appState == "parsedata") {
	    constituencyData = csvData.split("\r\n");
	    if (constituencyData.length == 1) {
			constituencyData = csvData.split("\n");
		}
		// Get rid of the top row (which is headers)
		constituencyData.shift();
		constituencyData.pop();

		numBoxes = constituencyData.length;
		// When that's done, parse each line
		loadInfo.message.text = "Processing data... ";
		appState = "fillboxes";
	}
	else if (appState == "fillboxes") {
		loadInfo.bar._xscale = 0;
		fillBoxes();
		appState = "colourboxes";
	}
	// Process the data and assign them to the constituency movie clips
	else if (appState == "colourboxes") {
		loadInfo._visible = true;
		var n = Math.round(100*colStart/maxIndex)
		loadInfo.message.text = "Colouring in..."+ n +"% ";
		loadInfo.bar._xscale = n;
		colourBoxes();
	}
	// All done
	else if (appState == "done") {
		loadInfo._visible = false;
		zIn._alpha = 100;
		optButton._alpha = 100;
		optButton.label.textColor = 0x999999;
		appState = "finished";
	}
}

electionData = new LoadVars();
electionData.onData = function(src) {
	csvData = src;
	loadInfo.message.text = "Loaded. Parsing Data...";
	loadInfo.bar._xscale = 0;
	appState = "parsedata";
}
function loadElectionData() {
	// electionData.load("2001data-enhanced.csv");
	electionData.load("2001+2005.csv");
}

// Wait 500ms before loading the map data (else app gets a bit crashy)

function loadMap() {
	map.loadMovie("mapdata_2005_final.swf");
	clearInterval(pid);
}
pid = setInterval(loadMap, 500);


/* SETTING APPEARANCE */

// Fills data into the constituency movieclips
function fillBoxes() {

	maxIndex = 0;

	for (var i=0; i<numBoxes; i++) {
		// Split the CSV data on commas, and match it to the movie clip of the constituency
		if (constituencyData[i] == "") continue;
		else {
			var thisConst = constituencyData[i].split(",");
			var thisSquare = map["s"+thisConst[0]];
		}
		// Throw an error if we can't find the clip
		if (thisSquare === undefined) {
			trace (thisConst[0] + "(" + thisConst[1] + ") is undefined!");
		}
		else {

			// Assign data to the constituency
			//
			// CSV data is:
			// number,name,labourVote,conservativeVote,libDemVote,snpVote,plaidVote,winningParty,turnout,totalRegistered

			thisSquare.id = thisConst[0];
			maxIndex = Math.max(thisSquare.id, maxIndex);

			clipsArray.unshift(thisSquare.id);

			thisSquare.name = thisConst[1];


			thisSquare.data2001 = new Object();
			thisSquare.data2005 = new Object();

			var array2001 = thisConst.slice(2,10);
			var array2005 = thisConst.slice(10,18);

			for (var j=0; j<8; j++) {
				if (array2001[j] == "" || array2001[j] == " ") array2001[j] = 0;
				if (array2005[j] == "" || array2005[j] == " ") array2005[j] = 0;
			}

			thisSquare.data2001.voteData = new Array();
			thisSquare.data2005.voteData = new Array();

			for (var j=0; j<5; j++) {
				thisSquare.data2001.voteData[j] = array2001[j];
				thisSquare.data2005.voteData[j] = array2005[j];
			}
			thisSquare.data2001.winner = array2001[5];
			thisSquare.data2001.totalVotes = array2001[6];
			thisSquare.data2001.turnout = array2001[7];

			thisSquare.data2005.winner = array2005[5];
			thisSquare.data2005.totalVotes = array2005[6];
			thisSquare.data2005.turnout = array2005[7];



			thisSquare.currentData = thisSquare["data"+electionYear];


			thisSquare.onRollOver = function() {
				showData(this)
			}

			thisSquare.onRollOut = function() {
				_root.rollBox._visible = false;
			}

			thisSquare.transforms = new Array();
		}
	}
}

function startColourBoxes(sp) {

	if (sp !== undefined) selectedParty = sp;

	colStart = 0;
	startTime = getTimer();

	/*
	// Reset all to white
	for (var i=0; i <= maxIndex; i++) {
		new Color(map["s"+i]).setTransform(
			{ ra: 100,
			  ga: 100,
			  ba: 100,
		  	  rb: 0, gb: 0, bb: 0 });
	} */

	appState = "colourboxes";
}

colStart = 0;
colLimit = 50;

// Adds colour to the boxes
function colourBoxes() {

	var selectedParties = [false,false,false,false,false];

	if (selectedParty < 8) {
		for (var i=0; i<3; i++) {
			selectedParties[i] = (selectedParty >> i) % 2 == 1
		}
	}
	else if (selectedParty == 8) {
		selectedParties[3] = true;
		selectedParties[4] = true;
	}

	// Go through each constituency
	for (var i=colStart; i< colStart + colLimit && i<clipsArray.length; i++) {

		var thisSquare = map["s"+clipsArray[i]];
		thisSquare._visible = (thisSquare.currentData.totalVotes > 0);

		if (thisSquare._visible) {

			// If we're looking at a nationalist vote, grey out the seats where this party does not stand
			thisSquare._alpha = (selectedParty == 8 && thisSquare.currentData.voteData[3] == 0 && thisSquare.currentData.voteData[4] == 0) ? 15 : 100;


			// If we have not yet worked out the transform for this square and this selected party, then do so

			if (thisSquare.transforms[selectedParty] === undefined) {
				// Work out the colour vector position...
				var x=0;
				var y=0;
				// If for turnout...
				if (selectedParty == 16) {
					// Emphasise turnout by reducing range between 25% and 75%
					x = (thisSquare.currentData.turnout-25)/50 * sinTheta[5];
					y = (thisSquare.currentData.turnout-25)/50 * cosTheta[5];
				}
				// If we're doing a party count...
				else {
					for (var j=0; j<5; j++) {
						// Only use a vector if we are viewing this party
						if (selectedParties[j]) {
							var rj = thisSquare.currentData.voteData[j]/thisSquare.currentData.totalVotes;
							x += rj * sinTheta[j];
							y += rj * cosTheta[j];
						}
					}
				}

				// Convert X and Y into and RGB colour object
				thisRGB = XYtoRGB(x,y);

				// Create a transform from this object
				var thisTransform = {
					ra: thisRGB.r,
					ga: thisRGB.g,
					ba: thisRGB.b,
					rb: 0, gb: 0, bb: 0 };

				// We store this transform so we don't need to work it out in future :-)
				thisSquare.transforms[selectedParty] = thisTransform;
			}
			new Color(thisSquare).setTransform(thisSquare.transforms[selectedParty]);
		}
		else {
			new Color(thisSquare).setTransform(null);
		}
		// Colour the clip accordingly


		// Stop if we're done
		if (i == clipsArray.length-1) {
			appState = "done";
			return;
		}
	}
	colStart += colLimit;
}

// Shows the data for a particular constituency when the mouse hovers over it
function showData(thisSquare) {

	// Only show the box when fully loaded
	if (appState == "finished") {
		// Shopw the box
		_root.rollBox._visible = true;
		// Do the name
		var s = "<b>" + thisSquare.name + " (" + partyNamesShort[thisSquare.currentData.winner] + ")</b>\n";

		for (var j=0; j<5; j++) {

			// Add in data for all thee parties, and optionally the 4th & 5th if the votes for them are above 0
			if (j < 3 || thisSquare.currentData.voteData[j] > 0) {

				var n = Math.round(1000*thisSquare.currentData.voteData[j]/thisSquare.currentData.totalVotes);

				s += " " + partyNames[j] + ": " +
						thisSquare.currentData.voteData[j] + " (" +
						(n/10) + "%)\n";

			}
		}
		s += "\nTotal votes: " + thisSquare.currentData.totalVotes +"\n";
		s += "Turnout: " + thisSquare.currentData.turnout + "%";
		//
		_root.rollBox.content.htmlText = s;

		// Resize the box accordingly
		_root.rollBox.background._height = _root.rollBox.content.textHeight + 5;
		_root.rollBox.background._width = Math.max(130,_root.rollBox.content.textWidth + 8);

		// Update the box's position
		_root.rollBox.onMouseMove();
	}
}



// Hide the rollover box to start with
rollBox._visible = false;
rollBox.swapDepths(1000);


function XYtoRGB(x,y) {
	// Convert x and y co-ordinates on the circle into hue and saturation
	// Hue is the multiple of 2PI that gives the angle
	var hue = Math.atan(x/y) / (2*Math.PI);

	// Saturation is length of the vector
	var sat = Math.sqrt(x*x + y*y);

	// Compensate for trig limitations
	if (y < 0) hue += 0.5;
	if (hue < 0) hue += 1;
	return HSVtoRGB(hue,sat,1);
}

function HSVtoRGB(h,s,v) {
	var clr;
	if (s == 0) {
		clr = [v,v,v]
	}
	else {
		h *= 6;
		i = Math.floor(h);
		f = h % 1;
		//
		p = v*(1-s);
		q = v*(1-s*f);
		t = v*(1-s*(1-f))
		//
		switch (i) {
			case 0: clr = [v,t,p]; break;
			case 1: clr = [q,v,p]; break;
			case 2: clr = [p,v,t]; break;
			case 3: clr = [p,q,v]; break;
			case 4: clr = [t,p,v]; break;
			case 5: clr = [v,p,q]; break;
		}
	}
	var retCol = {};
	retCol.r = clr[0]*100;
	retCol.g = clr[1]*100;
	retCol.b = clr[2]*100;
	return retCol;
}
//
//
//
/* Map Mask stuff */
mapZoom = 1;
function doMapBounds() {
	// Work out the bounds of the map
	mapLeftLimit = map._x - map._width/2;
	mapRightLimit = map._x + map._width/2;
	mapTopLimit = map._y - map._height/2;
	mapBottomLimit = map._y + map._height/2;
	// Where the map is 'centred'
	mapOriginX = map._x;
	mapOriginY = map._y;
}
// Draw a box around mask
_root.clear();
_root.lineStyle(1,0xCCCCCC);
_root.moveTo(mask._x-1, mask._y-1);
_root.lineTo(mask._x + mask._width, mask._y-1);
_root.lineTo(mask._x + mask._width, mask._y + mask._height);
_root.lineTo(mask._x-1, mask._y + mask._height);
_root.lineTo(mask._x-1, mask._y-1);
//
map._x = mask._x + mask._width/2;
map._y = mask._y + mask._height/2;

// Navigation stuff
// Remember where vertical and horizontal scrollbars are
vBarOrigin = vBar._y;
vBarRange = vBar._height;
hBarOrigin = hBar._x;
hBarRange = hBar._width;

// Zoom function. goIn is true if we zoom, false if we zoom out
function zoom(goIn) {

	if (appState == "finished") {
		// Only allow to zoom in if zoom is less than 4.
		if (goIn && mapZoom < 4) {
			mapZoom *= 2;
		}
		// Only allow zoom out if zoom is more than 1
		else if (!goIn && mapZoom > 1) {
			mapZoom /= 2;
		}

		// Go no further
		else return;
		// Rescale the map
		map._xscale = map._yscale = mapZoom * 100;
		// Move the map, to maintain the current centre
		var xOffset = map._x - mapOriginX;
		var yOffset = map._y - mapOriginY ;
		map._x += (goIn) ? xOffset : -xOffset/2;
		map._y += (goIn) ? yOffset : -yOffset/2;
		// Update the scrollbars
		updateBars();
	}
}

// Move the map when arrow buttons are pressed
function move(xDiff, yDiff) {
	if (appState == "finished") {
		map._x += xDiff;
		map._y += yDiff;
		updateBars();
	}
}


// Checks to see if the map is within the bounds, and doesn't over-scroll
function checkBounds() {
	map._x = Math.max(map._x, mapRightLimit - map._width/2);
	map._x = Math.min(map._x, mapLeftLimit + map._width/2);
	map._y = Math.max(map._y, mapBottomLimit - map._height/2);
	map._y = Math.min(map._y, mapTopLimit + map._height/2);
}


// Updates the bars' position after zoom or arrow buttons have been pressed
function updateBars() {
	// Check the map is within bounds
	checkBounds();
	// Scale & position the scroll bars
	hBar._xscale = 100 / mapZoom;
	hBar._x = hBarOrigin - (hBarRange * (map._x - mapOriginX)/map._width);
	//
	vBar._yscale = 104 / mapZoom;
	vBar._y = vBarOrigin - (vBarRange * (map._y - mapOriginY)/map._height);
	//
	// Hide the bars, if current zoome is 1
	vBar._visible = hBar._visible = (mapZoom > 1);
	// Grey out the zoom in button if fully zoomed in
	zIn._alpha = (mapZoom < 4) ? 100 : 25;
	// Grey out the arrow and zoom out buttons if fully zoomed out
	arrowUp._alpha = arrowDown._alpha = arrowRight._alpha = arrowLeft._alpha =
	zOut._alpha = (mapZoom > 1) ? 100 : 25;
}


// Updates the map after the bars have been dragged
function updateMap() {
	map._x = map._width*(hBarOrigin - hBar._x)/hBarRange + mapOriginX;
	map._y = map._height*(vBarOrigin - vBar._y)/vBarRange + mapOriginY;
	checkBounds();
}

/* UI management */

/* Arrows and zoom buttons */

// Assign onRelease function to the zoom buttons
zIn.onRelease = function() { zoom(true); };
zOut.onRelease = function() { zoom(false); };

// Assign onRelease functions to the arrow buttons to move the bars
arrowUp.onRelease = function() { move(0, 20); };
arrowDown.onRelease = function() { move(0, -20); };
arrowRight.onRelease = function() { move(-20, 0); };
arrowLeft.onRelease = function() { move(20, 0); };

// Grey out the zoom and arrow buttons, initially
zIn._alpha = 25;
zOut._alpha = 25;
arrowUp._alpha = 25;
arrowDown._alpha = 25;
arrowRight._alpha = 25;
arrowLeft._alpha = 25;

/* Scrollbars */

// Hide the scrollbars (as we're not zoomed in yet)
vBar._visible = hBar._visible = false;
// Don't use hand cursors on the bars
vBar.useHandCursor = hBar.useHandCursor =
vBarBack.useHandCursor = hBarBack.useHandCursor = false;

// Assign drag functions to the scrollbars
vBar.onPress = function() {
	startDrag(this,false,vBar._x,vBarOrigin-(vBarRange-vBar._height)/2,
					     vBar._x,vBarOrigin+(vBarRange-vBar._height)/2);

	this.onMouseMove = function() { updateMap(); };

}

hBar.onPress = function() {
	startDrag(this,false,hBarOrigin-(hBarRange-hBar._width)/2,hBar._y,
					     hBarOrigin+(hBarRange-hBar._width)/2,hBar._y);

	this.onMouseMove = function() { updateMap(); };
}

// End drag functions for the bars
vBar.onRelease = vBar.onReleaseOutside =
hBar.onRelease = hBar.onReleaseOutside =
function() { delete this.onMouseMove(); stopDrag(); };

// onRelease functions for the scrollbars' backgrounds, clicking on them moves up the bar one whole bar length
vBarBack.onRelease = function() {
	if (vBar._visible) {
		if (_root._ymouse > vBar._y + vBar._height/2) {
			map._y -= (mapBottomLimit - mapTopLimit)
		}
		else if (_root._ymouse < vBar._y - vBar._height/2) {
			map._y += (mapBottomLimit - mapTopLimit)
		}
		updateBars();
	}
}
hBarBack.onRelease = function() {
	if (hBar._visible) {
		if (_root._xmouse > hBar._x + hBar._width/2) {
			map._x -= (mapRightLimit - mapLeftLimit)
		}
		else if (_root._xmouse < hBar._x - hBar._width/2) {
			map._x += (mapRightLimit - mapLeftLimit)
		}
		updateBars();
	}
}

/* Radio buttons */

// Set up radio buttons
electionYears = [2001,2005];
for (var i=0; i<2; i++) {
	this["eb"+i].useHandCursor = false;
	this["eb"+i].value = electionYears[i];
	this["eb"+i].label.text = electionYears[i];
	this["eb"+i].label.
	this["eb"+i].button.dot._visible = false;
	this["eb"+i].onRelease = function () {
		if (_root.appState == "finished")
		chooseElectionYear(this);
	}
}
eb1.button.dot._visible = true;

function chooseElectionYear(button) {
	for (var j=0; j<2; j++) {
		this["eb"+j].button.dot._visible = (this["eb"+j] == button);
	}

	if (electionYear != button.value) {

		electionYear = button.value;

		for (var i=0; i<clipsArray.length; i++) {

			var n = clipsArray[i]

			map["s"+n].currentData = map["s"+n]["data"+electionYear];
			map["s"+n].transforms = new Array();

			map["s"+n]._visible = (map["s"+n].currentData.totalVotes > 0);
		}
		startColourBoxes();
	}
}

/* Options button */

// Setup the options button
optButton._alpha = 25;
optButton.label.textColor = 0xCCCCCC;
optButton.label.text = "Options";

// Assign it a click handler to show the dialog
optButton.onRelease = function() {
	if (appState == "finished") {
		configBox._visible = true;
	}
}
// Hide the dialog to begin with
configBox._visible = false;


// Function to go to London (for London inset link)
function gotoLondon() {
	map._x = mapOriginX - 130*mapZoom;
	map._y = mapOriginY + 100*mapZoom;
	updateBars();
}
