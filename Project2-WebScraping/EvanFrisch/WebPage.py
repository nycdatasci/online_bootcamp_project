from os import chdir
from os.path import expanduser
import os
import webbrowser

class WebPage:

    def __init__(self, script):
        # read in content of the template file
        self.set_html_template()
        # insert the script provided at the appropriate position
        self.set_part("{script}",script)

    def set_html_template(self, filename = 'GitHubProfile.html'):
        # get the path of the directory of this project
        path = os.path.dirname(os.path.realpath(__file__))
        text = open(path+"/"+filename)
        # read in the template file
        self.html = text.read()

    def set_part(self,old_location,new_div):
        # insert new content at a sepcified position in the template
        self.html = self.html.replace(old_location, new_div, 1)

    def show(self):
        # create temporary web page
        path = os.path.abspath('GitHubProfile.html')
        url = 'file://' + path
        with open(path, 'w') as f:
            f.write(self.html)
        # open temporary web page in web browser
        webbrowser.open(url)