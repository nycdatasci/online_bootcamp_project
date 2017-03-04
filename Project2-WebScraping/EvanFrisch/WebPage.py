import os
import sys
import webbrowser

class WebPage:
    """
    Creates a web page from a template and inserts the JavaScript
    needed to support graphs and other information to display on
    web page.
    """

    def __init__(self, script):
        """Create web page and insert script.

        script: JavaScript to insert into page
        """

        # read in content of the template file
        self.set_html_template()
        # insert the script provided at the appropriate position
        self.set_part("{script}",script)

    def set_html_template(self, filename = 'GitHubProfile.html'):
        """Read in html from template or exit if unavailable.

        filename: the name of the file containing the html template
        """
        try:
            # get the path of the directory of this project
            path = os.path.dirname(os.path.realpath(__file__))
            text = open(path+"/"+filename)
            # read in the template file
            self.html = text.read()
        except Exception as exc:
            print "Unable to read template from file."
            sys.exit()

    def set_part(self,old_location,new_div):
        """Replace a location in the template with a new div or other content.

        old_location: named location in template to replace with new content
        new_div:  new content to insert
        """
        # insert new content at a specified position in the template
        self.html = self.html.replace(old_location, new_div, 1)

    def show(self):
        """Display the web page. """
        # create temporary web page
        path = os.path.abspath('GitHubProfile.html')
        url = 'file://' + path
        with open(path, 'w') as f:
            f.write(self.html)
        # open temporary web page in web browser
        webbrowser.open(url)