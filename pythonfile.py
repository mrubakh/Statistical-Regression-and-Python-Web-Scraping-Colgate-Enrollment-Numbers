import requests
import urllib.request
import time
from bs4 import BeautifulSoup
import csv


dept_list = [] #This will contain all the department prefixes
term_list = ['201802','201801','201702','201701','201602','201601'] #Hard-coded for simplicity; we want a few years of data for comparison

##url = "http://www.colgate.edu/academics/courseofferings/results?term=201801&core=&distribution=&credits=&status=&dept=&before=22%3a30&after=07%3a00&level=&meets=M%3bT%3bW%3bR%3bF%3b&instructor=&firstYear="
url = "http://www.colgate.edu/academics/courseofferings"
outfile = open('C:\\Users\\vigor\\OneDrive\\Documents\\Sophomore Year\\data','a') #creates an output file
cf = csv.writer(outfile, lineterminator='\n')

response = requests.get(url) #retrieve the url
soup = BeautifulSoup(response.text, "html.parser") #create an instance of the BeautifulSoup object in order to parse the html code

thisTable = soup.find('table') #find the "table" will all of our deparements
cboxes = thisTable.findAll('input') #find all the checkboxes of the departments
for c in cboxes: # iterate through every department and get its "value"
    d = c.get('value')
    if d !=None:
        dept_list.append(d)
print(dept_list)

su1="http://www.colgate.edu/academics/courseofferings/results?term="
su2="&core=&distribution=&credits=&status=&dept="
su3="&before=22:30&after=07:00&level=&meets=M;T;W;R;F;&instructor=&firstYear="

cf.writerow(["Term","DeptCode","Class Name","Actual Enrollment", "Maximum Enrollment"]) #create the header for our output file

for term in term_list:
    for dept in dept_list:
        urlt = su1+term+su2+dept+su3
        thisPage = requests.get(urlt)
        pageSoup = BeautifulSoup(thisPage.text, "html.parser")
        for link in pageSoup.findAll('a'):
            if "/academics/coursedetails" in link.get("href"):
                thisClassLink = link.get("href")
                new_url = "http://www.colgate.edu" + thisClassLink
                response = requests.get(new_url)
                soup = BeautifulSoup(response.text, "html.parser")
                class_name= soup.find(id="lbCourseDetailHeading").string #find where the course name is located
                class_name= class_name[:class_name.find("\xa0")] + " " + class_name[class_name.find("\xa0")+3:] #use string splicing to get rid of some wacky symbols
                find_table = soup.findAll("div", {"class": "coursePad"})[1].table.find('table').div.findAll('table')[1] #locate where the enrollment numbers are
                total_row = len(find_table.findAll('tr'))-1 #find the index of the "total" row where our desired numbers are
                find_table_precise = find_table.findAll("tr")[total_row] #go to this index
                actual_enroll = find_table_precise.findAll('td')[3].string #obtain the actual enrollment
                max_enroll = find_table_precise.findAll('td')[2].string #obtain the max enrollment
                cf.writerow([term, dept, class_name, actual_enroll, max_enroll])
