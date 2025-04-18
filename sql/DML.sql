-- For procedures, functions, triggers, and views

-- ------------------------------ Use Case 1: Player Joins a Team ------------------------------------------
-- DML: select, insert
-- tables: team, team_player, facility
-- @ben
CREATE OR ALTER PROCEDURE joinTeam
    @player_id INT,
    @team_id INT,
    @join_date DATE = NULL,
    @position VARCHAR(20) = 'Member'
    AS
BEGIN
    SET NOCOUNT ON;

    -- Choose today if no join date is specified
    IF @join_date IS NULL
        SET @join_date = GETDATE();

    -- Check if the team exists
    IF NOT EXISTS (SELECT 1 FROM team WHERE team_id = @team_id)
        RAISERROR('Team does not exist', 16, 1);

    -- Check if the player exists
ELSE IF NOT EXISTS (SELECT 1 FROM player WHERE player_id = @player_id)
        RAISERROR('Player does not exist', 16, 1);

    -- Check if the player is already on the team
ELSE IF EXISTS (SELECT 1 FROM team_player WHERE player_id = @player_id AND team_id = @team_id)
        RAISERROR('Player is already on this team', 16, 1);

ELSE
BEGIN
BEGIN TRY
BEGIN TRANSACTION;

INSERT INTO team_player (player_id, team_id, join_date, position)
VALUES (@player_id, @team_id, @join_date, @position);

COMMIT TRANSACTION;

-- Return the team details
SELECT
    t.team_id,
    t.name,
    t.creation_date,
    t.home_facility_id,
    CASE
        WHEN t.home_facility_id IS NULL THEN 'No home facility'
        ELSE f.name
        END AS facility_name
FROM team t
         LEFT JOIN facility f on t.home_facility_id = f.facility_id
WHERE t.team_id = @team_id;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;
END CATCH;
END;
END;
GO

-- -------------------- Use Case 2: Cancelling a player membership ------------------------------
CREATE PROCEDURE CancelPlayerMembership
    @player_id INT,
    @membership_id INT
AS
BEGIN
    -- Step 1: Update payment status to 'Cancelled'
UPDATE player_membership
SET payment_status = 'Cancelled'
WHERE player_id = @player_id AND membership_id = @membership_id;

-- Step 2: Select related facility details for the cancelled membership
SELECT
    f.facility_id,
    f.name AS facility_name,
    f.address,
    f.city,
    f.state,
    f.zip,
    f.phone,
    f.website
FROM facility f
         JOIN membership m ON f.facility_id = m.facility_id
WHERE m.membership_id = @membership_id;
END;
GO

