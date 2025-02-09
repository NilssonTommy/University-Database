
CREATE VIEW BasicInformation AS
SELECT Students.idnr, Students.name, Students.login, 
         Students.program, StudentBranches.branch 
FROM Students LEFT JOIN StudentBranches 
ON Students.idnr = StudentBranches.student;

CREATE VIEW FinishedCourses AS
SELECT Taken.student, Taken.course, Courses.name AS courseName, 
          Taken.grade, Courses.credits
FROM Taken LEFT JOIN Courses
ON Taken.course = Courses.code;

CREATE VIEW Registrations AS
SELECT WaitingList.student, WaitingList.course, 'waiting' AS status
FROM WaitingList
UNION
SELECT Registered.student, Registered.course, 'registered' AS status
FROM Registered
WHERE NOT EXISTS(
SELECT * FROM WaitingList 
WHERE WaitingList.student = Registered.student AND 
      WaitingList.course = Registered.course);

CREATE VIEW PassedCourses AS
SELECT Taken.student, Taken.course, Courses.credits
FROM Taken JOIN Courses ON Taken.course = Courses.code
WHERE Taken.grade IN ('3','4','5');


CREATE VIEW UnreadMandatory AS
WITH
AllMandatoryProgramCourses AS (
SELECT Students.idnr AS student, MandatoryProgram.course
FROM Students
LEFT JOIN MandatoryProgram ON Students.program = MandatoryProgram.program
),
AllMandatoryBranchCourses AS (
 SELECT StudentBranches.student, MandatoryBranch.course
FROM StudentBranches
LEFT JOIN MandatoryBranch ON StudentBranches.branch = MandatoryBranch.branch
                          AND StudentBranches.program = MandatoryBranch.program
),
AllMandatoryCourses AS (
SELECT student, course
FROM AllMandatoryProgramCourses
UNION
SELECT student, course
FROM AllMandatoryBranchCourses
)
SELECT AllMandatoryCourses.student, AllMandatoryCourses.course
FROM AllMandatoryCourses LEFT JOIN PassedCourses
ON AllMandatoryCourses.student = PassedCourses.student AND AllMandatoryCourses.course = PassedCourses.course
WHERE PassedCourses.course IS NULL
      AND AllMandatoryCourses.course IS NOT NULL;

CREATE VIEW RecommendedCourses AS
SELECT PassedCourses.student, PassedCourses.course, PassedCourses.Credits
FROM PassedCourses JOIN RecommendedBranch
ON PassedCourses.course = RecommendedBranch.course 
JOIN StudentBranches ON PassedCourses.student =  StudentBranches.student
WHERE StudentBranches.branch = RecommendedBranch.branch AND
      StudentBranches.program = RecommendedBranch.program;


CREATE VIEW PathToGraduation AS
WITH
TotalCredits AS (
SELECT student, SUM(credits) AS totalCredits
FROM PassedCourses
GROUP BY student
),
MandatoryLeft AS (
SELECT student, COUNT(course) AS mandatoryLeft
FROM UnreadMandatory
GROUP BY student
),
MathCredits AS(
SELECT PassedCourses.student, SUM(PassedCourses.credits) AS mathCredits
FROM PassedCourses
JOIN Classified ON PassedCourses.course = Classified.course
  WHERE Classified.classification = 'math'
  GROUP BY PassedCourses.student
),
SeminarCourses AS (
SELECT PassedCourses.student, COUNT(*) AS seminarCourses
FROM PassedCourses
JOIN Classified ON PassedCourses.course = Classified.course
WHERE Classified.classification = 'seminar'
GROUP BY PassedCourses.student
)
SELECT 
  Students.idnr AS student,
  COALESCE(TotalCredits.totalCredits, 0) AS totalCredits,
  COALESCE(MandatoryLeft.mandatoryLeft, 0) AS mandatoryLeft,
  COALESCE(MathCredits.mathCredits, 0) AS mathCredits,
  COALESCE(SeminarCourses.seminarCourses, 0) AS seminarCourses,
 (
COALESCE(MandatoryLeft.mandatoryLeft, 0) = 0
AND COALESCE(MathCredits.mathCredits, 0) >= 20
AND COALESCE(SeminarCourses.seminarCourses, 0 ) >= 1 
AND (
SELECT COALESCE(SUM(PassedCourses.credits), 0)
FROM PassedCourses JOIN RecommendedBranch 
ON PassedCourses.course = RecommendedBranch.course
JOIN StudentBranches ON PassedCourses.student = StudentBranches.student
WHERE RecommendedBranch.branch = StudentBranches.branch
AND RecommendedBranch.program = StudentBranches.program
AND PassedCourses.student = Students.idnr ) >= 10 
) AS qualified
FROM Students
LEFT JOIN TotalCredits ON Students.idnr = TotalCredits.student
LEFT JOIN MandatoryLeft ON Students.idnr = MandatoryLeft.student
LEFT JOIN MathCredits ON Students.idnr = MathCredits.student
LEFT JOIN SeminarCourses ON Students.idnr = SeminarCourses.student;






