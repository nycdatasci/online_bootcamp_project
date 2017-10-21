from flask import Flask
from flask import render_template, abort, request, redirect, url_for, json
import requests
from flask_bootstrap import Bootstrap
from flask_nav import Nav
from flask_nav.elements import Navbar, View, Subgroup
import boto3

app = Flask(__name__)
app.config.from_object(__name__)


Bootstrap(app)
nav = Nav()

s3 = boto3.resource('s3')
bucket_name = 'so_predict'

@app.context_processor
def inject_app_name():
    """Supplies the application name to templates."""
    return dict(app_name="Stack Overlord")


questions_data = {}
users_data = {}
questions_quantiles = {}
users_quantiles = {}


@app.route("/")
def index():
    """Renders the application home page."""
    tagline = "Compete against predictive models of the Stack Overflow data set."
    return render_template('index.html', tagline_name=tagline)

@app.route("/compete")
def compete():
    """Renders the template that presents and enables the selection of a game play mode."""
    return render_template('/compete.html')

def setQuestionsData():
    """Reads data describing Stack Overflow questions from an AWS S3 bucket into a dictionary."""
    print("Starting setQuestionsData()")
    obj = s3.Object(bucket_name,'questions_qf.json')
    data = json.loads(obj.get()['Body'].read())

    for q in data:
        questions_data[str(q['question_id'])] = { 'question_id': q['question_id'],
                                       'question_title': q['question_title'],
                                       'question_score': q['question_score'],
                                       'question_favorited': q['question_favorited'],
                                       'prediction_lr': q['predict_lr'],
                                       'prediction_rf': q['predict_rf'],
                                       'prediction_gbm': q['predict_gbm'],
                                       'question_body_length': q['question_body_length'],
                                       'question_codeblock_count': q['question_codeblock_count'],
                                       'question_comment_count': q['question_comment_count'],
                                       'answer_count': q['answer_count'],
                                       'question_view_count': q['question_view_count'],
                                       'question_tags': q['question_tags'] }


def setUsersData():
    """Reads data describing Stack Overflow users from an AWS S3 bucket into a dictionary."""
    print("Starting setUsersData()")
    obj = s3.Object(bucket_name,'users_rq.json')
    data = json.loads(obj.get()['Body'].read())

    for u in data:
        users_data[str(u['user_id'])] = { 'user_id': u['user_id'],
                                       'user_display_name': u['user_display_name'],
                                       'questions_count': u['questions_count'],
                                       'answers_count': u['answers_count'],
                                       'comments_count': u['comments_count'],
                                       'prediction': u['predict'],
                                       'user_reputation_quantile' : u['user_reputation_quantile'],
                                       'questions_total_score': u['questions_total_score'],
                                       'answers_total_score': u['answers_total_score'],
                                       'comments_total_score': u['comments_total_score'],
                                       'user_profile_image_url': 'static/user.png' if u['user_profile_image_url'] == None else u['user_profile_image_url'] }


def setQuestionsQuantiles():
    """Reads data about Stack Overflow questions by quantile from an AWS S3 bucket into a dictionary."""
    print("Starting setQuestionsQuantiles()")
    obj = s3.Object(bucket_name,'questions_quantiles.json')
    global questions_quantiles
    questions_quantiles = json.loads(obj.get()['Body'].read().decode())
    print("questions_quantiles: {}".format(questions_quantiles))

def setUsersQuantiles():
    """Reads data about Stack Overflow users by quantile from an AWS S3 bucket into a dictionary."""
    print("Starting setUsersQuantiles()")
    obj = s3.Object(bucket_name,'users_quantiles.json')
    global users_quantiles
    users_quantiles = json.loads(obj.get()['Body'].read().decode())
    print("users_quantiles: {}".format(users_quantiles))

def filterQuestionsByTag(tag):
    """Produce a dictionary containing all questions that match the specified tag.
    :param tag: the tag to use to filter questions
    :returns: the dictionary containing all questions that contain the tag in their question_tags field
    """
    questions_with_tag = { k: v for k, v in questions_data.items() if tag in v['question_tags'].split('|') }
    print("In filterQuestionsByTag({}), questions_with_tag={}".format(tag,questions_with_tag))
    return questions_with_tag

@app.route("/questions/")
@app.route("/questions/<tag>")
def questions(tag=None):
    """Renders a template listing questions, which are limited to those that match the specified tag, if it is not None.
    :param tag: the tag to use to filter questions
    """
    print("At start of questions({})".format(tag))
    if(len(questions_data) == 0):
        setQuestionsData()

    if(len(questions_quantiles) == 0):
        setQuestionsQuantiles()

    if(tag == None):
        return render_template('/questions.html', questions=questions_data, questions_json=questions_data, tag='')
    else:
        questions_with_tag_data = filterQuestionsByTag(tag)
        return render_template('/questions.html', questions=questions_with_tag_data, questions_json=questions_with_tag_data, tag=tag)


