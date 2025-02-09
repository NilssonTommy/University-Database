
import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

    static final String DBNAME = "Tommy";
    static final String DATABASE = "jdbc:postgresql://localhost/"+DBNAME;
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";

    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    public String register(String student, String courseCode){
     
      try(PreparedStatement ps = conn.prepareStatement
          ("INSERT INTO Registrations(student, course) VALUES(?, ?)");){
        
        ps.setString(1, student);
        ps.setString(2, courseCode);
        ps.executeUpdate();
        
        return "{\"success\":true}";
              
    }catch (SQLException e){
 return "{\"success\":false, \"error\":\""+getError(e)+"\"}";

         }

  }
     

    //'; DROP TABLE Registered CASCADE; --
    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode){
    
   try (Statement s = conn.createStatement();){
          
    int rows = s.executeUpdate("DELETE FROM Registrations WHERE student = '" + student + "' AND course = '" + courseCode + "'");
/*
 try(PreparedStatement ps = conn.prepareStatement
      ("DELETE FROM Registrations WHERE student = ? AND course = ?");){

        ps.setString(1, student);
        ps.setString(2, courseCode);

        int rows = ps.executeUpdate();
*/

        if(rows == 0)
          return "{\"success\":false, \"error\":\"" + student + " and " + courseCode + " don't exist\"}";
        else
          return "{\"success\":true}";

    }catch(SQLException e){
  
      return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
    }
}
 
    public String getInfo(String student) throws SQLException{
        
        try(PreparedStatement st = conn.prepareStatement(
           "  SELECT jsonb_build_object(\n" +
  "'student', idnr, \n" +
  "'name', name, \n" +
  "'login', login, \n" +
  "'program', program, \n" +
  "'branch', branch, \n" +
  "'finished', (SELECT (jsonb_agg(jsonb_build_object( \n" +
  "            'course', coursename,  \n" +
  "            'code', course, \n" +
  "            'credits', credits, \n" +
  "            'grade', grade \n" +
  "             ))) FROM FinishedCourses WHERE student = BasicInformation.idnr), \n" +
  "'registered', (SELECT (jsonb_agg(jsonb_build_object( \n" +
  "            'course', (SELECT name FROM courses WHERE code = Registrations.course),  \n" +
  "            'code', course, \n" +
  "            'status', status, \n" +
  "            'position', (SELECT position FROM WaitingList WHERE student = BasicInformation.idnr AND status = 'waiting') \n" +
  "             ))) FROM Registrations WHERE student = BasicInformation.idnr), \n" +
  "'seminarCourses', seminarCourses, \n" +
  "'mathCredits', mathcredits, \n" +
  "'totalCredits', totalcredits, \n" +
  "'canGraduate', qualified \n" +
  ") as jsondata FROM BasicInformation LEFT JOIN PathToGraduation ON BasicInformation.idnr = PathToGraduation.student \n" +
  "    WHERE idnr = ?"            );){
            
            st.setString(1, student);
            
            ResultSet rs = st.executeQuery();
            
            if(rs.next())
              return rs.getString("jsondata");
            else
              return "{\"student\":\"does not exist :(\"}"; 
            
        } 
    }

    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}
