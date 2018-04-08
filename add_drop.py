#!/usr/bin/env python3

# add_drop.py
# Daniel Olaya - 03/30/2018

import sys, csv, psycopg2

if len(sys.argv) < 2:
	print("Usage: %s <input file>",file=sys.stderr)
	sys.exit(0)
	
input_filename = sys.argv[1]

psql_user = 'olaya' 
psql_db = 'olaya' 
psql_password = 'V00855054' 
psql_server = 'studdb2.csc.uvic.ca'
psql_port = 5432

conn = psycopg2.connect(dbname=psql_db,user=psql_user,password=psql_password,host=psql_server,port=psql_port)

cursor = conn.cursor()

print("Opening add_drop input file...\n")
with open(input_filename) as f:
	for row in csv.reader(f):
		if len(row) == 0:
			continue #Ignore blank rows
		if len(row) != 5:
			print("Error: Invalid input line \"%s\""%(','.join(row)), file=sys.stderr)
			cursor.rollback()
			break
		add_or_drop,student_id,student_name,course_code,term = row
		cursor.execute("Select insert_add_drop (%s, %s, %s, %s, %s);", (add_or_drop,student_id,student_name,course_code,term))
		print(add_or_drop, student_id, student_name, course_code, term)

try:
 	
 	conn.commit() #Only commit if no error occurs (commit will actually be prevented if an error occurs anyway)
except psycopg2.ProgrammingError as err: 
 	#ProgrammingError is thrown when the database error is related to the format of the query (e.g. syntax error)
 	print("Caught a ProgrammingError:",file=sys.stderr)
 	print(err,file=sys.stderr)
 	conn.rollback()
except psycopg2.IntegrityError as err: 
# 	#IntegrityError occurs when a constraint (primary key, foreign key, check constraint or trigger constraint) is violated.
 	print("Caught an IntegrityError:",file=sys.stderr)
 	print(err,file=sys.stderr)
 	conn.rollback()
except psycopg2.InternalError as err:  
# 	#InternalError generally represents a legitimate connection error, but may occur in conjunction with user defined functions.
# 	#In particular, InternalError occurs if you attempt to continue using a cursor object after the transaction has been aborted.
# 	#(To reset the connection, run conn.rollback() and conn.reset(), then make a new cursor)
 	print("Caught an IntegrityError:",file=sys.stderr)
 	print(err,file=sys.stderr)
 	conn.rollback()
	
cursor.close()
conn.close()
		
		
