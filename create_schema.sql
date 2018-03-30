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
drop function if exists insert_grades(course varchar, term varchar, student_id varchar, grade integer);
drop function if exists enrolled_validations();
drop trigger if exists enrolled_validations_trigger on enrolled;
drop function if exists enrolled_check_capacity();
drop trigger if exists enrolled_check_capacity_trigger on enrolled;

-- create Student table --
create table students(
	s_id varchar(9) primary key,
	s_name varchar(255),
	check(length(s_name) <= 255)
	);

-- create faculty table --
create table faculty(
	f_id serial primary key,
	f_name varchar(255),
	check(length(f_name) >= 1)
	);

-- create Course table --
create table courses(
	course_code varchar(10) primary key,
	check(length(course_code) >= 1)
	);

-- create Offering table --
create table offering(
	course_code varchar(10), 
	term varchar(6),
	course_name varchar(128),
	max_cap integer,
	f_id integer,
	primary key (course_code, term),
	foreign key (f_id) references faculty(f_id),
	foreign key(course_code) references courses(course_code),
	check(length(course_name) >= 1),
	check(max_cap >= 0)
	);

-- create Prerequisites tables --
create table prereq(
	course_code varchar(10),
	term varchar(6),
	prereq varchar(10),
	primary key (course_code, term, prereq),
	foreign key (course_code, term) references offering(course_code, term),
	foreign key (prereq) references courses(course_code)
	);
	
-- create Prerequisites tables --
create table enrolled(
	s_id varchar(9),
	course_code varchar(10),
	term varchar(6),
	primary key (s_id, course_code, term),
	foreign key (course_code, term) references offering(course_code, term),
	foreign key (s_id) references students(s_id)
	);

