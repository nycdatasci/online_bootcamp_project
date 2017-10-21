/**
 * Prepares the questions list page by applying strikethrough to questions
 * that were already answered, hiding the tag filter if no tag is selected,
 * and associating clicks on the clear filter button with a function
 * that clears the selected tag.
 */
function preparePage() {
    strikethroughAnsweredItems();
    hideEmptyTagFilter();
    $(document).on('click', '#clear-filter', clearTagFilter);
}

/* Call preparePage upon loading the page. */
if(window.attachEvent) {
    window.attachEvent('onload', preparePage);
} else if(window.addEventListener) {
    window.addEventListener('load', preparePage, false);
} else {
    document.addEventListener('load', preparePage, false);
}

/* Gets the specified question object from the session object */
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

/**
 * Adds a class that applies strikethrough to each question that
 * the player already answered.
 */
function strikethroughAnsweredItems() {
    session = getSessionFromStorage();
    var items = document.getElementsByClassName("item");
    for(var i=0; i<items.length; i++) {
        if(getQuestionByID(items[i].id)) {
            items[i].className += " answered";
            console.log("In strikethroughAnsweredItems, item["+i+"].id:"+items[i].id);
        }
    }
}

/* Hides the tag filter text if no tag is selected. */
function hideEmptyTagFilter() {
    if(session.tag == '') {
        document.getElementById("tag-filter").style.display = 'none';
    }
}

/* Deselects the selected tag. */
function clearTagFilter() {
    setTagInSession('');
}
