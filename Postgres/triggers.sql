CREATE FUNCTION Insert_function()
RETURNS trigger AS 
$$ 
DECLARE
    maxCapacity INT;
    totalStudents INT;

BEGIN

    IF EXISTS (
        SELECT * 
        FROM Taken 
        WHERE student = NEW.student
        AND course = NEW.course 
        AND grade <> 'U')
        THEN
        RAISE EXCEPTION 'The student has already passed this course';
    
    ELSIF EXISTS (
        SELECT * 
        FROM Registered 
        WHERE student = NEW.student
        AND course = NEW.course)
        THEN
        RAISE EXCEPTION 'The student is already registered for this course';

    ELSIF (EXISTS (
        SELECT * 
        FROM WaitingList 
        WHERE student = NEW.student
        AND course = NEW.course))
        THEN
        RAISE EXCEPTION 'The student is already in the WaitingList for this course';

    ELSIF EXISTS (
        SELECT *
        FROM Prerequisite
        WHERE code = NEW.Course
        AND NOT EXISTS (
            SELECT *
            FROM Taken
            WHERE student = NEW.student
            AND course = Prerequisite.pre
            AND grade <> 'U'))
        THEN RAISE EXCEPTION 'The student does not have the required prerequisites to take this course.';

    ELSE
        IF EXISTS (
            SELECT *
            FROM WaitingList
            WHERE course = NEW.course)
            THEN
            INSERT INTO WaitingList VALUES(
                NEW.student, 
                NEW.course, 
                (SELECT MAX(position) + 1
                    FROM WaitingList
                    WHERE course = NEW.course)
                    );
                /* Om det finns en student i WaitingList för den specifika kursen så läggs raden i WaitingList. */

        ELSE
            SELECT capacity
                INTO maxCapacity
                FROM LimitedCourses
                WHERE code = NEW.course;

            SELECT COUNT(*)
                INTO totalStudents
                FROM Registered
                WHERE course = NEW.course;

            IF( (totalStudents < maxCapacity) OR (maxCapacity IS NULL) OR (totalStudents IS NULL) ) THEN
                INSERT INTO Registered VALUES(
                    NEW.student,
                    NEW.course
                );
                /* Om det finns plats i kursen så läggs raden till i registered. */

            ELSE
                INSERT INTO WaitingList VALUES(
                    NEW.student, 
                    NEW.course, 
                    (SELECT COALESCE(MAX(position), 0) + 1
                        FROM WaitingList
                        WHERE course = NEW.course)
                    );
                /* Annars så läggs raden till i WaitingList. */

            END IF;
        END IF;
    END IF;
    RETURN NEW;    
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER Insert_trigger
    INSTEAD OF INSERT ON Registrations
    FOR EACH ROW EXECUTE PROCEDURE Insert_function();





/* Delete operation */

CREATE FUNCTION Delete_function()
RETURNS trigger AS 
$$ 
DECLARE
    maxCapacity INT;
    totalStudents INT;

BEGIN

    IF (NOT EXISTS (
        SELECT * 
        FROM Registered 
        WHERE student = OLD.student
        AND course = OLD.course))
        AND
        (NOT EXISTS (
        SELECT * 
        FROM WaitingList 
        WHERE student = OLD.student
        AND course = OLD.course))
        THEN
        RAISE EXCEPTION 'The student is not registered or in the WaitingList for this course';
  
ELSIF EXISTS ( /* Om studenten finns i registered */
        SELECT * 
        FROM Registered 
        WHERE student = OLD.student
        AND course = OLD.course)
        THEN

        DELETE FROM Registered /* Ta bort studenten från registered */
            WHERE student = OLD.student 
            AND course = OLD.course;

        SELECT capacity
                INTO maxCapacity 
                FROM LimitedCourses
                WHERE code = OLD.course;

        SELECT COUNT(*)
            INTO totalStudents
            FROM Registered
            WHERE course = OLD.course;

        IF((totalStudents < maxCapacity) OR (totalStudents IS NULL) /* Om det finns plats i Registered efter att man har raderat */
            AND 
            EXISTS(
            SELECT * 
            FROM WaitingList
            WHERE student = OLD.student
            AND course = OLD.course))
            THEN

            INSERT INTO Registered (student, course) /* Insert studenten som har position 1 för kursen i WaitingList */
                SELECT student, course
                FROM WaitingList
                WHERE course = OLD.course
                AND position = 1;

            DELETE FROM WaitingList /* Ta bort studenten från WaitingList */
                WHERE course = OLD.course
                AND position = 1;

        END IF;

    ELSE /* Annars (Om studenten inte finns i registered) */

        DELETE FROM WaitingList /* Ta bort studenten från WaitingList */
            WHERE course = OLD.course
            AND student = OLD.student;

    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER Delete_trigger
    INSTEAD OF DELETE ON Registrations
    FOR EACH ROW EXECUTE PROCEDURE Delete_function();


/* Trigger när man tar bort från WaitingList */

CREATE FUNCTION compact()
    RETURNS trigger AS $$
BEGIN
    UPDATE WaitingList SET position = position - 1
        WHERE course = OLD.course AND position > OLD.position;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER waiting_deleted
    AFTER DELETE
    ON WaitingList
    FOR EACH ROW
    EXECUTE PROCEDURE compact();