-- --------------------- Use Case 3: Match Cancellation (Case #13 in doc2) --------------------------------
CREATE OR ALTER PROCEDURE CancelMatchesAtFacility
    @facility_id    INT,
    @reason         VARCHAR(500)
    AS
BEGIN
    SET NOCOUNT ON;
BEGIN TRANSACTION;

    -- 1. Ensure the facility exists
    IF NOT EXISTS (SELECT 1 FROM facility WHERE facility_id = @facility_id)
BEGIN
ROLLBACK TRANSACTION;
RETURN -1;
END;

BEGIN TRY
        -- 2. Cancel all scheduled matches at this facility
UPDATE game
SET status = 'Cancelled'
WHERE facility_id = @facility_id
  AND status = 'Scheduled';

-- 3. Return facility details + the reason
SELECT
    f.facility_id,
    f.name,
    f.address,
    f.city,
    f.[state],
    f.zip,
    f.phone,
    f.website,
    @reason AS cancellation_reason
FROM facility f
WHERE f.facility_id = @facility_id;

COMMIT TRANSACTION;
RETURN 0;
END TRY
BEGIN CATCH
ROLLBACK TRANSACTION;
RETURN -1;
END CATCH;
END;
GO

-- ------------------------------ Use Case 4: Golf Facility wants to start a league ------------------------------------------
-- DML: select, insert, update
-- tables: team, league_team, league, facility
-- @ben
CREATE OR ALTER PROCEDURE CreateFacilityLeague
    @FacilityId INT,
    @LeagueName VARCHAR(100),
    @SkillLevel VARCHAR(20),
    @StartDate DATE,
    @EndDate DATE,
    @MaxTeams INT,
    @LeagueFormat VARCHAR(20)
    AS
BEGIN
SET NOCOUNT ON;

    DECLARE @LeagueId INT;
    DECLARE @TeamCount INT;
    DECLARE @State VARCHAR(50);
    DECLARE @City VARCHAR(50);
    DECLARE @Zip VARCHAR(20);

    -- Get facility location information to set as league information
SELECT @State = [state], @City = city, @Zip = zip
FROM facility
WHERE facility_id = @FacilityId;

IF @@ROWCOUNT = 0
BEGIN
        RAISERROR('Facility ID %d not found.', 16, 1, @FacilityId);
        RETURN;
END

    -- Check if there are teams with this facility as home
SELECT @TeamCount = COUNT(*)
FROM team
WHERE home_facility_id = @FacilityId;

IF @TeamCount = 0
BEGIN
        RAISERROR('No teams found with this facility as home base.', 16, 1);
        RETURN;
END

    IF @TeamCount > @MaxTeams
BEGIN
        RAISERROR('There are more teams (%d) than the maximum allowed (%d) for the league.', 16, 1, @TeamCount, @MaxTeams);
        RETURN;
END

BEGIN TRANSACTION;

BEGIN TRY
        -- 1. INSERT: Create the new league
INSERT INTO league (name, state, city, zip, skill_level, status, start_date, end_date, max_teams, league_format)
        VALUES (@LeagueName, @State, @City, @Zip, @SkillLevel, 'Setting Up', @StartDate, @EndDate, @MaxTeams, @LeagueFormat);

        -- Get the new league ID
        SET @LeagueId = SCOPE_IDENTITY();

        -- 2. INSERT: Register all teams from the facility into the league
INSERT INTO league_team (league_id, team_id, join_date)
SELECT @LeagueId, team_id, GETDATE()
FROM team
WHERE home_facility_id = @FacilityId;

-- 3. UPDATE: Update the league status to indicate it's ready
UPDATE league
SET status = 'In Season'
WHERE league_id = @LeagueId;

-- 4. SELECT: Return information about the registered teams
SELECT
    l.league_id,
    l.name AS league_name,
    t.team_id,
    t.name AS team_name,
    f.name AS facility_name,
    lt.join_date
FROM league l
         JOIN league_team lt ON l.league_id = lt.league_id
         JOIN team t ON lt.team_id = t.team_id
         JOIN facility f ON t.home_facility_id = f.facility_id
WHERE l.league_id = @LeagueId;

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
END CATCH;
END
GO


-- ----------------------------- Helpful Stored Procedures (No Use Cases) ----------------------------
CREATE PROCEDURE GetPlayersWithTeamInfo
    AS
BEGIN
    SET NOCOUNT ON;

SELECT
    p.player_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone_number,
    p.skill_level,
    p.handicap,
    t.team_id,
    t.name AS team_name,
    t.creation_date AS team_creation_date,
    f.name AS facility_name,
    tp.join_date AS team_join_date,
    tp.position AS team_position
FROM
    player p
        LEFT JOIN
    team_player tp ON p.player_id = tp.player_id
        LEFT JOIN
    team t ON tp.team_id = t.team_id
        LEFT JOIN
    facility f ON t.home_facility_id = f.facility_id
ORDER BY
    p.last_name, p.first_name;
END
GO

CREATE PROCEDURE GetTeamsWithLeagueInfo
    @LeagueId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

SELECT
    l.league_id,
    l.name AS league_name,
    l.state,
    l.city,
    l.skill_level AS league_skill_level,
    l.status AS league_status,
    l.start_date,
    l.end_date,
    t.team_id,
    t.name AS team_name,
    t.creation_date,
    f.facility_id,
    f.name AS facility_name,
    lt.join_date AS league_join_date
FROM
    league l
        LEFT JOIN
    league_team lt ON l.league_id = lt.league_id
        LEFT JOIN
    team t ON lt.team_id = t.team_id
        LEFT JOIN
    facility f ON t.home_facility_id = f.facility_id
WHERE
    (@LeagueId IS NULL OR l.league_id = @LeagueId)
ORDER BY
    l.name, t.name;
END
GO


-- ----------------------------- Helpful Stored Procedures (No Use Cases) ----------------------------
CREATE PROCEDURE GetPlayersWithTeamInfo
    AS
BEGIN
    SET NOCOUNT ON;

SELECT
    p.player_id,
    p.first_name,
    p.last_name,
    p.email,
    p.phone_number,
    p.skill_level,
    p.handicap,
    t.team_id,
    t.name AS team_name,
    t.creation_date AS team_creation_date,
    f.name AS facility_name,
    tp.join_date AS team_join_date,
    tp.position AS team_position
FROM
    player p
        LEFT JOIN
    team_player tp ON p.player_id = tp.player_id
        LEFT JOIN
    team t ON tp.team_id = t.team_id
        LEFT JOIN
    facility f ON t.home_facility_id = f.facility_id
ORDER BY
    p.last_name, p.first_name;
END
GO

CREATE PROCEDURE GetTeamsWithLeagueInfo
    @LeagueId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

SELECT
    l.league_id,
    l.name AS league_name,
    l.state,
    l.city,
    l.skill_level AS league_skill_level,
    l.status AS league_status,
    l.start_date,
    l.end_date,
    t.team_id,
    t.name AS team_name,
    t.creation_date,
    f.facility_id,
    f.name AS facility_name,
    lt.join_date AS league_join_date
FROM
    league l
        LEFT JOIN
    league_team lt ON l.league_id = lt.league_id
        LEFT JOIN
    team t ON lt.team_id = t.team_id
        LEFT JOIN
    facility f ON t.home_facility_id = f.facility_id
WHERE
    (@LeagueId IS NULL OR l.league_id = @LeagueId)
ORDER BY
    l.name, t.name;
END
GO

-- --------------------- Use Case: Update Player Handicap -----------------------------
-- DML: select, update
-- tables: game_team, team_player, player
CREATE OR ALTER PROCEDURE UpdatePlayerHandicap
    @player_id INT
    AS
BEGIN
    SET NOCOUNT ON;

    -- Variables for calculation
    DECLARE @avg_score DECIMAL(5,2);
    DECLARE @new_handicap DECIMAL(4,1);

    -- Check if player exists
    IF NOT EXISTS (SELECT 1 FROM player WHERE player_id = @player_id)
BEGIN
        RAISERROR('Player does not exist', 16, 1);
        RETURN;
END

BEGIN TRY
BEGIN TRANSACTION;

        -- Calculate average score from recent matches
        -- Retrieves scores from matches the player participated in through their teams
SELECT @avg_score = AVG(CAST(gt.score AS DECIMAL(5,2)))
FROM game_team gt
         JOIN team_player tp ON gt.team_id = tp.team_id
         JOIN game g ON gt.game_id = g.game_id
WHERE tp.player_id = @player_id
  AND g.status = 'Completed'
  AND g.date_time >= DATEADD(MONTH, -3, GETDATE()); -- Only use matches from last 3 months

-- If no matches found, don't update handicap
IF @avg_score IS NULL
BEGIN
SELECT
    p.player_id,
    p.first_name,
    p.last_name,
    p.handicap,
    'No recent matches found' AS update_status
FROM player p
WHERE p.player_id = @player_id;

COMMIT TRANSACTION;
RETURN;
END

        -- Calculate new handicap (basic formula: avg_score - 72)
        -- Using 72 as a standard par score, adjust as needed
        SET @new_handicap = @avg_score - 72.0;

 -- Update player's handicap
UPDATE player
SET handicap = @new_handicap
WHERE player_id = @player_id;

-- Return updated player information
SELECT
    p.player_id,
    p.first_name,
    p.last_name,
    p.handicap AS new_handicap,
    @avg_score AS average_score,
    'Handicap updated successfully' AS update_status
FROM player p
WHERE p.player_id = @player_id;

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @error_message NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @error_severity INT = ERROR_SEVERITY();
        DECLARE @error_state INT = ERROR_STATE();

        RAISERROR(@error_message, @error_severity, @error_state);
END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE UpdateMatchResults
    @GameID INT,
    @Team1ID INT,
    @Team1Score INT,
    @Team2ID INT,
    @Team2Score INT
    AS
BEGIN
    SET NOCOUNT ON;

    -- Begin transaction for atomicity
BEGIN TRY
BEGIN TRANSACTION;

        -- Verify that the game exists
        IF NOT EXISTS (SELECT 1 FROM game WHERE game_id = @GameID)
BEGIN
            RAISERROR('Game with ID %d does not exist.', 16, 1, @GameID);
            RETURN;
END

        -- Verify that the game is not already completed or cancelled
        DECLARE @CurrentStatus VARCHAR(20);
SELECT @CurrentStatus = status FROM game WHERE game_id = @GameID;

IF @CurrentStatus = 'Completed'
BEGIN
            RAISERROR('Game with ID %d is already marked as completed.', 16, 1, @GameID);
            RETURN;
END

        IF @CurrentStatus = 'Cancelled'
BEGIN
            RAISERROR('Game with ID %d has been cancelled and cannot be updated.', 16, 1, @GameID);
            RETURN;
END

        -- Verify that both teams are part of this game
        IF NOT EXISTS (SELECT 1 FROM game_team WHERE game_id = @GameID AND team_id = @Team1ID)
BEGIN
            RAISERROR('Team with ID %d is not part of game with ID %d.', 16, 1, @Team1ID, @GameID);
            RETURN;
END

        IF NOT EXISTS (SELECT 1 FROM game_team WHERE game_id = @GameID AND team_id = @Team2ID)
BEGIN
            RAISERROR('Team with ID %d is not part of game with ID %d.', 16, 1, @Team2ID, @GameID);
            RETURN;
END

        -- Update the scores for both teams
UPDATE game_team
SET score = @Team1Score
WHERE game_id = @GameID AND team_id = @Team1ID;

UPDATE game_team
SET score = @Team2Score
WHERE game_id = @GameID AND team_id = @Team2ID;

-- Update the game status to 'Completed'
UPDATE game
SET status = 'Completed'
WHERE game_id = @GameID;

-- Return game details with updated information
SELECT
    g.game_id,
    g.league_id,
    l.name AS league_name,
    g.facility_id,
    f.name AS facility_name,
    g.date_time,
    g.status,
    g.game_type,
    t1.team_id AS team1_id,
    t1.name AS team1_name,
    gt1.score AS team1_score,
    t2.team_id AS team2_id,
    t2.name AS team2_name,
    gt2.score AS team2_score,
    CASE
        WHEN gt1.score > gt2.score THEN t1.name
        WHEN gt2.score > gt1.score THEN t2.name
        ELSE 'Tie'
        END AS winner
FROM game g
         JOIN facility f ON g.facility_id = f.facility_id
         LEFT JOIN league l ON g.league_id = l.league_id
         JOIN game_team gt1 ON g.game_id = gt1.game_id AND gt1.team_id = @Team1ID
         JOIN game_team gt2 ON g.game_id = gt2.game_id AND gt2.team_id = @Team2ID
         JOIN team t1 ON gt1.team_id = t1.team_id
         JOIN team t2 ON gt2.team_id = t2.team_id
WHERE g.game_id = @GameID;

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
        -- An error occurred, roll back the transaction
IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Return error information
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH
END;

-- Create a trigger that updates player handicaps after a game is completed
CREATE OR ALTER TRIGGER trg_UpdatePlayerHandicap
ON game
AFTER UPDATE
                          AS
BEGIN
    SET NOCOUNT ON;

    -- Only proceed if a game was marked as completed
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.game_id = d.game_id
        WHERE i.status = 'Completed' AND d.status <> 'Completed'
    )
