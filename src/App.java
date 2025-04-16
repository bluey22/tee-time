import java.sql.*;
import java.util.Scanner;

import utils.Credentials;

public class App {

    // Main()
    public static void main(String[] args) throws Exception {
        System.out.println("Welcome to the Tee-Time database! Please navigate by following the instructions below.");

        // Connection URL - set your credentials in utils/Credentials.java based on the template
        String connectionUrl = String.format(
            "jdbc:sqlserver://%s;" +
            "database=%s;" +
            "user=%s;" +
            "password=%s;" +
            "encrypt=true;" +
            "trustServerCertificate=true;" +
            "loginTimeout=15;",
            Credentials.SERVER_NAME,
            Credentials.DATABASE_NAME,
            Credentials.USER,
            Credentials.PASSWORD
        );

        try (Connection connection = DriverManager.getConnection(connectionUrl)) {
          
            Scanner scanner = new Scanner(System.in);

            while (true) {
                System.out.println("--------- Menu ---------");
                System.out.println("1. Join a Team");
                System.out.print("Enter your choice (input a number 1 through 6): ");

                int choice = scanner.nextInt();
                scanner.nextLine();
                switch (choice) {
                    case 1:
                        joinTeam(connection, scanner);
                        break;
                    default:
                        System.out.println("Invalid choice. Please try again.");
                        break;
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    // Use Case 1: Join a Team
    private static void joinTeam(Connection connection, Scanner scanner) {
        System.out.println("\n=== Join Team ===");
        String callStoredProc = "{? = call dbo.joinTeam(?,?,?,?)}";
        int inpPlayerId, inpTeamId;
        String inpJoinDate, inpPosition;

        // Prompt the user for information
        try {
            System.out.println("Enter the player id (as an integer), then press enter:");
            inpPlayerId = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter the team id (as an integer), then press enter:");
            inpTeamId = Integer.parseInt(scanner.nextLine().trim());

            System.out.print("Enter a join date (YYYY-MM-DD) or leave empty for today: ");
            inpJoinDate = scanner.nextLine().trim();
            if (!inpJoinDate.isEmpty()) {
                try {
                    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
                    dateFormat.setLenient(false);
                    dateFormat.parse(inpJoinDate);
                } catch (ParseException e) {
                    System.out.println("Invalid date format. Using today's date instead.");
                    inpJoinDate = "";
                }
            }

            System.out.print("Enter position (\"Captain\" or leave empty for \"Member\"): ");
            inpPosition = scanner.nextLine().trim();
        } catch (Exception e) {
            System.out.println("Invalid input given, please try again. Exiting...");
            return;
        }

        // Run stored procedure with input
        try (CallableStatement prepStoredProc = connection.prepareCall(callStoredProc)) {
            connection.setAutoCommit(false);
            
            // Set input parameters
            prepStoredProc.registerOutParameter(1, Types.INTEGER);
            prepStoredProc.setInt(2, inpPlayerId);
            prepStoredProc.setInt(3, inpTeamId);

            if (inpJoinDate.isEmpty()) {
                prepStoredProc.setNull(4, Types.DATE);
            } else {
                prepStoredProc.setString(4, inpJoinDate);
            }
            
            if (inpPosition.isEmpty()) {
                prepStoredProc.setNull(5, Types.VARCHAR);
            } else {
                prepStoredProc.setString(5, inpPosition);
            }

            
            // Execute the stored procedure
            prepStoredProc.execute();
            int returnValue = prepStoredProc.getInt(1);
            
            // Handle return value
            if (returnValue == -1) {
                System.out.println("Error: Operation failed. Team or Player may not exist, or there was a database error.");
                connection.rollback();
                return;
            }

            // Process result set
            ResultSet resultSet = prepStoredProc.getResultSet();
            if (resultSet != null) {
                if (resultSet.next()) {
                    System.out.println("\n=== Team Details ===");
                    System.out.println("Team ID: " + resultSet.getInt("team_id"));
                    System.out.println("Team Name: " + resultSet.getString("name"));
                    System.out.println("Creation Date: " + resultSet.getDate("creation_date"));
                    System.out.println("Home Facility ID: " + resultSet.getInt("home_facility_id"));
                    System.out.println("Facility Name: " + resultSet.getString("facility_name"));
                    System.out.println("\nPlayer successfully joined the team!");
                }
                resultSet.close();
            } else {
                System.out.println("No results returned from database.");
            }
            
            // Commit the transaction
            connection.commit();
        } catch (SQLException e) {
            try {
                connection.rollback();
            } catch (SQLException rollbackEx) {
                System.out.println("Error rolling back transaction: " + rollbackEx.getMessage());
            }
            System.out.println("Database error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
