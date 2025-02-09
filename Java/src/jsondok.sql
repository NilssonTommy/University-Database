SELECT jsonb_build_object(
  'student', idnr,
  'name', name,
  'login', login,
  'program', program,
  'branch', branch,
  'finished', (SELECT (jsonb_agg(jsonb_build_object(
              'course', coursename, 
              'code', course,
              'credits', credits,
              'grade', grade
               ))) FROM FinishedCourses WHERE student = BasicInformation.idnr),
  'registered', (SELECT (jsonb_agg(jsonb_build_object(
              'course', (SELECT name FROM courses WHERE code = Registrations.course), 
              'code', course,
              'status', status,
              'position', (SELECT position FROM WaitingList WHERE student = BasicInformation.idnr AND status ='waiting')
               ))) FROM Registrations WHERE student = BasicInformation.idnr),
  'seminarCourses', seminarCourses,
  'mathCredits', mathcredits,
  'totalCredits', totalcredits,
  'canGraduate', qualified
  )FROM BasicInformation LEFT JOIN PathToGraduation ON BasicInformation.idnr = PathToGraduation.student;


