'''
Created on Apr 25, 2017

@author: J.Kelley
'''
import requests
import time
import re
import urllib
import io
import logging
import os
import random
import csv
from datetime import datetime
from selenium import webdriver
from bs4 import BeautifulSoup
from copy import deepcopy


# Needed directories
saved_html_files_location = "/Users/intothelight/nycdatascience/tmp/data_dump/scraper_html_files"
processed_files_location = "/Users/intothelight/nycdatascience/tmp/data_dump/scraper_data_files"
log_files_location = "/Users/intothelight/nycdatascience/tmp/data_dump/scraper_log_files"
app_name = "html_processor"

# create needed directories
if not os.path.exists(log_files_location):
    os.makedirs(log_files_location)
    
if not os.path.exists(saved_html_files_location):
    os.makedirs(saved_html_files_location)

if not os.path.exists(processed_files_location):
    os.makedirs(processed_files_location)
    
# start logging
logfile = time.strftime("%Y-%m-%d")
full_logfilepath = "{}/{}__{}.log".format(log_files_location,logfile,app_name)
logging.basicConfig(filename=full_logfilepath, format="%(asctime)s - %(levelname)s: %(message)s", datefmt="%m/%d/%Y %I:%M:%S %p", level=logging.DEBUG)

logging.info("Begin logging")


urls_to_scan = {}
html_files_to_process = {}
final_csv_files = {}


def load_urls_to_scan():
    logging.debug("Enter:load_urls_to_scan")
    full_datafilepath = "{}/urls_to_scan.txt".format(processed_files_location)
    if os.path.isfile(full_datafilepath):
        with open(full_datafilepath,'r') as f:
            for line in f:
                new_url = line.strip()
                if new_url:
                    urls_to_scan[new_url] = new_url
        logging.debug("load_urls_to_scan: number of urls:%s", len(urls_to_scan.keys()))
        logging.debug("Exit:load_urls_to_scan")
        return
    else:
        site_for_urls = "https://moz.com/top500"
        logging.debug("File that contains urls not present:%s",full_datafilepath)
        logging.debug("Will attempt to scrape this website for urls:%s", site_for_urls)
        #Using session created in main program
        session.get(site_for_urls)
        time.sleep(5)
        text = session.page_source
        soup = BeautifulSoup(text,'html.parser')
        all_tags = soup.findAll("td", { "class" : "url" })
        logging.debug("Number of elements found:%s", len(all_tags))
        for tag in all_tags:
            value = tag.a["href"]
            urls_to_scan[value] = value
            logging.debug("url:%s", value)
        if len(urls_to_scan.keys()) > 0:
            save_urls_to_scan(urls_to_scan)
        logging.debug("load_urls_to_scan: number of urls:%s", len(urls_to_scan.keys()))
        logging.debug("Exit:load_urls_to_scan")
        return

def save_urls_to_scan(the_dict):
    logging.debug("Enter:save_urls_to_scan")
    full_datafilepath = "{}/urls_to_scan.txt".format(processed_files_location)
    the_urls = the_dict.keys()
    logging.debug("save_urls_to_scan: Will save %s urls to file", len(the_urls))
    urls_w_newlines = ('\n'.join(the_urls) + '\n')
    with open(full_datafilepath, "w") as f:
        f.writelines(urls_w_newlines)
    logging.debug("Exit:save_urls_to_scan")

def load_html_files_to_process():
    logging.debug("Enter:load_html_files_to_process")
    full_datafilepath = "{}/html_files_to_process.csv".format(processed_files_location)
    if os.path.isfile(full_datafilepath):
        with open(full_datafilepath,'r') as f:
            for line in f:
                currentline = line.strip().split(",")
                if currentline:
                    html_files_to_process[currentline[0]] = currentline[1]
        logging.debug("html_files_to_process.csv has %s files to process",len(html_files_to_process.keys()))
        logging.debug("Exit:load_html_files_to_process")
        return
    else:
        logging.debug("html_files_to_process.csv not present at:%s",full_datafilepath)


def save_html_file_to_process(the_html_dict):
    logging.debug("Enter:save_html_file_to_process")
    full_datafilepath = "{}/html_files_to_process.csv".format(processed_files_location)
    the_url = the_html_dict.keys() # should only be one
    logging.debug("save_html_file_to_process: going to this pair to file:%s,%s",the_url[0],the_html_dict[the_url[0]])
    pair = "{},{}\n".format(the_url[0],the_html_dict[the_url])
    with open(full_datafilepath, "a+") as f:
        f.writelines(pair)
    logging.debug("Exit:save_html_file_to_process")
    
    
