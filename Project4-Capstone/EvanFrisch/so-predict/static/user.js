/**
 * Sets link to Stack Overflow user image,
 * sets up the slider for reputation level,
 * and displays box and whisker charts.
 **/
function preparePage() {
    prepareImage();
    prepareSlider();
    prepareSparklines();
}

/* Sets link to Stack Overflow user image. */
function prepareImage() {
    image = document.getElementById("user-profile");
    console.log("image.src:"+image.src);
    if(image.src.endsWith("static/user.png")) {
        image.src = image.src.replace("static/user.png","../static/user.png");
        console.log("Changed image.src to:"+image.src);
    }
}

/* Sets up the slider for reputation level. */
function prepareSlider() {
    var slider = new Slider("#reputationSlider");
}

/* Call preparePage upon loading the page. */
if(window.attachEvent) {
    window.attachEvent('onload', preparePage);
} else if(window.addEventListener) {
    window.addEventListener('load', preparePage, false);
} else {
    document.addEventListener('load', preparePage, false);
}

/* Gets the user object for the specified ID. */
function getUserByID(userID) {
    if(session == null) {
        console.log("In getUserByID, session is null");
        return null;
    }
    user = session.users.filter(
        function(u){ return u.userID == userID } 
    );
    if(user === null || user === undefined) {
        return null;
    } else {
        return user[0]; 
    }
}

/* Gets the result code for the specified user ID. */
function getResultByID(userID) {
    var user = getUserByID(userID);
    console.log("In getResultByID, user:"+user);
    if(user === null || user === undefined) {
        return null;
    } else {
        return user.result;
    }
}


/**
 * Gets the selection that the player made for the
 * specified user ID.
 */
function getUserSelectionByID(userID) {
    var user = getUserByID(userID);
    console.log("In getUserSelectByID, user:"+user);
    if(user === null || user === undefined) {
        return null;
    } else {
        return user.userSelection;
    }
}

/* Displays box and whisker charts for each metric. */
function prepareSparklines() {
    var metrics = ['questions_count','answers_count','comments_count','questions_total_score','answers_total_score','comments_total_score'];

    metrics.forEach(function(metric) {
        console.log("In prepareSparklines, metric: "+metric);
        prepareSparkline(metric,false);
    });
}

/**
 * Display a modal dialog showing how the player's prediction
 * fared against the machine.
 **/
