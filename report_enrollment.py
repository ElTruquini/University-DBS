#!/usr/bin/env python3
# report_enrollment.py
# Daniel Olaya

import sys, csv, psycopg2

psql_user = 'olaya' 
psql_db = 'olaya' 
psql_password = 'V00855054' 
psql_server = 'studdb2.csc.uvic.ca'
psql_port = 5432
conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)
conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)

cursor = conn.cursor()

cursor.execute("with x as (select course_code, term, count(*) as curr_enrr from enrolled group by course_code, term), y as (select term, course_code, course_name, f_name, max_cap from offering natural join faculty), z as (select y.term, y.course_code, y.course_name, y.f_name, coalesce(x.curr_enrr, 0) as curr, y.max_cap from y left join x on y.term = x.term and y.course_code = x.course_code) select * from z order by z.term, z.course_code;")

for record in cursor:
	term, course_code, course_name, instructor_name, total_enrollment, maximum_capacity = record
	print("%6s %10s %-35s %-25s %s/%s"%(str(term), str(course_code), str(course_name), str(instructor_name), str(total_enrollment), str(maximum_capacity)) )


