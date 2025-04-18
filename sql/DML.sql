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
