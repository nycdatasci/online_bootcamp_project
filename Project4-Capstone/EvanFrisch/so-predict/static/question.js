var humanPoints;
var machinePoints;

/**
 * Displays labels based on question tags, sets the
 * selected tag in the user interface, displays the
 * name of the current level, and displays box and
 *  whisker charts for each metric.
 **/
function preparePage() {
    labelizeTags();
    presetTag();
    setLevelName();
    prepareSparklines();
    $(document).on('click', '.tag-button', setClickedTag);
}

/* Displays the name of the level that the player is playing. */
function setLevelName() {
    document.getElementById('levelName').innerHTML = 'Level ' + (parseInt(session.level,10)+1).toString() + ": " +levels[session.level].name;
}

/* Gets the question object for the specified ID. */
function getQuestionByID(questionID) {
    if(session == null) {
        console.log("In getQuestionByID, session is null");
        return null;
    }
    question = session.questions.filter(
        function(q){ return q.questionID == questionID } 
    );
    if(question === null || question === undefined) {
        return null;
    } else {
        return question[0]; 
    }
}

/* Gets the result code for the specified question ID. */
function getResultByID(questionID) {
    var question = getQuestionByID(questionID);
    console.log("In getResultByID, question:"+question);
    if(question === null || question === undefined) {
        return null;
    } else {
        return question.result;
    }
}

/**
 * Gets the selection that the player made for the
 * specified question ID.
 */
function getUserSelectionByQuestionID(questionID) {
    var question = getQuestionByID(questionID);
    console.log("In getUserSelectionByQuestionID, question:"+question);
    if(question === null || question === undefined) {
        return null;
    } else {
        return question.userSelection;
    }
}

/* Display question tags as labels. */
function labelizeTags() {
    var questionTags = document.getElementById('questionTags').innerHTML;
    var tags = questionTags.split('|');
    var labels = "";
    tags.forEach(function(item, index, array) {
        labels += '<button type="button" id="' + item + '" class="label tag-button label-';
        switch(index) {
            case 0: 
                labels += 'primary';
                break;
            case 1:
                labels += 'warning';
                break;
            case 2: 
                labels += 'info';
                break;
            case 3:
                labels += 'default';
                break;
            default:
                labels += 'success';
        }
        labels += '">'+item+'</button>';
    });
    document.getElementById('questionTags').innerHTML = labels;
}

/* Convert isFavorited boolean supplied to text. */
function getFavoritedText(isFavorited) {
    return parseInt(isFavorited)==1 ? 'Favorited' : 'Not Favorited';
}


/* Displays box and whisker charts for each metric. */
function prepareSparklines() {
    $('.inlinebar').sparkline('html', {type: 'bar', barColor: 'red'} );
    var metrics = ['answer_count','question_body_length','question_codeblock_count','question_comment_count','question_score','question_view_count'];

    metrics.forEach(function(metric) {
        console.log("In prepareSparklines, metric: "+metric);
        prepareSparkline(metric,true);
    });
}

/* Call preparePage upon loading the page. */
if(window.attachEvent) {
    window.attachEvent('onload', preparePage);
} else if(window.addEventListener) {
    window.addEventListener('load', preparePage, false);
} else {
    document.addEventListener('load', preparePage, false);
}

/**
 * Display a modal dialog showing how the player's prediction
 * fared against the machine.
 **/
$('#myModal').on('show.bs.modal', function(e) {
    session = getSessionFromStorage();
    var correctAnswer = document.getElementById('correctAnswer').value;
    console.log("session.level: "+session.level+", predictor: "+levels[session.level].predictor)+", level name: "+levels[session.level].name;
    var modelPrediction = document.getElementById(levels[session.level].predictor).value;
    var userSelection = $(e.relatedTarget).data('user-selection');
    var questionID = document.getElementById('questionID').value;
    console.log("correctAnswer:"+correctAnswer);
    console.log("getFavoritedText(correctAnswer):"+getFavoritedText(correctAnswer));
    console.log("modelPrediction:"+modelPrediction);
    console.log("getFavoritedText(modelPrediction):"+getFavoritedText(modelPrediction));
    console.log("userSelection:"+userSelection);
    console.log("getFavoritedText(userSelection):"+getFavoritedText(userSelection));
    document.getElementById('user-selection').innerHTML = getFavoritedText(userSelection);
    document.getElementById('model-prediction').innerHTML = getFavoritedText(modelPrediction);
    document.getElementById('correct-answer').innerHTML = getFavoritedText(correctAnswer);
    var outcome = "not sure";
    var outcomeGlyph = "glyphicon-unchecked";
    var outcomeBackground = "bg-info";
    var result = getResultByID(questionID);
    /* Update points and determine appropriate outcome text, icon, and styles based on predictions. */
    if(result === null) {
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
            } else {
               outcome = "Tie! Your answer is wrong, but the model's prediction is also wrong.";
               outcomeGlyph = "glyphicon-hand-down";
               outcomeBackground = 'bg-warning';
               result = "BI";//Both Incorrect
            }
        }

        // Update session object to reflect predictions and outcome.
        session.questions.push({ 'questionID': questionID, 'result': result, 'userSelection': userSelection, 'modelPrediction': modelPrediction, 'correctAnswer': correctAnswer });
        sessionStorage.setItem('session', JSON.stringify(session));

        oldOutcomeMessage = document.getElementById('outcome').innerHTML.split('&nbsp;')[1];
        document.getElementById('outcome').innerHTML = document.getElementById('outcome').innerHTML.replace(oldOutcomeMessage, 'DEFAULTOUTCOME')
    } else {
        /**
         * Player predicted this question before, so prepare to display the outcome again
         * and show a warning that players may not predict the same question more than once.
         **/
        var userSelectionFromSession = getUserSelectionByQuestionID(questionID);
        console.log("userSelectionFromSession:"+userSelectionFromSession);

        document.getElementById('user-selection').innerHTML = getFavoritedText(userSelectionFromSession);
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
