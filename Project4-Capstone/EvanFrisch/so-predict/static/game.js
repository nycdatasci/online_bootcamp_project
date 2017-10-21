/* Initialize the session object that stores the state of game play. */
var session = {
  'humanPoints': 0,
  'machinePoints': 0,
  'itemType': '',
  'level': 0,
  'tag': '',
  'questions': [],
  'users': []
}

/* Initialize the levels object with abbreviations and full names of the game levels. */
var levels = [{ predictor: 'prediction_lr', name: 'Logistic Regression'},{ predictor: 'prediction_gbm',name: 'Gradient Boosted Machine'},{ predictor: 'prediction_rf', name: 'Random Forest'}];


/* Calls updatePoints function to display current points. */
function prepareGame() {
    updatePoints();
}

/**
 * Gets the current number of points for the human player and
 * the machine opponent and updates the elements of the page
 * that display these scores.
 **/
function updatePoints() {
    console.log("In updatePoints function");
    var humanPointsFromSession = getPointsFromSession('human');
    var machinePointsFromSession = getPointsFromSession('machine');
    console.log("humanPointsFromSession is "+humanPointsFromSession);

    var humanPointsElement = document.getElementById('humanPoints')
    if(humanPointsElement) {
        humanPointsElement.innerHTML = humanPointsFromSession;
    }
    console.log("machinePointsFromSession is "+machinePointsFromSession);

    var machinePointsElement = document.getElementById('machinePoints')
    if(machinePointsElement) {
        machinePointsElement.innerHTML = machinePointsFromSession;
    }
}

/* Call prepareGame upon loading the page. */
if(window.attachEvent) {
    window.attachEvent('onload', prepareGame);
} else if(window.addEventListener) {
    window.addEventListener('load', prepareGame, false);
} else {
    document.addEventListener('load', prepareGame, false);
}

/**
 * Returns session object after retrieving it from SessionStorage
 * and parsing it or, if no session is found in SessionStorage,
 * store the session object in SessionStorage first.
 **/
function getSessionFromStorage() {
    if(sessionStorage.getItem('session') === null) {
        console.log("Session not found in session storage. Setting session in storage to:"+JSON.stringify(session));
        sessionStorage.setItem('session', JSON.stringify(session));
    } else {
        console.log("Session found in session storage. Setting local session from session storage:"+sessionStorage.getItem('session'));
        session = JSON.parse(sessionStorage.getItem('session'));
    }
    console.log("At end of getSessionFromStorage(), session:"+session+" JSON.stringify(session):"+JSON.stringify(session));
    return session;
}

/**
 * Returns the current score of the specified player
 * from the session object after retrieving it from
 * SessionStorage.
 **/
function getPointsFromSession(player) {
    console.log("At start of getPointsFromSession("+player+"), session:"+JSON.stringify(session));
    session = getSessionFromStorage();
    console.log("In getPointsFromSession("+player+") after getSessionFromStorage() call, session:"+JSON.stringify(session));
    if(player == 'human') {
        console.log("Player is human. session.humanPoints:"+session.humanPoints);
        return session.humanPoints;
    } else {
        console.log("Player is machine. session.machinePoints:"+session.machinePoints);
        return session.machinePoints;
    }
}

/* Flash effect to draw attention to score changes. */
var flash = function(elements) {
    var opacity = 100;
    var color = "255, 255, 20";
    var interval = setInterval(function() {
        opacity -= 3;
        if(opacity <= 0) {
            clearInterval(interval);
        }
        $(elements).css({background: "rgba("+color+", "+opacity/100+")"});
    }, 30)
};

/* Add the specified number of points to the score
 * of the selected player in the session object
 * and update the score that is displayed.
 **/
function addPoints(player,points) {
    result = addPointsInSession(player,points);
    console.log("In addPoints("+player+","+points+"), result: "+result);
    if(player === 'human') {
        console.log("Player is human");
        console.log("Setting #humanPoints to result: "+result);
        $('#humanPoints').text(result).fadeIn();
        flash($('#humanPoints'));
   } else {
        console.log("Player is machine");
        console.log("Setting #machinePoints to result: "+result);
        $('#machinePoints').text(result).fadeIn();
        flash($('#machinePoints'));
    }
}

