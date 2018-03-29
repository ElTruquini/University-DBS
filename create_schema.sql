--Written by:Daniel Olaya Moran, V00855054

-- Issue a pre-emptive rollback (to discard the effect of any active transaction) --
rollback;

drop table if exists courses cascade;
drop table if exists offering cascade;
drop table if exists prereq cascade;
drop table if exists grades cascade;
drop table if exists enrolled cascade;
drop table if exists faculty cascade;
drop table if exists students cascade;
drop function if exists insert_add_drop(cmd varchar, s_id varchar, name varchar, course varchar, term varchar);
drop function if exists students_ignore_duplicates();
drop trigger if exists students_ignore_duplicates_trigger on students;
drop function if exists insert_courses(c_id varchar, c_name varchar, offering_term varchar, f_name varchar, max_cap integer, variadic prereq varchar[]);
drop function if exists insert_courses(c_id varchar, c_name varchar, offering_term varchar, f_name varchar, max_cap integer);
drop function if exists courses_ignore_duplicates();
drop trigger if exists courses_ignore_duplicates_trigger on courses;
drop function if exists faculty_ignore_duplicates();
drop trigger if exists faculty_ignore_duplicates_trigger on faculty;


-- create Student table --
create table students(
	s_id varchar(9) primary key,
	s_name varchar(255)
	);

-- create faculty table --
create table faculty(
	f_id serial primary key,
	f_name varchar(255)
	);


-- create Course table --
create table courses(
	course_code varchar(10) primary key,
	check(length(course_code) >= 1)
	);

-- create Offering table --
create table offering(
	of_ccode varchar(10), 
	of_term varchar(6),
	of_cname varchar(128),
	max_cap integer,
	of_instructor_id integer,
	primary key (of_ccode, of_term),
	foreign key (of_instructor_id) references faculty(f_id),
	foreign key(of_ccode) references courses(course_code),
	check(length(of_cname) >= 1),
	check(max_cap >= 0)
	);

-- create Prerequisites tables --
create table prereq(
	prereq_code varchar(10),
	prereq_term varchar(6),
	prereq varchar(10),
	primary key (prereq_code, prereq_term, prereq),
	foreign key (prereq_code, prereq_term) references offering(of_ccode, of_term),
	foreign key (prereq) references courses(course_code)

	);
	
-- create Prerequisites tables --
create table enrolled(
	enrolled_student varchar(9),
	enrolled_course varchar(10),
	enrolled_term varchar(6),
	primary key (enrolled_student, enrolled_course, enrolled_term),
	foreign key (enrolled_course, enrolled_term) references offering(of_ccode, of_term),
	foreign key (enrolled_student) references students(s_id)
	);

-- create Grades table --
create table grades(
	student varchar(9),
	course varchar(10),
	term varchar(6),
	grade integer,
	primary key(student, course, term),
	foreign key (student) references students(s_id),
	foreign key (course, term) references offering(of_ccode, of_term),
	check (grade <= 100 and grade >= 0)
	);



-- Students insertion, ignore duplicate --
create or replace function students_ignore_duplicates()
returns trigger as
$BODY$
begin 
	if(select count(*)
		from students
		where s_id = new.s_id) > 0
	then
		return null;
	end if;
return new;
end 
$BODY$
language plpgsql;

create trigger students_ignore_duplicates_trigger
	before insert on students
	for each row
	execute procedure students_ignore_duplicates();

--Course insertion, ignore duplicates
create or replace function courses_ignore_duplicates()
returns trigger as
$BODY$
begin 
	if (select count(*)
		from courses
		where course_code = new.course_code) > 0
	then
		return null;
	end if;
return new;
end 
$BODY$
language plpgsql;

create trigger courses_ignore_duplicates_trigger
	before insert on courses
	for each row
	execute procedure courses_ignore_duplicates();

--Faculty insertion, ignore duplicates
create or replace function faculty_ignore_duplicates()
returns trigger as
$BODY$
begin 
	if (select count(*)
		from faculty
		where f_name = new.f_name) > 0
	then
		return null;
	end if;
return new;
end 
$BODY$
language plpgsql;

create trigger faculty_ignore_duplicates_trigger
	before insert on faculty
	for each row
	execute procedure faculty_ignore_duplicates();



--*****Is there a way to avoid duplicating function for when additional argument prereq is given???
--insert_courses(): INCLUDING prerequisite argument--
create or replace function insert_courses(course_id varchar, course_name varchar, offering_term varchar, f_name varchar, max_cap integer, variadic prereq varchar[])
returns void as 
$BODY$
begin 
	insert into faculty(f_name)
		values($4); 
	insert into courses(course_code)
		values($1);
	insert into offering(of_ccode, of_cname, of_term)
		values($1, $2, $3);
end 
$BODY$
language plpgsql;


--insert_coureses(): NO prerequsite argument--
create or replace function insert_courses(c_id varchar, c_name varchar, offering_term varchar, f_name varchar, max_cap integer)
returns void as 
$BODY$
begin 
	insert into faculty(f_name)
		values($4);

	insert into courses(course_code)
		values($1);
	insert into offering(of_ccode, of_cname, of_term)
		values($1, $2, $3);

end 
$BODY$
language plpgsql;

--insert_add_drop()--
create or replace function insert_add_drop(cmd varchar, s_id varchar, s_name varchar, course varchar, term varchar)
returns void as
$BODY$
begin
	if cmd = 'ADD'
then
	insert into students(s_id, s_name)
		values(s_id, s_name);
end if;
end
$BODY$
language plpgsql;





select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'CSC 110', '201709');
--select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'CSC 115', '201801');
--select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'CSC 110', '201709');
--select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'CSC 115', '201801');
--select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'MATH 122', '201709');
--select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'MATH 122', '201801');
--select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'CSC 225' ,'201805');
--select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'CSC 225', '201805');
--select insert_add_drop ('DROP', 'V00123456', 'Alastair Avocado','CSC 110','201709');


select insert_courses('CSC 115','Fundamentals of Programming: II', '201801', 'Mike Zastre', '200', 'CSC 110');
select insert_courses('CSC 110','Fundamentals of Programming: I', '201709' ,'Jens Weber', '200');
select insert_courses('CSC 110','Fundamentals of Programming: I', '201801' ,'LillAnne Jackson', '150');
select insert_courses('CSC 115','Fundamentals of Programming: II', '201709', 'Tibor van Rooij', '100', 'CSC 110');
select insert_courses('MATH 122','Logic and Fundamentals', '201709', 'Gary McGillivray', '100');
select insert_courses('MATH 122','Logic and Fundamentals', '201801', 'Gary McGillivray', '100');
select insert_courses('CSC 225','Algorithms and Data Structures: I', '201805', 'Bill Bird', '100', 'CSC 115', 'MATH 122');











