/**
 * Prepares the users list page by applying strikethrough to user challenges
 * that were already answered.
 */
function preparePage() {
    strikethroughAnsweredItems();
}

/* Call preparePage upon loading the page. */
if(window.attachEvent) {
    window.attachEvent('onload', preparePage);
} else if(window.addEventListener) {
    window.addEventListener('load', preparePage, false);
} else {
    document.addEventListener('load', preparePage, false);
}

/* Gets the specified user object from the session object */
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

/**
 * Adds a class that applies strikethrough to each user challenge that
 * the player already answered.
 */
function strikethroughAnsweredItems() {
    session = getSessionFromStorage();
    var items = document.getElementsByClassName("item");
    for(var i=0; i<items.length; i++) {
        if(getUserByID(items[i].id)) {
            items[i].className += " answered";
            console.log("In strikethroughAnsweredItems, item["+i+"].id:"+items[i].id);
        }
    }
}
