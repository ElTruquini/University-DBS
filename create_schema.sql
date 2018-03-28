--Written by:Daniel Olaya Moran, V00855054


-- Issue a pre-emptive rollback (to discard the effect of any active transaction) --
rollback;


drop table if exists course cascade;
drop table if exists offering cascade;
drop table if exists prereq cascade;
drop table if exists grades cascade;
drop table if exists enrolled cascade;
drop table if exists people cascade;
drop table if exists students cascade;



-- create People table --
create table people(
	people_id serial primary key,
	name varchar(255),
	check(length(name) > 0)
	);


-- create Student table --
create table students(
	student_id varchar(9) primary key,
	people_id serial, 
	foreign key (people_id) references people(people_id)
		on delete restrict
		on update cascade
	);

-- create Course table --
create table course(
	course_code varchar(10) primary key
	);

-- create Offering table --
create table offering(
	offering_code varchar(10), 
	offering_term varchar(6),
	course_name varchar(128),
	max_cap integer,
	curr_cap integer,
	instructor_id integer,
	primary key (offering_code, offering_term),
	foreign key (instructor_id) references people(people_id)
		on delete restrict
		on update cascade,
	foreign key(offering_code) references course(course_code)
		on delete restrict
		on update cascade,

	check(length(course_name) >= 1),
	check(max_cap >= 0)
	);

-- create Prerequisites tables --
create table prereq(
	prereq_code varchar(10),
	prereq_term varchar(6),
	prereq varchar(10),
	primary key (prereq_code, prereq_term, prereq),
	foreign key (prereq_code, prereq_term) references offering(offering_code, offering_term)
		on delete restrict
		on update cascade,
	foreign key (prereq) references course(course_code)
		on delete restrict
		on update cascade
	);
	
-- create Prerequisites tables --
create table enrolled(
	enrolled_student varchar(9),
	enrolled_course varchar(10),
	enrolled_term varchar(6),
	primary key (enrolled_student, enrolled_course, enrolled_term),
	foreign key (enrolled_course, enrolled_term) references offering(offering_code, offering_term),
	foreign key (enrolled_student) references students(student_id)
	);

-- create Grades table --
create table grades(
	grade_student varchar(9),
	grade_course varchar(10),
	grade_term varchar(6),
	grade integer,
	primary key(grade_student, grade_course, grade_term),
	foreign key (xd)
	check (grade <= 100 and >= 0)
	);