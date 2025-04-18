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



CREATE OR ALTER PROCEDURE CancelPlayerMembership --Use Case 6
    @player_id INT,
    @membership_id INT
    AS
BEGIN
    SET NOCOUNT ON;
    -- Check if the membership exists
    IF NOT EXISTS (SELECT 1 FROM player_membership
                  WHERE player_id = @player_id AND membership_id = @membership_id)
BEGIN
        -- Return an error message
SELECT 'Membership not found' AS error_message;
RETURN;
END

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

-- --------------------- Use Case: Update Player Handicap (Use Case 5) -----------------------------
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

-- --------------------- Trigger to Update Handicap After Match Score Changes -----------------------------
CREATE OR ALTER TRIGGER AutoUpdateHandicapAfterMatch
ON game_team
AFTER INSERT, UPDATE
                                  AS
BEGIN
    SET NOCOUNT ON;

    -- Only process if score was updated
    IF UPDATE(score)
BEGIN
        -- Temporary table to hold players that need handicap updates
        DECLARE @players_to_update TABLE (player_id INT);

        -- Find all players on teams that had scores updated
INSERT INTO @players_to_update
SELECT DISTINCT tp.player_id
FROM inserted i
         JOIN team_player tp ON i.team_id = tp.team_id
         JOIN game g ON i.game_id = g.game_id
WHERE g.status = 'Completed';

-- Update handicap for each player
DECLARE @player_id INT;
        DECLARE player_cursor CURSOR FOR
SELECT player_id FROM @players_to_update;

OPEN player_cursor;
FETCH NEXT FROM player_cursor INTO @player_id;

WHILE @@FETCH_STATUS = 0
BEGIN
EXEC UpdatePlayerHandicap @player_id;
FETCH NEXT FROM player_cursor INTO @player_id;
END

CLOSE player_cursor;
DEALLOCATE player_cursor;
END
END;
GO

-- -------------------- Use Case 7: Updating League Status --------------------
CREATE OR ALTER PROCEDURE UpdateLeagueStatus
    @league_id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    -- 1. Verify league exists
    IF NOT EXISTS (SELECT 1 FROM league WHERE league_id = @league_id)
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN -1;  -- league not found
    END;

    -- 2. Count joined teams vs. max_teams
    DECLARE @joinedCount INT, @maxTeams INT;
    SELECT @joinedCount = COUNT(*) 
      FROM league_team 
     WHERE league_id = @league_id;

    SELECT @maxTeams = max_teams
      FROM league
     WHERE league_id = @league_id;

    -- 3. If not all teams joined, abort
    IF @joinedCount < @maxTeams
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN -2;  -- not ready: still waiting on teams
    END;

    -- 4. Transition to “In Season”
    UPDATE league
       SET status = 'In Season'
     WHERE league_id = @league_id;

    -- 5. Return updated league info + joinedCount
    SELECT
        l.league_id,
        l.name,
        l.state,
        l.city,
        l.zip,
        l.skill_level,
        l.status,
        l.start_date,
        l.end_date,
        l.max_teams,
        @joinedCount AS teams_joined
    FROM league l
    WHERE l.league_id = @league_id;

    COMMIT TRANSACTION;
    RETURN 0;  -- success
END;
GO