def determine_files_already_processed():
    logging.debug("Enter:determine_files_already_processed")  
    # if the data csv file exists, dont need to redo/add redundant information
    #load csv file and remove urls already processed
    full_datafilepath = "{}/scanned_urls.csv".format(processed_files_location)
    if not os.path.isfile(full_datafilepath):
        logging.debug("determine_files_already_processed: no file exists to check")
        logging.debug("Exit:determine_files_already_processed")
        return
    with open(full_datafilepath, 'rb') as f:
        mycsv = csv.reader(f)
        for row in mycsv:
            logging.debug("determine_files_already_processed: will delete %s in processing queue if it exists", row[0])
            html_files_to_process.pop(row[0], None)  
    logging.debug("Exit:determine_files_already_processed")  

def check_url(url):
    response_code = ""
    try:
        response_code = requests.head(url)
    except requests.exceptions.ConnectionError as ex:
        logging.debug("check_url:Connection error:%s", ex)
        return False
    except requests.exceptions.RequestException as ex:
        logging.debug("check_url:Request error:%s", ex)
        return False
    return response_code.status_code < 400


scanner_primer_url = "http://urlquery.net/index.php"
scanner_report_url = "http://urlquery.net/report.php?id="
scanner_queued_url = "http://urlquery.net/queued.php?id="
website_url = "https://www.va.gov"

# PhantomJS needs location of binary on device
session = webdriver.PhantomJS(executable_path="/Users/intothelight/anaconda/pkgs/phantomjs-2.1.1-0/bin/phantomjs")
session.set_window_size(1439, 799)

# Load up new or in-progress files
load_urls_to_scan()    
load_html_files_to_process()


# BEGIN SCAN LOOP
still_scanning = True
skipped_urls = {}
all_urls = urls_to_scan.keys()
while still_scanning:
    
    if len(all_urls) == 0:
        logging.debug("No more urls to scan")
        still_scanning = False
        continue
    
    website_url = all_urls.pop()
    logging.info("Selected url to scan: %s", website_url)
    
    
    if check_url(scanner_primer_url):
        logging.debug("Scanner is up")
    else:
        logging.error("Scanner not available")
        still_scanning = False #but maybe we have html files to process
        continue
          
    # we can comment out this check if some urls have issues and just let
    #  the scanner timeout if need be (ie. my machine python requests module is having issues with ssl)      
    if check_url(website_url):
        logging.debug("Target site is up")
    else:
        logging.warn("Target site not available, skipping: %s", website_url)
        skipped_urls[website_url] = website_url
        continue    
         
      
    session.get(scanner_primer_url)
    url_box_id = "url"
    url_btn_id = "url-submit"
    url_text_box = session.find_element_by_id(url_box_id)
    url_text_box.send_keys(website_url)
    url_submit_btn = session.find_element_by_id(url_btn_id)
    url_submit_btn.click()
    html_ready_to_save = False
    waiting = True
    wait_time = 15
    report_status_id = "status"
    attempts_to_submit = 0
    while waiting:
      
        time.sleep(wait_time)
        logging.debug("Current browser url:%s", session.current_url)
        matchObj = re.search(r"report",session.current_url, re.M|re.I)
        matchQueObj = re.search(r"queued",session.current_url, re.M|re.I)
        if matchObj:
            logging.debug("Report url was matched")
            try:
                cell = session.find_element_by_id(report_status_id)
                logging.debug("Status element found in html")
                matchReportObj = re.search(r"Report complete",cell.text, re.M|re.I)
                if matchReportObj:
                    logging.debug("Report complete, matched")
                    waiting = False
                    html_ready_to_save = True
                  
            except Exception as ex:
                logging.warn("Exception:%s", ex)
                logging.debug("Current browser url:%s", session.current_url)
                skipped_urls[website_url] = website_url
                waiting = False
                html_ready_to_save = False
                  
        else:
            if matchQueObj:
                logging.debug("Scan is queued")
                continue
            else:
                attempts_to_submit = attempts_to_submit + 1
                if attempts_to_submit > 3:
                    logging.debug("Submit probably failed. Skipping. Current url:%s", session.current_url)
                    attempts_to_submit = 0
                    skipped_urls[website_url] = website_url
                    waiting = False
                    html_ready_to_save = False
                   
               
      
    if html_ready_to_save:
        filename = "{}__{}__{}".format(datetime.now(),website_url,session.current_url)
        filename = urllib.quote_plus(filename)
        full_filepath = "{}/{}.html".format(saved_html_files_location,filename)
        logging.debug("Going to save html source code here:%s",full_filepath ) 
        html_file = io.open(full_filepath, "w", encoding="utf8")
        html_file.write(session.page_source)
        html_file.close()
        html_files_to_process[website_url] = full_filepath
        new_pair = {website_url:full_filepath}
        save_html_file_to_process(new_pair)
        del urls_to_scan[website_url]
        new_set_to_scan = deepcopy(urls_to_scan)
        if len(skipped_urls.keys()) > 0:
            new_set_to_scan.update(skipped_urls)
        save_urls_to_scan(new_set_to_scan)
        
      
      