$('#myModal').on('show.bs.modal', function(e) {
    var correctAnswer = document.getElementById('correctAnswer').value;
    var modelPrediction = document.getElementById('prediction').value;
    var userSelection = parseInt(document.querySelector(".tooltip-inner").innerHTML);
    var userID = document.getElementById('userID').value;
    console.log("userID from document:"+userID);
    console.log("correctAnswer:"+correctAnswer);
    console.log("modelPrediction:"+modelPrediction);
    console.log("userSelection:"+userSelection);
    modelDifference = Math.abs(correctAnswer-modelPrediction);
    userDifference = Math.abs(correctAnswer-userSelection);
    console.log("modelDifference:"+modelDifference);
    console.log("userDifference:"+userDifference);
    document.getElementById('model-prediction').innerHTML = modelPrediction;
    var outcome = "not sure";
    var outcomeGlyph = "glyphicon-unchecked";
    var outcomeBackground = "bg-info";
    session = getSessionFromStorage();
    var result = getResultByID(userID);
    console.log("result:"+result);

    /* Update points and determine appropriate outcome text, icon, and styles based on predictions. */
    if(result === null) {
        document.getElementById('user-selection').innerHTML = userSelection;
        if(userSelection == correctAnswer) {
            if(modelPrediction == correctAnswer) {
               outcome = "Tie! Your answer and the model's prediction are both correct.";
               outcomeGlyph = "glyphicon-hand-up";
               outcomeBackground = 'bg-success';
               addPoints('human',5);
               addPoints('machine',5);
               result = "BC";//Both Correct
            } else {
               outcome = "Winner! Your answer is correct, but the model's prediction is wrong.";
               outcomeGlyph = "glyphicon-thumbs-up";
               outcomeBackground = 'bg-primary';
               addPoints('human',10);
               result = "HC";//Human Correct Only
            }
        } else {
            if(modelPrediction == correctAnswer) {
               outcome = "Fail! Your answer is wrong, but the model's prediction is correct.";
               outcomeGlyph = "glyphicon-thumbs-down";
               outcomeBackground = 'bg-danger';
               addPoints('machine',10);
               result = "MC";//Machine Correct Only
            } else if(userDifference < modelDifference) {
               outcome = "Partial win! Your answer was closer than the model's prediction.";
               outcomeGlyph = "glyphicon-thumbs-up";
               outcomeBackground = 'bg-primary';
               addPoints('human',4);
               result = "HB";//Human Better
            } else if(userDifference < modelDifference) {
               outcome = "Fail! The model's prediction is closer than yours.";
               outcomeGlyph = "glyphicon-thumbs-down";
               outcomeBackground = 'bg-danger';
               addPoints('machine',4);
               result = "MB";//Machine Better
            } else {
               outcome = "Tie! Your answer is wrong, but the model's prediction is also wrong.";
               outcomeGlyph = "glyphicon-hand-down";
               outcomeBackground = 'bg-warning';
               result = "BI";//Both Incorrect
            }
        }
        // Update session object to reflect predictions and outcome.
        session.users.push({ 'userID': userID, 'result': result, 'userSelection': userSelection, 'modelPrediction': modelPrediction, 'correctAnswer': correctAnswer});
        sessionStorage.setItem('session', JSON.stringify(session));

        oldOutcomeMessage = document.getElementById('outcome').innerHTML.split('&nbsp;')[1];
        document.getElementById('outcome').innerHTML = document.getElementById('outcome').innerHTML.replace(oldOutcomeMessage, 'DEFAULTOUTCOME')
    } else {
        /**
         * Player predicted this question before, so prepare to display the outcome again
         * and show a warning that players may not predict the same question more than once.
         **/
        var userSelectionFromSession = getUserSelectionByID(userID);
        console.log("userSelectionFromSession:"+userSelectionFromSession);

        document.getElementById('user-selection').innerHTML = userSelectionFromSession;
        if(document.getElementById('isCheating').className == "hidden") {
            $("#isCheating").toggleClass('hidden');
        }
    }
    // Set outcome elements
    if(result == "BC") {
           outcome = "Tie! Your answer and the model's prediction are both correct.";
           outcomeGlyph = "glyphicon-hand-up";
           outcomeBackground = 'bg-success';
    } else if(result == "HC") {
           outcome = "Winner! Your answer is correct, but the model's prediction is wrong.";
           outcomeGlyph = "glyphicon-thumbs-up";
           outcomeBackground = 'bg-primary';
    } else if(result == "MC") {
           outcome = "Fail! Your answer is wrong, but the model's prediction is correct.";
           outcomeGlyph = "glyphicon-thumbs-down";
           outcomeBackground = 'bg-danger';
    } else if(result == "HB") {
           outcome = "Partial win! Your answer was closer than the model's prediction.";
           outcomeGlyph = "glyphicon-thumbs-up";
           outcomeBackground = 'bg-primary';
    } else if(result == "MB") {
           outcome = "Fail! The model's prediction is closer than yours.";
           outcomeGlyph = "glyphicon-thumbs-down";
           outcomeBackground = 'bg-danger';
    } else {
           outcome = "Tie! Your answer is wrong, but the model's prediction is also wrong.";
           outcomeGlyph = "glyphicon-hand-down";
           outcomeBackground = 'bg-warning';
    }

    // Display outcome with appropriate text, icon, and styles
    document.getElementById('outcome').innerHTML = document.getElementById('outcome').innerHTML.replace('DEFAULTOUTCOME', outcome);
    document.getElementById('outcome-icon').className = "glyphicon " + outcomeGlyph;
    document.getElementById('outcome').className = "modal-title " + outcomeBackground;
});
