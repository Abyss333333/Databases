/* 
 * This code is provided solely for the personal and private use of students 
 * taking the CSC343H course at the University of Toronto. Copying for purposes 
 * other than this use is expressly prohibited. All forms of distribution of 
 * this code, including but not limited to public repositories on GitHub, 
 * GitLab, Bitbucket, or any other online platform, whether as given or with 
 * any changes, are expressly prohibited. 
*/ 

import java.sql.*;
import java.util.Date;
import java.util.Arrays;
import java.util.List;

public class Assignment2 {
   /////////
   // DO NOT MODIFY THE VARIABLE NAMES BELOW.
   
   // A connection to the database
   Connection connection;

   // Can use if you wish: seat letters
   List<String> seatLetters = Arrays.asList("A", "B", "C", "D", "E", "F");

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to 'air_travel, public'.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
   public boolean connectDB(String URL, String username, String password) {
      // Implement this method!
    try{
      connection = DriverManager.getConnection(URL, username,password);
      String qS = "set search_path to air_travel,public";
      PreparedStatement bb = connection.prepareStatement(qS);
      bb.executeUpdate();
      return true;
    }
    catch (SQLException se)
            {
                System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
            }

      return false;
    }
   

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
   public boolean disconnectDB() {
      // Implement this method!

      try {
        connection.close();
        return true;
      }
      catch (SQLException se)
            {
                System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
            }

      return false;
   }
   
   /* ======================= Airline-related methods ======================= */

   /**
    * Attempts to book a flight for a passenger in a particular seat class. 
    * Does so by inserting a row into the Booking table.
    *
    * Read handout for information on how seats are booked.
    * Returns false if seat can't be booked, or if passenger or flight cannot be found.
    *
    * 
    * @param  passID     id of the passenger
    * @param  flightID   id of the flight
    * @param  seatClass  the class of the seat (economy, business, or first) 
    * @return            true if the booking was successful, false otherwise. 
    */
   public boolean bookSeat(int passID, int flightID, String seatClass) {
      
      try{
        PreparedStatement c, x, y,s,t;
        ResultSet cr, xr, yr,sr,tr;

        c = connection.prepareStatement(
          "select * from price where flight_id = ?");
        c.setInt(1, flightID);
        cr = c.executeQuery();

        x = connection.prepareStatement(
          "Select id, capacity_economy "
          +"from flight join plane on flight.plane = tail_number and id = ?");
        x.setInt(1, flightID);
        xr = x.executeQuery();

        s = connection.prepareStatement(
          "Select id, capacity_business "
          +"from flight join plane on flight.plane = tail_number and id = ?");
        s.setInt(1, flightID);
        sr = s.executeQuery();

        t = connection.prepareStatement(
          "Select id, capacity_first "
          +"from flight join plane on flight.plane = tail_number and id = ?");
        t.setInt(1, flightID);
        tr = t.executeQuery();

        y = connection.prepareStatement(
          "Select count(*) as count from Booking Where seat_class = ?::seat_class and "
          + "flight_id = ? ");
        y.setString(1,seatClass);
        y.setInt(2,flightID);
        yr = y.executeQuery();
       // System.out.println("HERE1");
        while (yr.next() && xr.next() && cr.next() && sr.next() && tr.next()){
          //System.out.println("HERE2");
          String cap;
          int check;
          int i = 0;
          int row = -1;
          int add = yr.getInt("count")/6;
          int maxSeat = yr.getInt("count") % 6;
          char letter = 'A';
          
          int n = 0;
          if (seatClass == "economy"){
            cap = "capacity_economy";
            int temp = xr.getInt(cap) - yr.getInt("count");
            check = temp;
            i = -10;
            if (temp > 0){
              row = tr.getInt("capacity_first")/6 + sr.getInt("capacity_business")/6 + 2;
              row = row + add;
            }
            else {
              n = 1;
            }

          }
          else if (seatClass == "business"){
            cap = "capacity_business";
            row = tr.getInt("capacity_first")/6 + 2 + add;
            check = sr.getInt(cap) - yr.getInt("count");
          }
          else {
            //System.out.println("HERE3");
            cap = "capacity_first";
            row = 1 + add;
            check = tr.getInt(cap) - yr.getInt("count");
          }

    
          int cost = cr.getInt(seatClass);
          
          if (check > i){
            PreparedStatement fin = connection.prepareStatement(
              "Insert Into booking "
              + "Values ((Select Max(id) from booking)+1, ?, ?, ?, ?, ?::seat_class, ?, ?) " );
            fin.setInt(1,passID);
            fin.setInt(2,flightID);
            fin.setTimestamp(3,getCurrentTimeStamp());
            fin.setInt(4, cost);
            fin.setString(5,seatClass);
            if (n == 1){
              fin.setNull(6, Types.NULL);
              fin.setNull(7, Types.NULL);
            }
            else {
              char input;
              if (maxSeat == 0){
                
                input = letter;
              }
              else{
                input = (char)(letter + maxSeat);
              }
              
              fin.setInt(6, row);
              fin.setString(7, input+" ");
              
             
            }
            fin.executeUpdate();
            //System.out.println("HERE7");
            return true;

          }
          return false;
      }
    }
      catch (SQLException se)
            {
                System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
                
            }

      return false;
   }

