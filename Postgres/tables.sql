CREATE TABLE Programs(
name VARCHAR(50) NOT NULL PRIMARY KEY,
  abbreviation VARCHAR(50) NOT NULL
);

CREATE TABLE Departments(
  name VARCHAR(50) NOT NULL PRIMARY KEY,
 abbreviation VARCHAR(50) NOT NULL,
  UNIQUE(abbreviation)
);

CREATE TABLE Students(
  idnr CHAR(10) NOT NULL PRIMARY KEY CHECK(LENGTH(idnr) = 10),
  name VARCHAR(50) NOT NULL,
  login VARCHAR(50) NOT NULL,
  program VARCHAR(50) NOT NULL,
  UNIQUE(login),
  UNIQUE(idnr, program),
  FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE Branches(
  name VARCHAR(50) NOT NULL,
  program VARCHAR(50) NOT NULL,
  PRIMARY KEY(name,program),
  FOREIGN KEY (program) REFERENCES programs(name)
);

CREATE TABLE Courses( 
  code CHAR(6) NOT NULL PRIMARY KEY CHECK(LENGTH(code) = 6),
  name VARCHAR(50) NOT NULL,
  credits DOUBLE PRECISION NOT NULL CHECK(credits > 0),
  department VARCHAR(50) NOT NULL,
 FOREIGN KEY (department) REFERENCES Departments(name)
);

CREATE TABLE HostedBy(
  department VARCHAR(50) NOT NULL,
  program VARCHAR(50) NOT NULL,
  PRIMARY KEY(department, program),
 FOREIGN KEY (department) REFERENCES Departments(name),
 FOREIGN KEY (program) REFERENCES Programs(name)
);

CREATE TABLE LimitedCourses(
  code CHAR(6) NOT NULL PRIMARY KEY CHECK(LENGTH(code) = 6),
  capacity INT NOT NULL CHECK(capacity >  0),
  FOREIGN KEY (code) REFERENCES Courses(code)
);

CREATE TABLE Prerequisite(
  code VARCHAR(50) NOT NULL,
  pre VARCHAR(50) NOT NULL,
  PRIMARY KEY(code, pre),
  FOREIGN KEY (code) REFERENCES Courses(code),
 FOREIGN KEY (pre) REFERENCES Courses(code)
);


CREATE TABLE StudentBranches(
  student CHAR(10) NOT NULL PRIMARY KEY CHECK(LENGTH(student) = 10),
  branch VARCHAR(50) NOT NULL,
  program VARCHAR(50) NOT NULL,
  FOREIGN KEY (student, program) REFERENCES Students(idnr, program),
  FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);


CREATE TABLE Classifications(
  name VARCHAR(50) NOT NULL PRIMARY KEY
);

CREATE TABLE Classified(
  course CHAR(6) NOT NULL CHECK(LENGTH(course) = 6),
  classification VARCHAR(50) NOT NULL,
  PRIMARY KEY(course, classification),
  FOREIGN KEY (course) REFERENCES Courses(code),
  FOREIGN KEY (classification) REFERENCES Classifications(name)
);

CREATE TABLE MandatoryProgram(
  course CHAR(6) NOT NULL CHECK(LENGTH(course) = 6),
  program VARCHAR(50) NOT NULL,
  PRIMARY KEY(course, program),
  FOREIGN KEY (course) REFERENCES  Courses(code)
);

CREATE TABLE MandatoryBranch(
  course CHAR(6) NOT NULL CHECK(LENGTH(course) = 6),
  branch VARCHAR(50) NOT NULL,
  program VARCHAR(50) NOT NULL,
  PRIMARY KEY(course, branch, program),
  FOREIGN KEY(course) REFERENCES Courses(code),
  FOREIGN KEY(branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE RecommendedBranch(
  course CHAR(6) NOT NULL CHECK(LENGTH(course) = 6),
  branch VARCHAR(50) NOT NULL,
  program VARCHAR(50) NOT NULL,
  PRIMARY KEY(course, branch, program),
  FOREIGN KEY (course) REFERENCES Courses(code),
  FOREIGN KEY (branch, program) REFERENCES Branches(name, program)
);

CREATE TABLE Registered(
  student CHAR(10) NOT NULL CHECK(LENGTH(student) = 10),
  course  CHAR(6) NOT NULL CHECK(LENGTH(course) = 6),
  PRIMARY KEY(student, course),
  FOREIGN KEY (student) REFERENCES Students(idnr),
  FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE Taken(
  student CHAR(10) NOT NULL CHECK(LENGTH(student) = 10),
  course CHAR(6) NOT NULL CHECK(LENGTH(course) = 6),
  grade CHAR(1) NOT NULL CHECK(grade in ('U','3', '4', '5')),
  PRIMARY KEY(student, course),
  FOREIGN KEY (student) REFERENCES Students(idnr),
  FOREIGN KEY (course) REFERENCES Courses(code)
);

CREATE TABLE WaitingList(
  student CHAR(10) NOT NULL CHECK(LENGTH(student) = 10),
  course CHAR(6) NOT NULL CHECK (LENGTH(course) = 6),
  position INT NOT NULL CHECK (position > 0),
  PRIMARY KEY (student, course),
  UNIQUE(course, position),
  FOREIGN KEY (student) REFERENCES Students(idnr),
  FOREIGN KEY (course) REFERENCES Courses(code)
);