/* Add the specified number of points to the score
 * of the selected player in the session object,
 * advancing the player to the next level if
 * appropriate, before storing the session in
 * SessionStorage.
 **/
function addPointsInSession(player,points) {
    console.log("In addPointsInSession("+player+","+points+")");
    session = getSessionFromStorage();

    if(player === 'human') {
        console.log("In addPointsInSession("+player+","+points+"), found that session.humanPoints was:"+session.humanPoints);
        if((session.humanPoints < 100 && session.humanPoints + points >= 100) || (session.humanPoints < 200 && session.humanPoints + points >= 200)) {
           session.level += 1;
           setLevelName();
           flash($('#levelName'));
           console.log("Moved up to level "+session.level);
        }
        session.humanPoints += points;
        result = session.humanPoints;
        console.log("In addPointsInSession("+player+","+points+"), result was:"+result);
    } else {
        console.log("In addPointsInSession("+player+","+points+"), found that session.machinePoints was:"+session.machinePoints);
        session.machinePoints += points;
        result = session.machinePoints;
        console.log("In addPointsInSession("+player+","+points+"), result was:"+result);
    }

    console.log("At end of addPointsInSession("+player+","+points+"), JSON.stringify(session):"+JSON.stringify(session));
    sessionStorage.setItem('session',JSON.stringify(session));
    return result;
}

/**
 * Assigns the specified tag in the session object
 * and store the session in SessionStorage.
 **/
function setTagInSession(tag='') {
    console.log("In setTagInSession("+tag+")");
    session = getSessionFromStorage();
    console.log("Found that session.tag was:"+session.tag);
    session.tag = tag;
    console.log("At end of setTagInSession("+tag+"), JSON.stringify(session):"+JSON.stringify(session));
    sessionStorage.setItem('session',JSON.stringify(session));
    return session.tag;
}

/**
 * Updates the user interface to use the tag
 * specified.
 **/
function setTag(tag) {
    moreQuestionsButton = document.getElementById('more-questions');
    moreLink = moreQuestionsButton.href;
    moreLink = moreLink.substring(0,moreLink.search('questions/')).concat('questions/',tag);
    moreQuestionsButton.href = moreLink;
    nextQuestionButton = document.getElementById('next-question');
    nextLink = nextQuestionButton.href;
    nextLink = nextLink.substring(0,nextLink.lastIndexOf('/')).concat('/',tag);
    nextQuestionButton.href = nextLink;
    $(".selected-tag").removeClass("selected-tag");
    $('[id="'+decodeURIComponent(tag)+'"]').addClass("selected-tag");
}

/**
 * Sets the tag that the user clicked in
 * the session object in SessionStorage
 * and update the user interface.
 **/
function setClickedTag() {
    tag = encodeURIComponent(this.id);
    // If same tag was already set, then clear it visually and clear from session
    session = getSessionFromStorage();
    console.log("Found that session.tag was:"+session.tag);
    if(tag == session.tag) {
        tag = '';
    }
    setTagInSession(tag);
    setTag(tag);
}

/**
 * Calls setTag to update the user interface to
 * use the tag found in the session object that
 * is retrieved from SessionStorage.
 **/
function presetTag() {
    session = getSessionFromStorage();
    console.log("In presetTag, session.tag: "+session.tag);
    setTag(session.tag);
}

/**
 * Calls the sparkline function from
 * the jQuery Sparkline plugin for the
 * specified metric to display a box
 * and whiskers chart.
 **/
function prepareSparkline(metric,isQuestionType=true) {
    var targetData = [];
    if(isQuestionType == true) {
        targetData = questionData;
    } else {
        targetData = userData;
    }
    var idName = "#boxplot-"+metric.replace(/_/g,"-");
    $(idName).sparkline(quants[metric], {
        type: 'box',
        raw: true,
        showOutliers: true,
        targetColor: 'FF0000',
        target: targetData[metric]
    });
}
