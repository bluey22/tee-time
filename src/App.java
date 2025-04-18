import java.sql.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
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
                System.out.println("5. Update match details");
                System.out.println("6. Update League Status");
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
                    case 5:
                        updateMatchResults(connection, scanner);
                        break;
                    case 6:
                        updateLeagueStatus(connection, scanner);
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
    //  - e.g., Add min woo lee (8) to to Drive Dynasty (3)
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

    // Use Case 2: Cancel Player Membership
    private static void cancelMembership(Connection connection, Scanner scanner) {
        System.out.println("\n=== Cancel Player Membership ===");
        String callStoredProc = "{call dbo.CancelPlayerMembership(?,?)}";
        int inpPlayerId, inpMembershipId;

        // Prompt the user for information
        try {
            System.out.println("Enter the player id (as an integer), then press enter:");
            inpPlayerId = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter the membership id (as an integer), then press enter:");
            inpMembershipId = Integer.parseInt(scanner.nextLine().trim());
        } catch (Exception e) {
            System.out.println("Invalid input given, please try again. Exiting...");
            return;
        }

        // Run stored procedure with input
        try (CallableStatement prepStoredProc = connection.prepareCall(callStoredProc)) {
            connection.setAutoCommit(false);

            // Set input parameters
            prepStoredProc.setInt(1, inpPlayerId);
            prepStoredProc.setInt(2, inpMembershipId);

            // Execute the stored procedure
            boolean hasResults = prepStoredProc.execute();
            System.out.println("Execute returned: " + hasResults);

            int updateCount = prepStoredProc.getUpdateCount();
            System.out.println("Update count: " + updateCount);

            // Then proceed with your existing result processing

            // Process potential result sets
            if (hasResults) {
                try (ResultSet rs = prepStoredProc.executeQuery()) {
                    if (rs.next()) {
                        System.out.println("\n=== Facility Details ===");
                        System.out.println("Facility ID:        " + rs.getInt("facility_id"));
                        System.out.println("Facility Name:      " + rs.getString("facility_name"));
                        System.out.println("Address:           " + rs.getString("address"));
                        System.out.println("City:              " + rs.getString("city"));
                        System.out.println("State:             " + rs.getString("state"));
                        System.out.println("ZIP:               " + rs.getString("zip"));
                        System.out.println("Phone:             " + rs.getString("phone"));
                        System.out.println("Website:           " + rs.getString("website"));
                        System.out.println("\nMembership #" + inpMembershipId + " for Player #" + inpPlayerId + " successfully cancelled!");
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



// Use Case 3 (with Completed‑status check)
private static void cancelMatchesAtFacility(Connection connection, Scanner scanner) {
    System.out.println("\n=== Cancel a Specific Match at a Facility ===");
    System.out.print("Enter the facility id (as an integer): ");
    int facilityId;
    try {
        facilityId = Integer.parseInt(scanner.nextLine().trim());
    } catch (NumberFormatException e) {
        System.out.println("Invalid facility id. Exiting...");
        return;
    }

    System.out.print("Enter the match id (as an integer): ");
    int matchId;
    try {
        matchId = Integer.parseInt(scanner.nextLine().trim());
    } catch (NumberFormatException e) {
        System.out.println("Invalid match id. Exiting...");
        return;
    }

    System.out.print("Enter reason for cancellation: ");
    String reason = scanner.nextLine().trim();

    String checkSql = 
        "SELECT status " +
        "  FROM game " +
        " WHERE game_id     = ? " +
        "   AND facility_id = ?";
    String updateSql = 
        "UPDATE game " +
        "   SET status = 'Cancelled' " +
        " WHERE facility_id = ? " +
        "   AND game_id     = ? " +
        "   AND status      = 'Scheduled'";
    String selectSql =
        "SELECT game_id, league_id, facility_id, date_time, status, game_type " +
        "  FROM game " +
        " WHERE game_id = ?";

    try {
        connection.setAutoCommit(false);

        // 1) Pre‑check: does the match exist, and what's its status?
        String currentStatus;
        try (PreparedStatement chk = connection.prepareStatement(checkSql)) {
            chk.setInt(1, matchId);
            chk.setInt(2, facilityId);
            try (ResultSet rs = chk.executeQuery()) {
                if (!rs.next()) {
                    System.out.println("No match found for facility " 
                        + facilityId + " with match ID " + matchId);
                    connection.rollback();
                    return;
                }
                currentStatus = rs.getString("status");
            }
        }

        // 2) If it's already completed, error out
        if ("Completed".equalsIgnoreCase(currentStatus)) {
            System.out.println("Cannot cancel: match #" + matchId 
                + " has already been completed.");
            connection.rollback();
            return;
        }

        // 3) Proceed only if it was Scheduled
        int affected;
        try (PreparedStatement upd = connection.prepareStatement(updateSql)) {
            upd.setInt(1, facilityId);
            upd.setInt(2, matchId);
            affected = upd.executeUpdate();
        }

        if (affected == 0) {
            // could happen if status was neither Scheduled nor Completed (e.g. already Cancelled)
            System.out.println("No scheduled match to cancel (status=" 
                + currentStatus + ").");
            connection.rollback();
            return;
        }

        // 4) Retrieve and display the now‑cancelled match
        try (PreparedStatement sel = connection.prepareStatement(selectSql)) {
            sel.setInt(1, matchId);
            try (ResultSet rs = sel.executeQuery()) {
                if (rs.next()) {
                    System.out.println("\n--- Cancelled Match Details ---");
                    System.out.println("Match ID:    " + rs.getInt("game_id"));
                    System.out.println("League ID:   " + rs.getInt("league_id"));
                    System.out.println("Facility ID: " + rs.getInt("facility_id"));
                    System.out.println("Date/Time:   " + rs.getTimestamp("date_time"));
                    System.out.println("Status:      " + rs.getString("status"));
                    System.out.println("Game Type:   " + rs.getString("game_type"));
                    System.out.println("Reason:      " + reason);
                } else {
                    System.out.println("Match record not found after cancellation.");
                }
            }
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
    // - e.g., Register everyone at Top Golf (1) to an Advanced league starting now, ending 2025-07-31, RR
    // - called "TopGolf (CLE) Only Summer League"
    private static void createFacilityLeague(Connection connection, Scanner scanner) {
        System.out.println("\n=== Create Facility League ===");
        String callStoredProc = "{call CreateFacilityLeague(?,?,?,?,?,?,?)}";
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

            System.out.print("Enter start date (YYYY-MM-DD) (Leave Empty for Today): ");
            startDate = scanner.nextLine().trim();
            try {
                SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
                dateFormat.setLenient(false);
                dateFormat.parse(startDate);
            } catch (ParseException e) {
                System.out.println("Empty or invalid date format. Proceeding with today's date");
                startDate = LocalDate.now().toString();
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
                        System.out.printf("%-30s", metaData.getColumnName(i));
                    }
                    System.out.println();

                    // Print separator
                    for (int i = 1; i <= columnCount; i++) {
                        System.out.print("------------------------------");
                    }
                    System.out.println();

                    // Print data rows
                    while (rs.next()) {
                        for (int i = 1; i <= columnCount; i++) {
                            System.out.printf("%-30s", rs.getString(i));
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

    // Use Case 9: Update Match Results
    private static void updateMatchResults(Connection connection, Scanner scanner) {
        System.out.println("\n=== Update Match Results ===");
        String callStoredProc = "{call dbo.UpdateMatchResults(?,?,?,?,?)}";
        int inpGameId, inpTeam1Id, inpTeam1Score, inpTeam2Id, inpTeam2Score;

        // Prompt the user for information
        try {
            System.out.println("Enter the game ID (as an integer), then press enter:");
            inpGameId = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter the first team ID (as an integer), then press enter:");
            inpTeam1Id = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter the first team's score (as an integer), then press enter:");
            inpTeam1Score = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter the second team ID (as an integer), then press enter:");
            inpTeam2Id = Integer.parseInt(scanner.nextLine().trim());

            System.out.println("Enter the second team's score (as an integer), then press enter:");
            inpTeam2Score = Integer.parseInt(scanner.nextLine().trim());
        } catch (Exception e) {
            System.out.println("Invalid input given, please try again. Exiting...");
            return;
        }

        // Run stored procedure with input
        try (CallableStatement prepStoredProc = connection.prepareCall(callStoredProc)) {
            connection.setAutoCommit(false);

            // Set input parameters
            prepStoredProc.setInt(1, inpGameId);
            prepStoredProc.setInt(2, inpTeam1Id);
            prepStoredProc.setInt(3, inpTeam1Score);
            prepStoredProc.setInt(4, inpTeam2Id);
            prepStoredProc.setInt(5, inpTeam2Score);

            // Execute the stored procedure
            boolean hasResults = prepStoredProc.execute();

            // Process potential result sets
            if (hasResults) {
                try (ResultSet rs = prepStoredProc.getResultSet()) {
                    if (rs.next()) {
                        System.out.println("\n=== Match Results Successfully Updated ===");
                        System.out.println("Game ID:            " + rs.getInt("game_id"));
                        System.out.println("League:             " + (rs.getString("league_name") != null ? rs.getString("league_name") : "N/A"));
                        System.out.println("Facility:           " + rs.getString("facility_name"));
                        System.out.println("Date/Time:          " + rs.getTimestamp("date_time"));
                        System.out.println("Status:             " + rs.getString("status"));
                        System.out.println("Game Type:          " + rs.getString("game_type"));
                        System.out.println("\n=== Results Summary ===");
                        System.out.println(rs.getString("team1_name") + ": " + rs.getInt("team1_score"));
                        System.out.println(rs.getString("team2_name") + ": " + rs.getInt("team2_score"));
                        System.out.println("Winner:             " + rs.getString("winner"));
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

    // Use Case 7: Update League Status (all‐status workflow)
// Use Case 7: Update League Status (with final team scores)
private static void updateLeagueStatus(Connection connection, Scanner scanner) {
    System.out.println("\n=== Update League Status ===");
    System.out.print("Enter League ID: ");
    int leagueId;
    try {
        leagueId = Integer.parseInt(scanner.nextLine().trim());
    } catch (NumberFormatException e) {
        System.out.println("Invalid League ID. Exiting...");
        return;
    }

    try {
        connection.setAutoCommit(false);

        // 1) Fetch current status + max_teams
        String fetchSql = "SELECT status, max_teams FROM league WHERE league_id = ?";
        String currentStatus;
        int maxTeams;
        try (PreparedStatement ps = connection.prepareStatement(fetchSql)) {
            ps.setInt(1, leagueId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    System.out.println("League not found.");
                    connection.rollback();
                    return;
                }
                currentStatus = rs.getString("status");
                maxTeams      = rs.getInt("max_teams");
            }
        }

        // 2) Decide next status
        String nextStatus;
        switch (currentStatus) {
            case "Setting Up":
                // only go In Season if all teams have joined
                int joinedCount;
                try (PreparedStatement ps = connection.prepareStatement(
                        "SELECT COUNT(*) FROM league_team WHERE league_id = ?")) {
                    ps.setInt(1, leagueId);
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        joinedCount = rs.getInt(1);
                    }
                }
                if (joinedCount < maxTeams) {
                    System.out.printf(
                      "Cannot move to In Season: %d of %d teams have joined.%n",
                      joinedCount, maxTeams
                    );
                    connection.rollback();
                    return;
                }
                nextStatus = "In Season";
                break;

            case "In Season":
                nextStatus = "Playoffs";
                break;

            case "Playoffs":
                nextStatus = "Completed";
                break;

            case "Paused":
                nextStatus = "In Season";
                break;

            case "Completed":
                System.out.println("League is already Completed; no further transition.");
                connection.rollback();
                return;

            default:
                System.out.println("Unknown status: " + currentStatus);
                connection.rollback();
                return;
        }

        // 3) Apply the status update
        try (PreparedStatement ps = connection.prepareStatement(
                "UPDATE league SET status = ? WHERE league_id = ?")) {
            ps.setString(1, nextStatus);
            ps.setInt(2,    leagueId);
            ps.executeUpdate();
        }

        // 4) Display the updated league row
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT league_id, name, city, state, zip, skill_level, status, start_date, end_date, max_teams "
              + "FROM league WHERE league_id = ?")) {
            ps.setInt(1, leagueId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    System.out.println("\n--- League Updated ---");
                    System.out.println("League ID:   " + rs.getInt("league_id"));
                    System.out.println("Name:        " + rs.getString("name"));
                    System.out.println("Location:    " 
                        + rs.getString("city") + ", " 
                        + rs.getString("state") + " " 
                        + rs.getString("zip"));
                    System.out.println("Skill Level: " + rs.getString("skill_level"));
                    System.out.println("Status:      " + rs.getString("status"));
                    System.out.println("Start Date:  " + rs.getDate("start_date"));
                    System.out.println("End Date:    " + rs.getDate("end_date"));
                    System.out.println("Max Teams:   " + rs.getInt("max_teams"));
                    System.out.printf("Transitioned from \"%s\" to \"%s\".%n",
                                      currentStatus, nextStatus);
                }
            }
        }

        // 5) If we've just moved to "Completed", show final team scores
        if ("Completed".equals(nextStatus)) {
            System.out.println("\n--- Final Standings (Total Points) ---");
            String standingsSql =
              "SELECT t.team_id, t.name AS team_name, "
            + "       ISNULL(SUM(gt.score),0) AS total_score "
            + "  FROM league_team lt "
            + "  JOIN team t ON lt.team_id = t.team_id "
            + "  LEFT JOIN game_team gt "
            + "    ON gt.team_id = t.team_id "
            + "   AND gt.game_id IN ("
            + "       SELECT game_id FROM game "
            + "        WHERE league_id = ? AND status = 'Completed'"
            + "     ) "
            + " WHERE lt.league_id = ? "
            + " GROUP BY t.team_id, t.name "
            + " ORDER BY total_score DESC";
            try (PreparedStatement ps = connection.prepareStatement(standingsSql)) {
                ps.setInt(1, leagueId);
                ps.setInt(2, leagueId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        System.out.printf("Team %-3d %-20s : %4d points%n",
                          rs.getInt("team_id"),
                          rs.getString("team_name"),
                          rs.getInt("total_score")
                        );
                    }
                }
            }
        }

        connection.commit();
    } catch (SQLException e) {
        System.out.println("Database error: " + e.getMessage());
        try {
            connection.rollback();
            System.out.println("Rolled back.");
        } catch (SQLException ex) {
            System.out.println("Rollback failed: " + ex.getMessage());
        }
    } finally {
        try {
            connection.setAutoCommit(true);
        } catch (SQLException e) {
            System.out.println("Couldn't reset auto-commit: " + e.getMessage());
        }
    }
}


    

}