-- create Grades table --
create table grades(
	s_id varchar(9),
	course_code varchar(10),
	term varchar(6),
	grade integer,
	primary key(s_id, course_code, term),
	foreign key (s_id) references students(s_id),
	foreign key (course_code, term) references offering(course_code, term),
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













--Enrolled insertion, not enough space
create or replace function enrolled_check_capacity()
returns trigger as
$BODY$
declare
	curr_capacity integer;
	max_capacity integer;
begin 
	select(select max_cap from offering
		where course_code = new.course_code and term = new.term)
	into max_capacity;

	select(select count(s_id) from offering natural join enrolled
			where course_code = new.course_code and term = new.term)
	into curr_capacity;

	if 
		curr_capacity < max_capacity
	then
--		raise notice 'Course insertion % capacity OK - %: CURR_CAP:% | MAX_CAP:%', new.course_code, new.s_id, curr_capacity, max_capacity;
		return new;
	else
		raise exception 'Course insertion % capacity exceeded - %: CURR_CAP:% | MAX_CAP:%', new.course_code, new.s_id, curr_capacity, max_capacity;

	end if;
return null;
end 
$BODY$
language plpgsql;

create trigger enrolled_check_capacity_trigger
	before insert on enrolled
	for each row
	execute procedure enrolled_check_capacity();

--****TODO: trigger for assigning grades when there is no enrolled

--*****Is there a way to avoid duplicating function for when additional argument prereq is given???
--insert_courses(): INCLUDING prerequisite argument--
create or replace function insert_courses(course_id varchar, course_name varchar, offering_term varchar, f_name varchar, max_cap integer, variadic prereq varchar[])
returns void as 
$BODY$
declare
	instructor_id integer;
	opts integer;
begin 
	insert into faculty(f_name)
		values($4);
	select faculty.f_id into instructor_id from faculty where faculty.f_name = $4;
--	raise notice 'Instructor insertion:%', instructor_id;
	insert into courses(course_code)
		values($1);
--	raise notice 'Course insertion:%', $1;
	insert into offering(course_code, course_name, term, f_id, max_cap)
		values($1, $2, $3, instructor_id, $5);
	select array_length($6,1) into opts;
--	raise notice 'optional args:%', opts;
	for i in 1 .. opts
		loop
--			raise notice 'variadic[%]:%', i, $6[i]; 
			insert into prereq(course_code, term, prereq)
				values($1, $3, $6[i] );
		end loop;
end 
$BODY$
language plpgsql;


--insert_coureses(): NO prerequsite argument--
create or replace function insert_courses(c_id varchar, c_name varchar, offering_term varchar, f_name varchar, max_cap integer)
returns void as 
$BODY$
declare
	instructor_id integer;
begin 
	insert into faculty(f_name)
		values($4);
	select faculty.f_id into instructor_id from faculty where faculty.f_name = $4;
--	raise notice 'Instructor insertion:%', instructor_id;
	insert into courses(course_code)
		values($1);
--	raise notice 'Course insertion:%', $1;

	insert into offering(course_code, course_name, term, f_id, max_cap)
		values($1, $2, $3, instructor_id, $5);
end 
$BODY$
language plpgsql;



--insert_add_drop()--
create or replace function insert_add_drop(cmd varchar, s_id varchar, s_name varchar, course varchar, term varchar)
returns void as
$BODY$
declare
	grade_assigned integer;
begin
	if 
		cmd = 'ADD'
	then
		insert into students(s_id, s_name)
			values(s_id, s_name);
		insert into enrolled(s_id, course_code, term)
			values($2, $4, $5);
	end if;
	if
		cmd = 'DROP'
	then
		select (select grade from enrolled natural join grades
					where enrolled.s_id = $2 and enrolled.course_code = $4 and enrolled.term = $5)
		into grade_assigned;
		if
			grade_assigned is not null
		then
			raise exception 'Cannot drop enrollment, grade[%] has been assigned to % - %', grade_assigned, $2, $4;
		else
--			raise notice 'Dropping enrollment: % - % - %:%', $2, $3, $4, $5;
			delete from enrolled where enrolled.s_id = $2 and enrolled.course_code = $4 and enrolled.term = $5;
		end if;
	end if;
end
$BODY$
language plpgsql;

--grades()--
create or replace function insert_grades(course varchar, term varchar, student_id varchar, grade integer)
returns void as
$BODY$
begin
	insert into grades(s_id, course_code, term, grade)
		values($3, $1, $2, $4);
end
$BODY$
language plpgsql;



--Enrolled insertion, 
create or replace function enrolled_validations()
returns trigger as
$BODY$
declare
	cp record;
	grade_assigned integer;
begin 
	if (select count(*)
			from enrolled
			where s_id = new.s_id and course_code = new.course_code and term = new.term) > 0
	then
		return null;
	end if;
	--no prerequisites--
	if (select count(*)
			from prereq
			where course_code = new.course_code and term = new.term) = 0
	then
--		raise notice 'No prerequisite %:% - %', new.course_code, new.term, new.s_id;
		return new;
	else
		for cp in select * from prereq
					where course_code = new.course_code and term = new.term
		loop
			raise notice'';
			raise notice 'LOOPING PREREQ wants:%:% preeq:% - %', cp.course_code, cp.term, cp.prereq, new.s_id;
			if (select count(*) from enrolled 
					where enrolled.s_id = new.s_id 
						and enrolled.course_code = cp.prereq
						and enrolled.term < new.term) > 0	
			then
				raise notice 'Mtf was enrolled, checking grade... prereq:% - %', cp.prereq, new.s_id;
				select (select grade from grades
							where grades.s_id = new.s_id 
								and grades.course_code = cp.prereq
								and grades.term < new.term)
				into grade_assigned;
				if
					grade_assigned is NULL or grade_assigned >= 50	
				then
					raise notice 'grade >= 50 or null - OK insert % - % - grade:%', cp.course_code, new.s_id, grade_assigned;
					return new;
				else
					raise notice 'grade assigned or < 50 - ABORT insert % - % - grade:%', cp.course_code, new.s_id, grade_assigned;
					return null;
				end if;

			else
				raise notice 'sad mtf doesnt have the :( % - %', cp.prereq, new.s_id;
				return null;
			end if;

		end loop;
	end if;
	

return new;
end 
$BODY$
language plpgsql;

create trigger enrolled_validations_trigger
	before insert on enrolled
	for each row
	execute procedure enrolled_validations();

select insert_courses('CSC 110','Fundamentals of Programming: I', '201709' ,'Jens Weber', '200');
select insert_courses('CSC 110','Fundamentals of Programming: I', '201801' ,'LillAnne Jackson', '150');
select insert_courses('CSC 115','Fundamentals of Programming: II', '201709', 'Tibor van Rooij', '100', 'CSC 110');
select insert_courses('CSC 115','Fundamentals of Programming: II', '201801', 'Mike Zastre', '100', 'CSC 110');
select insert_courses('MATH 122','Logic and Fundamentals', '201709', 'Gary McGillivray', '100');
select insert_courses('MATH 122','Logic and Fundamentals', '201801', 'Gary McGillivray', '100');
select insert_courses('CSC 225','Algorithms and Data Structures: I', '201805', 'Bill Bird', '100', 'CSC 115', 'MATH 122');


select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'CSC 110', '201709');
select insert_grades ('CSC 110', '201709', 'V00123456', '50');
select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'CSC 115', '201801');
select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'CSC 110', '201709');
select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'CSC 115', '201801');
select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'MATH 122', '201709');
select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'MATH 122', '201801');
select insert_add_drop ('ADD', 'V00123456', 'Alastair Avocado', 'CSC 225' ,'201805');
select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'CSC 225', '201805');
--select insert_add_drop ('DROP', 'V00123456', 'Alastair Avocado','CSC 110','201709');
--duplicate--
select insert_add_drop ('ADD', 'V00123457', 'Rebecca Raspberry', 'CSC 225', '201805');
--droping with grade assigned
--select insert_grades ('CSC 110', '201709', 'V00123456', '80');
--select insert_add_drop ('DROP', 'V00123456', 'Alastair Avocado','CSC 110','201709');


--select insert_grades ('CSC 110', '201709', 'V00123457', '80');
--select insert_grades ('MATH 122', '201709', 'V00123456', '67');
--select insert_grades ('CSC 225', '201805', 'V00123457', '75');
--select insert_grades ('CSC 225', '201805', 'V00123456', '79');
--select insert_grades ('CSC 115', '201801', 'V00123456', '83');