session.quit()
logging.debug("Quit session connection")

# END SCAN LOOP
# All urls should be scanned by this point
# now start processing html files



# html elements of interest

# BEGIN HTML FILE PROCESSING LOOP


fieldnames = ["Url", "IP.Address", "ASN", "IP.Location",
             "Report.Date", "UrlQuery.Alerts", "User.Agent",
             "Snort", "Suricata", "Fortinet", "MDL", "DNS.BH",
             "MS.DNS", "Openfish", "Phishtank", "Spamhaus",
             "JS.ES", "JS.EE", "JS.EW", "HTTP.Tranx"  ]

# open up csv file
full_datafilepath = "{}/scanned_urls.csv".format(processed_files_location)
csv_file = ""
writer = ""
if not os.path.isfile(full_datafilepath):
    csv_file = open(full_datafilepath, 'wb')
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
    writer.writeheader()
else:
    # lets make sure we don't re-process files
    determine_files_already_processed()
    csv_file = open(full_datafilepath, 'ab')
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)

while len(html_files_to_process.keys()) > 0:
    url_key = random.choice(html_files_to_process.keys())
    logging.info("Selected key for processing: %s", url_key)

    scanned_filename = html_files_to_process[url_key]
    logging.info("Actual file to process: %s", scanned_filename)

    the_file = open(scanned_filename, "r")
    file_contents = the_file.read()
    webpage = BeautifulSoup(file_contents,'html.parser')

  

    # data of interest: must be same as fieldnames above
    observation = {"Url":url_key, "IP.Address":"NA", "ASN":"NA", "IP.Location":"NA",
                   "Report.Date":"NA", "UrlQuery.Alerts":0, "User.Agent":"NA",
                   "Snort":0, "Suricata":0, "Fortinet":0, "MDL":0, "DNS.BH":0,
                   "MS.DNS":0, "Openfish":0, "Phishtank":0, "Spamhaus":0,
                   "JS.ES":0, "JS.EE":0, "JS.EW":0, "HTTP.Tranx":0  }
    url_of_website = url_key
    
    # we'll cycle through all the page sections
    all_h2_elements = webpage.findAll('h2')
    for tag in all_h2_elements:
        section_text = tag.get_text()
        if section_text == "Overview":
            logging.debug("Overview h2 element found")
            table_element = tag.findNextSibling('table')
            all_cells = table_element.tbody.findAll("td")
            logging.debug("total number of <td> cells:%s", len(all_cells))
            logging.debug("URL=%s", all_cells[1].contents[0].strip())
            observation["IP.Address"] = all_cells[4].contents[0].strip()
            observation["ASN"] = all_cells[6].contents[0].strip()
            observation["IP.Location"] = all_cells[8].contents[0]['title']
            observation["Report.Date"] = all_cells[10].contents[0].strip()
            logging.debug("IP=%s", observation["IP.Address"])
            logging.debug("ASN=%s", observation["ASN"])
            logging.debug("IP Location=%s", observation["IP.Location"])
            logging.debug("Report Completed Date=%s", observation["Report.Date"])
            logging.debug("Report Status=%s", all_cells[12].contents[0].contents[0])
            has_table = all_cells[14].find("table")
            if has_table:
                observation["UrlQuery.Alerts"] = 1
            else:
                observation["UrlQuery.Alerts"] = 0
            
            logging.debug("urlQuery Alerts=%s", observation["UrlQuery.Alerts"])
            i = 0
            for cell in all_cells:
                logging.debug("cell content:%s, index=%s",cell.contents[0], i)
                i = i + 1
            
        elif section_text == "Settings":
            logging.debug("Settings h2 element found")  
            table_element = tag.findNextSibling('table')
            all_cells = table_element.tbody.findAll("td")
            logging.debug("total number of <td> cells:%s", len(all_cells))
            i = 0
            for cell in all_cells:
                if not cell.contents:
                    value = "NA"
                else:
                    value = cell.contents[0]    
                logging.debug("cell content:%s, index=%s",value, i)
                i = i + 1
                
            observation["User.Agent"] = all_cells[1].contents[0].strip()    
            logging.debug("User Agent=%s", observation["User.Agent"]) 
           
        elif section_text == "Intrusion Detection Systems":
            logging.debug("Intrusion Detection Systems h2 element found")  
            table_element = tag.findNextSibling('table')
            
            row = table_element.tbody.tr
            has_table = row.find("table")
            if has_table:
                observation["Snort"] = 1
            else:
                observation["Snort"] = 0
                
            row = row.findNextSibling("tr")
            has_table = row.find("table")
            if has_table:
                observation["Suricata"] = 1
            else:
                observation["Suricata"] = 0  
            
            logging.debug("Snort=%s", observation["Snort"])
            logging.debug("Suricata=%s", observation["Suricata"])   
                 
        elif section_text == "Blacklists":
            logging.debug("Blacklists h2 element found")
            table_element = tag.findNextSibling('table')
        
            row = table_element.tbody.tr
            has_table = row.find("table")
            if has_table:
                observation["Fortinet"] = 1
            else:
                observation["Fortinet"] = 0
                
            row = row.findNextSibling("tr")
            has_table = row.find("table")
            if has_table:
                observation["MDL"] = 1
            else:
                observation["MDL"] = 0
                
            row = row.findNextSibling("tr")
            has_table = row.find("table")
            if has_table:
                observation["DNS.BH"] = 1
            else:
                observation["DNS.BH"] = 0
                
            row = row.findNextSibling("tr")
            has_table = row.find("table")
            if has_table:
                observation["MS.DNS"] = 1
            else:
                observation["MS.DNS"] = 0
                
            row = row.findNextSibling("tr")
            has_table = row.find("table")
            if has_table:
                observation["Openfish"] = 1
            else:
                observation["Openfish"] = 0
                
            row = row.findNextSibling("tr")
            has_table = row.find("table")
            if has_table:
                observation["Phishtank"] = 1
            else:
                observation["Phishtank"] = 0
                
            row = row.findNextSibling("tr")
            has_table = row.find("table")
            if has_table:
                observation["Spamhaus"] = 1
            else:
                observation["Spamhaus"] = 0
                    
            logging.debug("Fortinet=%s", observation["Fortinet"])  
            logging.debug("MDL=%s", observation["MDL"])  
            logging.debug("DNS_BH=%s", observation["DNS.BH"]) 
            logging.debug("MS_DNS=%s", observation["MS.DNS"])
            logging.debug("OpenPhish=%s", observation["Openfish"])
            logging.debug("PhishTank=%s", observation["Phishtank"])
            logging.debug("Spamhaus=%s", observation["Spamhaus"])    
        
        elif section_text == "JavaScript":
            logging.debug("JavaScript h2 element found")
            next_h3_tags = webpage.findAll("h3", text=re.compile("Executed"))
            logging.debug("total number of <h3> cells:%s", len(next_h3_tags))
            i = 0
            for cell in next_h3_tags:
                if not cell.contents:
                    value = "NA"
                else:
                    value = cell.contents[0]    
                logging.debug("cell content:%s, index=%s",value, i)
                i = i + 1
        
            num_of_tranx = "0"
            searchObj = re.search( r'(\d+)', next_h3_tags[0].contents[0], re.M|re.I)
            if searchObj:
                logging.debug("js executed scripts tranx search found:%s", searchObj.group())
                num_of_tranx = searchObj.group()
            observation["JS.ES"] = int(num_of_tranx)
            logging.debug("JS_ES=%s", observation["JS.ES"])
        
            num_of_tranx = "0"
            searchObj = re.search( r'(\d+)', next_h3_tags[1].contents[0], re.M|re.I)
            if searchObj:
                logging.debug("js executed evals tranx search found:%s", searchObj.group())
                num_of_tranx = searchObj.group()
            observation["JS.EE"] = int(num_of_tranx)
            logging.debug("JS_EE=%s", observation["JS.EE"])
        
            num_of_tranx = "0"
            searchObj = re.search( r'(\d+)', next_h3_tags[2].contents[0], re.M|re.I)
            if searchObj:
                logging.debug("js executed writes tranx search found:%s", searchObj.group())
                num_of_tranx = searchObj.group()
            observation["JS.EW"] = int(num_of_tranx)
            logging.debug("JS_EW=%s", observation["JS.EW"])
        
        elif section_text.startswith("HTTP Transactions"):
            logging.debug("HTTP Transactions h2 element found: %s", section_text)
            num_of_tranx = "0"
            searchObj = re.search( r'(\d+)', section_text, re.M|re.I)
            if searchObj:
                logging.debug("http tranx search found:%s", searchObj.group())
                num_of_tranx = searchObj.group()
            observation["HTTP.Tranx"] = int(num_of_tranx)
            logging.debug("HTTP Tranx=%s", observation["HTTP.Tranx"])    
        
        else:
            logging.debug("Ignoring this h2 element: %s", section_text)            

    
    # write observation to file
    writer.writerow(observation)
    logging.debug("Wrote dictionary to cvs file: %s", observation)
    del html_files_to_process[url_key]
    logging.debug("Deleted processed url: %s", url_key)
    # END WHILE LOOP

 

csv_file.close()

logging.info("Program complete.")