   /**
    * Attempts to upgrade overbooked economy passengers to business class
    * or first class (in that order until each seat class is filled).
    * Does so by altering the database records for the bookings such that the
    * seat and seat_class are updated if an upgrade can be processed.
    *
    * Upgrades should happen in order of earliest booking timestamp first.
    *
    * If economy passengers are left over without a seat (i.e. more than 10 overbooked passengers or not enough higher class seats), 
    * remove their bookings from the database.
    * 
    * @param  flightID  The flight to upgrade passengers in.
    * @return           the number of passengers upgraded, or -1 if an error occured.
    */
   public int upgrade(int flightID) {
      
      
    try{
      PreparedStatement  x,s,t, ee, bb, ff, n, del, upgrade;
      ResultSet xr,sr,tr, erow,brow,frow, nrow;

      String cape = "capacity_economy";
      String capb = "capacity_business";
      String capf = "capacity_first";
      x = connection.prepareStatement(
          "Select id, capacity_economy "
          +"from flight join plane on flight.plane = tail_number and id = ?");
      x.setInt(1, flightID);
      xr = x.executeQuery();

      s = connection.prepareStatement(
          "Select id, capacity_business "
          +"from flight join plane on flight.plane = tail_number and id = ?");
      s.setInt(1, flightID);
      sr = s.executeQuery();

      t = connection.prepareStatement(
          "Select id, capacity_first "
          +"from flight join plane on flight.plane = tail_number and id = ?");
      t.setInt(1, flightID);
      tr = t.executeQuery();

      ee = connection.prepareStatement(
        "Select count(*), max(row) as row "
        +"From Booking where flight_ID = ? and seat_class = 'economy'");
      ee.setInt(1,flightID);

      bb = connection.prepareStatement(
        "Select count(*), max(row) as row "
        +"From Booking where flight_ID = ? and seat_class = 'business'");
      bb.setInt(1,flightID);

      ff = connection.prepareStatement(
        "Select count(*), max(row) as row "
        +"From Booking where flight_ID = ? and seat_class = 'first'");
      ff.setInt(1,flightID);

      n = connection.prepareStatement(
        " Select id as nid from booking "
        +"where seat_class = ?::seat_class and row is NULL and letter is NULL "
        +"and flight_ID = ?");
      n.setString(1, "economy");
      n.setInt(2, flightID);


      erow = ee.executeQuery();
      brow = bb.executeQuery();
      frow = ff.executeQuery();
      

      

      while (erow.next() && brow.next() && frow.next() && xr.next()&& tr.next()&& sr.next() ){
        boolean check = erow.getInt("count") <= xr.getInt(cape);
        
        if (check){
          //System.out.println("here2");
          return 0;
        }
        else {
          int f_max = tr.getInt(capf) - frow.getInt("count");
          int b_max = sr.getInt(capb) - brow.getInt("count");

          int countb= 0;
          int countf= 0;
          int countrow =0;
          nrow = n.executeQuery();
          int row, seat;
          while (nrow.next() ){
            char letter = 'A';
            String placeholder;
            
            
            if (b_max > 0){
              placeholder = "business";
              
              b_max--;
              row = brow.getInt("row") +countrow;
              seat = (brow.getInt("count") + countb )% 6 ;
              countb++;
              
            }
            else if (f_max > 0){
              if (countf == 0){
                countrow = 0;
              }
              placeholder = "first";
              
              f_max--;
              row = frow.getInt("row") + countrow;
              seat = (frow.getInt("count") +countf)%6;
              countf++;

            }
            else {
              
              del = connection.prepareStatement(
                "delete from booking where id = ?");
              int rown = nrow.getInt("nid");
              del.setInt(1, rown);
              del.executeUpdate();
              continue;
            }
            int rown = nrow.getInt("nid");
            //System.out.println(rown);
            upgrade = connection.prepareStatement(
              "update booking set seat_class = ?::seat_class , row = ? , letter = ? "
              + "where id = ? ");
            //System.out.println("SEAT " + seat);

            if(seat == 0){
              row = row + 1;
              countrow ++;
            }
            else{
              //System.out.println("HERE7");
              letter = (char)(letter + seat);
            }

            upgrade.setString(1,placeholder);
            upgrade.setInt(2,row);
            upgrade.setString(3, letter+" ");
            upgrade.setInt(4, rown);
            //System.out.println(row);
            //System.out.println(upgrade);
            upgrade.executeUpdate();
            //System.out.println("here3");




          

          


        }
        return countb + countf;
      }

      
   }
}
   catch (SQLException se)
            {
                System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
                
            }

    return -1;
}

   /* ----------------------- Helper functions below  ------------------------- */

    // A helpful function for adding a timestamp to new bookings.
    // Example of setting a timestamp in a PreparedStatement:
    // ps.setTimestamp(1, getCurrentTimeStamp());

    /**
    * Returns a SQL Timestamp object of the current time.
    * 
    * @return           Timestamp of current time.
    */
   private java.sql.Timestamp getCurrentTimeStamp() {
      java.util.Date now = new java.util.Date();
      return new java.sql.Timestamp(now.getTime());
   }

   // Add more helper functions below if desired.


  
  /* ----------------------- Main method below  ------------------------- */

   public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      System.out.println("Running the code!");



      try{
          Assignment2 a2 = new Assignment2();
          String url = "jdbc:postgresql://localhost:5432/csc343h-siddi558";
          boolean c = a2.connectDB(url, "siddi558", "");
          

          int a = a2.upgrade(10);
          boolean aa = a2.bookSeat(3,3,"first");
          boolean as = a2.bookSeat(4,10,"economy");
          boolean ass = a2.bookSeat(4,10,"economy");
          boolean asss = a2.bookSeat(4,10,"economy");
          boolean assss = a2.bookSeat(4,10,"economy");
          boolean ad = a2.bookSeat(5,3,"business");
          System.out.println(a);
          if (a == -1){
            System.out.println("FIN");
          }
      }
      catch (SQLException se)
            {
                System.err.println("SQL Exception." +
                        "<Message>: " + se.getMessage());
            }
   }

}
