#!/usr/bin/env python3
# report_classlist.py
# Daniel Olaya

import sys, csv, psycopg2

psql_user = 'olaya'
psql_db = 'olaya'
psql_password = 'V00855054'
psql_server = 'studdb2.csc.uvic.ca'
psql_port = 5432
conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)

cursor = conn.cursor()

def print_header(course_code, course_name, term, instructor_name):
	print("Class list for %s (%s)"%(str(course_code), str(course_name)) )
	print("  Term %s"%(str(term), ) )
	print("  Instructor: %s"%(str(instructor_name), ) )
	
def print_row(student_id, student_name, grade):
	if grade is not None:
		print("%10s %-25s   GRADE: %s"%(str(student_id), str(student_name), str(grade)) )
	else:
		print("%10s %-25s"%(str(student_id), str(student_name),) )

def print_footer(total_enrolled, max_capacity):
	print("%s/%s students enrolled"%(str(total_enrolled),str(max_capacity)) )


if len(sys.argv) < 3:
	print('Usage: %s <course code> <term>'%sys.argv[0], file=sys.stderr)
	sys.exit(0)
	
course_code, term = sys.argv[1:3]

#Getting general report variables for header and footer
cmd1 = "select term, course_code, course_name, f_name, count(*) as curr_enrr, max_cap from enrolled natural join students natural join offering natural join faculty where course_code = '"
cmd2 = cmd1 + course_code
cmd3 = cmd2 + "' and term = '"
cmd4 = cmd3 + term
cmd_final = cmd4 + "' group by max_cap, f_name, term, course_name, course_code;"

#Getting header infomarion
cursor.execute(cmd_final)
for record in cursor:
	course_term, course_code, course_name, instructor_name, enrolled, capacity = record
print_header(course_code, course_name, course_term, instructor_name)

#Print student list
cmd1 = "select enrolled.s_id, s_name, grade, enrolled.term, enrolled.course_code from enrolled natural join students left join grades on enrolled.s_id = grades.s_id and enrolled.term = grades.term and enrolled.course_code = grades.course_code where enrolled.course_code = '"
cmd2 = cmd1 + course_code
cmd3 = cmd2 + "' and enrolled.term = '"
cmd4 = cmd3 + term
cmd_final = cmd4 + "' order by enrolled.s_id;"
cursor.execute(cmd_final)
for record in cursor:
	student_id, student_name, grade, _, _ = record
	print_row(student_id, student_name, grade)

#Print the last line (enrollment/max_capacity)
print_footer(enrolled,capacity)