BEGIN
        -- Get the game_id of the completed game
        DECLARE @GameID INT;
SELECT @GameID = i.game_id
FROM inserted i
         JOIN deleted d ON i.game_id = d.game_id
WHERE i.status = 'Completed' AND d.status <> 'Completed';

-- Get team scores
DECLARE @Team1ID INT, @Team2ID INT, @Team1Score INT, @Team2Score INT;

        -- Get teams and scores for this game
SELECT TOP 1 @Team1ID = team_id, @Team1Score = score
FROM game_team
WHERE game_id = @GameID;

SELECT TOP 1 @Team2ID = team_id, @Team2Score = score
FROM game_team
WHERE game_id = @GameID AND team_id <> @Team1ID;

-- Calculate handicap adjustment factors based on game performance
-- This is a simplified handicap calculation - in reality, handicap calculations are more complex
-- For winners: slightly decrease handicap (improve)
-- For losers: slightly increase handicap
DECLARE @WinnerAdjustment DECIMAL(4,1) = -0.2; -- Improve handicap
        DECLARE @LoserAdjustment DECIMAL(4,1) = 0.1;  -- Decrease handicap
        DECLARE @TieAdjustment DECIMAL(4,1) = -0.1;   -- Slight improvement for both

        -- Determine which team won
        DECLARE @WinningTeamID INT, @LosingTeamID INT;
        IF @Team1Score > @Team2Score
