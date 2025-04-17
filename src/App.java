import java.sql.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
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
                System.out.println("2. Cancel a membership");
                System.out.println("3. Cancel Matches at a Facility");
                System.out.println("4. Create a Home League at a Facility (Adds all home teams)");
                System.out.print("Enter your choice (input a number 1 through 6): ");

                int choice = scanner.nextInt();
                scanner.nextLine();
                switch (choice) {
                    case 1:
                        joinTeam(connection, scanner);
                        break;
                    case 2:
                        cancelMembership(connection, scanner);
                        break;
                    case 3:
                        cancelMatchesAtFacility(connection, scanner);
                        break;
                    case 4:
                        createFacilityLeague(connection, scanner);
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
        String callStoredProc = "{call dbo.joinTeam(?,?,?,?)}";
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
            prepStoredProc.setInt(1, inpPlayerId);
            prepStoredProc.setInt(2, inpTeamId);

            if (inpJoinDate.isEmpty()) {
                prepStoredProc.setDate(3, null);
            } else {
                Date sqlDate = Date.valueOf(inpJoinDate);
                prepStoredProc.setDate(3, sqlDate);
            }

            if (inpPosition.isEmpty()) {
                prepStoredProc.setString(4, "Member");
            } else {
                prepStoredProc.setString(4, inpPosition);
            }

            // Execute the stored procedure
            boolean hasResults = prepStoredProc.execute();

            // Process potential result sets
            if (hasResults) {
                try (ResultSet rs = prepStoredProc.getResultSet()) {
                    if (rs.next()) {
                        System.out.println("\n=== Team Details ===");
                        System.out.println("Team ID:            " + rs.getInt("team_id"));
                        System.out.println("Team Name:          " + rs.getString("name"));
                        System.out.println("Creation Date:      " + rs.getDate("creation_date"));
                        System.out.println("Home Facility ID:   " + rs.getInt("home_facility_id"));
                        System.out.println("Facility Name:      " + rs.getString("facility_name"));
                        System.out.println("\nPlayer #"+ inpPlayerId+" successfully joined the team!");
                    } else {
                        System.out.println("No results returned.");
                    }
                }
            } else {
                System.out.println("No result set was returned.");
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

    // Use case 2:
    private static void cancelMembership(Connection connection, Scanner scanner) {
        try {
            // Start transaction
            connection.setAutoCommit(false);

            // Step 1: Prompt user for input
            System.out.print("Enter Player ID: ");
            int playerId = Integer.parseInt(scanner.nextLine());

            System.out.print("Enter Membership ID: ");
            int membershipId = Integer.parseInt(scanner.nextLine());

            // Step 2: Prepare and execute the stored procedure call
            String sql = "{call CancelPlayerMembership(?, ?)}";
            CallableStatement stmt = connection.prepareCall(sql);
            stmt.setInt(1, playerId);
            stmt.setInt(2, membershipId);

            boolean hasResultSet = stmt.execute();

            // Step 3: Display facility details if available
            if (hasResultSet) {
                ResultSet rs = stmt.getResultSet();
                if (!rs.isBeforeFirst()) {
                    System.out.println("No facility information found for the cancelled membership.");
                } else {
                    System.out.println("Membership cancelled successfully. Facility details:");
                    while (rs.next()) {
                        System.out.println("Facility ID: " + rs.getInt("facility_id"));
                        System.out.println("Name: " + rs.getString("facility_name"));
                        System.out.println("Address: " + rs.getString("address"));
                        System.out.println("City: " + rs.getString("city"));
                        System.out.println("State: " + rs.getString("state"));
                        System.out.println("ZIP: " + rs.getString("zip"));
                        System.out.println("Phone: " + rs.getString("phone"));
                        System.out.println("Website: " + rs.getString("website"));
                        System.out.println("-------------------------");
                    }
                }
                rs.close();
            } else {
                System.out.println("Membership cancelled, but no facility information was returned.");
            }

            // Step 4: Commit the transaction
            connection.commit();
            stmt.close();

        } catch (SQLException e) {
            System.out.println("Database error: " + e.getMessage());
            try {
                // Rollback if there was a failure
                if (connection != null) {
                    connection.rollback();
                    System.out.println("Transaction rolled back.");
                }
            } catch (SQLException rollbackEx) {
                System.out.println("Rollback failed: " + rollbackEx.getMessage());
            }
        } catch (NumberFormatException e) {
            System.out.println("Invalid input. Please enter valid numbers for IDs.");
            try {
                connection.rollback();
            } catch (SQLException rollbackEx) {
                System.out.println("Rollback failed: " + rollbackEx.getMessage());
            }
        } finally {
            try {
                // Restore default behavior
                connection.setAutoCommit(true);
            } catch (SQLException e) {
                System.out.println("Failed to reset auto-commit: " + e.getMessage());
            }
        }
    }

    // Use Case 3
    private static void cancelMatchesAtFacility(Connection connection, Scanner scanner) {
        System.out.println("\n=== Cancel Matches at a Facility ===");
        System.out.print("Enter the facility id (as an integer): ");
        int facilityId;
        try {
            facilityId = Integer.parseInt(scanner.nextLine().trim());
        } catch (NumberFormatException e) {
            System.out.println("Invalid facility id. Exiting...");
            return;
        }
    
        System.out.print("Enter reason for cancellation: ");
        String reason = scanner.nextLine().trim();
    
        String callProc = "{? = call dbo.CancelMatchesAtFacility(?, ?)}";
        try (CallableStatement stmt = connection.prepareCall(callProc)) {
            connection.setAutoCommit(false);
    
            // register and set parameters
            stmt.registerOutParameter(1, Types.INTEGER);
            stmt.setInt(2, facilityId);
            stmt.setString(3, reason);
    
            stmt.execute();
            int returnCode = stmt.getInt(1);
            if (returnCode == -1) {
                System.out.println("Error: Facility not found or database error.");
                connection.rollback();
                return;
            }
    
            // read and display the facility + reason
            ResultSet rs = stmt.getResultSet();
            if (rs != null && rs.next()) {
                System.out.println("\nFacility cancellation details:");
                System.out.println("Facility ID: " + rs.getInt("facility_id"));
                System.out.println("Name:        " + rs.getString("name"));
                System.out.println("Address:     " + rs.getString("address"));
                System.out.println("City:        " + rs.getString("city"));
                System.out.println("State:       " + rs.getString("state"));
                System.out.println("ZIP:         " + rs.getString("zip"));
                System.out.println("Phone:       " + rs.getString("phone"));
                System.out.println("Website:     " + rs.getString("website"));
                System.out.println("Reason:      " + rs.getString("cancellation_reason"));
                System.out.println("\nAll scheduled matches at this facility have been cancelled.");
            } else {
                System.out.println("No facility information returned.");
            }
    
            connection.commit();
        } catch (SQLException e) {
            System.out.println("Database error: " + e.getMessage());
            try {
                connection.rollback();
                System.out.println("Transaction rolled back.");
            } catch (SQLException ex) {
                System.out.println("Rollback failed: " + ex.getMessage());
            }
        } finally {
            try {
                connection.setAutoCommit(true);
            } catch (SQLException e) {
                System.out.println("Failed to reset auto-commit: " + e.getMessage());
            }
        }
    }
    
    // Use case 4:
    private static void createFacilityLeague(Connection connection, Scanner scanner) {
        System.out.println("\n=== Create Facility League ===");
        String callStoredProc = "{call RegisterTeamsFromFacilityToLeague(?,?,?,?,?,?,?)}";
        int facilityId;
        String leagueName, skillLevel, startDate, endDate, leagueFormat;
        int maxTeams;

        // 1. Prompt the user for information
        try {
            System.out.println("Enter the facility ID (as an integer), then press enter:");
            facilityId = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter the league name, then press enter:");
            leagueName = scanner.nextLine().trim();

            System.out.println("Enter skill level (Complete Beginner, Beginner, Intermediate, Advanced, Professional):");
            skillLevel = scanner.nextLine().trim();

            System.out.print("Enter start date (YYYY-MM-DD): ");
            startDate = scanner.nextLine().trim();
            try {
                SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
                dateFormat.setLenient(false);
                dateFormat.parse(startDate);
            } catch (ParseException e) {
                System.out.println("Invalid date format. Please try again.");
                return;
            }

            System.out.print("Enter end date (YYYY-MM-DD): ");
            endDate = scanner.nextLine().trim();
            try {
                SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
                dateFormat.setLenient(false);
                dateFormat.parse(endDate);
            } catch (ParseException e) {
                System.out.println("Invalid date format. Please try again.");
                return;
            }

            System.out.println("Enter maximum number of teams:");
            maxTeams = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter league format (Round Robin, Elimination, RR-E):");
            leagueFormat = scanner.nextLine().trim();
            
        } catch (Exception e) {
            System.out.println("Invalid input given, please try again. Exiting...");
            return;
        }

        // 2. Run stored procedure with input
        try (CallableStatement prepStoredProc = connection.prepareCall(callStoredProc)) {
            connection.setAutoCommit(false);

            // Set input parameters
            prepStoredProc.setInt(1, facilityId);
            prepStoredProc.setString(2, leagueName);
            prepStoredProc.setString(3, skillLevel);
            prepStoredProc.setDate(4, Date.valueOf(startDate));
            prepStoredProc.setDate(5, Date.valueOf(endDate));
            prepStoredProc.setInt(6, maxTeams);
            prepStoredProc.setString(7, leagueFormat);

            // Execute the stored procedure
            boolean hasResults = prepStoredProc.execute();

            // Process potential result sets
            while (hasResults) {
                try (ResultSet rs = prepStoredProc.getResultSet()) {
                    ResultSetMetaData metaData = rs.getMetaData();
                    int columnCount = metaData.getColumnCount();
                    
                    System.out.println("\n=== Teams Registered to the New League ===");
                    
                    // Print column headers
                    for (int i = 1; i <= columnCount; i++) {
                        System.out.printf("%-20s", metaData.getColumnName(i));
                    }
                    System.out.println();
                    
                    // Print separator
                    for (int i = 1; i <= columnCount; i++) {
                        System.out.print("--------------------");
                    }
                    System.out.println();
                    
                    // Print data rows
                    while (rs.next()) {
                        for (int i = 1; i <= columnCount; i++) {
                            System.out.printf("%-20s", rs.getString(i));
                        }
                        System.out.println();
                    }
                    
                    System.out.println("\nNew league created and teams registered successfully!");
                }
                
                hasResults = prepStoredProc.getMoreResults();
            }
    
            // 4. Commit the transaction
            connection.commit();

        } catch (SQLException e) {
            // 5. Handle Errors
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