@app.route("/question/<question_id>")
def question(question_id):
    """Renders a template presenting one Stack Overflow question corresponding to the specified question ID.
    :param question_id: the question ID of the question information to display in the template
    """
    print("At start of question({})".format(question_id))
    if(len(questions_data) == 0):
        setQuestionsData()

    if(len(questions_quantiles) == 0):
        setQuestionsQuantiles()

    print("len(questions_data): {}".format(len(questions_data)))
    print("len(questions_quantiles): {}".format(len(questions_quantiles)))
    if(question_id not in questions_data):
        abort(404)
    return render_template('/question.html',
                           question=questions_data[question_id], quantiles=questions_quantiles)

@app.route("/next_question/<question_id>/")
@app.route("/next_question/<question_id>/<tag>")
def next_question(question_id,tag=None):
    """Renders a template presenting one Stack Overflow question that is subsequent to the specified question ID.
    :param question_id: the question ID that immediately precedes the question to display in the template
    """
    if(len(questions_data) == 0):
        setQuestionsData()

    if(len(questions_quantiles) == 0):
        setQuestionsQuantiles()

    print("len(questions_data): {}".format(len(questions_data)))

    if(question_id not in questions_data):
        not_found(404,"In next_question, question_id {} not in questions_data {}".format(question_id, questions_data))
        abort(404)

    if(tag == None):
        keyList = sorted(questions_data.keys())
        questions_data_temp = questions_data
    else:
        questions_data_temp = filterQuestionsByTag(tag)
        keyList = sorted(questions_data_temp.keys())

    print("question_id: {}".format(question_id))
    print("len(keyList): {}".format(len(keyList)))

    if(keyList.index(question_id)+1 < len(keyList)):
       return render_template('question.html',
                              question=questions_data_temp[keyList[keyList.index(question_id)+1]],
                              tag=tag,
                              quantiles=questions_quantiles)
    else:
       return render_template('/questions.html', questions=questions_data_temp, questions_json = questions_data_temp, tag = tag)

@app.route("/users")
def users():
    """Renders a template listing users."""
    if(len(users_data) == 0):
        setUsersData()

    if(len(users_quantiles) == 0):
        setUsersQuantiles()

    return render_template('/users.html', users=users_data, users_json = users_data)

@app.route("/user/<user_id>")
def user(user_id):
    """Renders a template presenting one Stack Overflow user corresponding to the specified user ID.
    :param user_id: the user ID of the user information to display in the template
    """
    if(len(users_data) == 0):
        setUsersData()

    if(len(users_quantiles) == 0):
        setUsersQuantiles()

    print("Started user({})".format(user_id))
    print("len(users_data): {}".format(len(users_data)))
    if(user_id not in users_data):
        users()
    return render_template('/user.html',
                           user=users_data[user_id],
                           quantiles=users_quantiles)

@app.route("/next_user/<user_id>")
def next_user(user_id):
    """Renders a template presenting one Stack Overflow user that is subsequent to the specified user ID.
    :param user_id: the user ID that immediately precedes the user to display in the template
    """
    if(len(users_data) == 0):
        setUsersData()

    print("len(users_data): {}".format(len(users_data)))

    if(len(users_quantiles) == 0):
        setUsersQuantiles()

    if(user_id not in users_data):
        not_found(404,"In next_user, user_id {} not in users_data {}".format(user_id, users_data))
        abort(404)

    print("len(sorted(users_data.keys())): {}".format(len(sorted(users_data.keys()))))

    keyList = sorted(users_data.keys())
    if(user_id not in keyList):
        not_found(404,"In next_user, user_id {} not in keyList {}".format(user_id, keyList))
        abort(404)

    print("user_id: {}".format(user_id))
    print("len(keyList): {}".format(len(keyList)))
    current_user_index = keyList.index(user_id)
    next_user_index = current_user_index + 1
    next_user_id = keyList[next_user_index]

    return render_template('/user.html', user=users_data[next_user_id], quantiles=users_quantiles)

@app.route("/about-stack-overflow")
def about_stack_overflow():
    """Renders a template presenting static information about the Stack Overflow website."""
    return render_template('/about-stack-overflow.html')

@app.route("/about-project")
def about_project():
    """Renders a template presenting static information about this project."""
    return render_template('/about-project.html')


@app.errorhandler(404)
def not_found(error,description=""):
    """Renders a custom 404 Not Found error page with the description specified, if any.
    :param description: the description to display in the 404 Not Found error template (Default value = '')
    """
    return render_template('404.html', description=description), 404

@nav.navigation()
def sitenavbar():
    """Generates site navigation."""
    return Navbar(
      'Stack Overlord',
      View('Home', 'index'),
      Subgroup('Compete',
          View('Overview', 'compete'),
          View('Questions', 'questions', tag=''),
          View('Users', 'users')
      ),
      Subgroup('About',
          View('This Project', 'about_project'),
          View('Stack Overflow', 'about_stack_overflow')
      )
    )


if(__name__ == "__main__"):
    app.run()

nav.init_app(app)