BEGIN
            SET @WinningTeamID = @Team1ID;
            SET @LosingTeamID = @Team2ID;
END
ELSE IF @Team2Score > @Team1Score
BEGIN
            SET @WinningTeamID = @Team2ID;
            SET @LosingTeamID = @Team1ID;
END
        -- If it's a tie, both teams get a slight improvement

        -- Update handicaps for players on the winning team
        IF @WinningTeamID IS NOT NULL
BEGIN
UPDATE player
SET handicap =
        CASE
            WHEN handicap IS NULL THEN NULL -- Don't update NULL handicaps
            ELSE ROUND(handicap + @WinnerAdjustment, 1)
            END
    FROM player p
            JOIN team_player tp ON p.player_id = tp.player_id
WHERE tp.team_id = @WinningTeamID
  AND p.handicap IS NOT NULL;

-- Update handicaps for players on the losing team
UPDATE player
SET handicap =
        CASE
            WHEN handicap IS NULL THEN NULL -- Don't update NULL handicaps
            ELSE ROUND(handicap + @LoserAdjustment, 1)
            END
    FROM player p
            JOIN team_player tp ON p.player_id = tp.player_id
WHERE tp.team_id = @LosingTeamID
  AND p.handicap IS NOT NULL;
END
ELSE
BEGIN
            -- It's a tie - update both teams with the tie adjustment
UPDATE player
SET handicap =
        CASE
            WHEN handicap IS NULL THEN NULL -- Don't update NULL handicaps
            ELSE ROUND(handicap + @TieAdjustment, 1)
            END
    FROM player p
            JOIN team_player tp ON p.player_id = tp.player_id
WHERE tp.team_id IN (@Team1ID, @Team2ID)
  AND p.handicap IS NOT NULL;
END

END
END;