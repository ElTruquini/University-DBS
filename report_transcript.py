#!/usr/bin/env python3
# report_transcript.py
# Daniel Olaya

import sys, csv, psycopg2

psql_user = 'olaya'
psql_db = 'olaya'
psql_password = 'V00855054'
psql_server = 'studdb2.csc.uvic.ca'
psql_port = 5432
conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)

cursor = conn.cursor()

def print_header(student_id, student_name):
	print("Transcript for %s (%s)"%(str(student_id), str(student_name)) )
	
def print_row(course_term, course_code, course_name, grade):
	if grade is not None:
		print("%6s %10s %-35s   GRADE: %s"%(str(course_term), str(course_code), str(course_name), str(grade)) )
	else:
		print("%6s %10s %-35s   (NO GRADE ASSIGNED)"%(str(course_term), str(course_code), str(course_name)) )

if len(sys.argv) < 2:
	print('Usage: %s <student id>'%sys.argv[0], file=sys.stderr)
	sys.exit(0)
	
student_id = sys.argv[1]

#Getting header information
cmd1 = "select s_name, s_id from students where s_id = '"
cmd2 = cmd1 + student_id
cmd_final = cmd2 + "'"
cursor.execute(cmd_final)
for record in cursor:
	student_name,_ = record
print (student_name, student_id)
print_header(student_id, student_name)

#Getting report content
cmd1 = "with x as (select term, course_code, course_name, s_id, s_name from students natural join enrolled natural join offering where s_id = '"
cmd2 = cmd1 + student_id
cmd_final = cmd2 + "')select x.term, x.course_code, x.course_name, x.s_id, grade from x left join grades on x.course_code = grades.course_code and x.s_id = grades.s_id and x.term = grades.term order by x.term, x.course_code;"
cursor.execute(cmd_final)

for record in cursor:
	term, course_code, course_name, _,grade = record
	print_row(term, course_code, course_name, grade)



#print_row(201709,'CSC 110','Fundamentals of Programming: I', 90)
#print_row(201709,'CSC 187','Recursive Algorithm Design', None) #The special value None is used to indicate that no grade is assigned.
#print_row(201801,'CSC 115','Fundamentals of Programming: II', 75)
