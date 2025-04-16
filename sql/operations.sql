-- For procedures, functions, triggers, and views

-- ------------------------------ Use Case 1: Player Joins a Team ------------------------------------------
-- DML: select, insert
-- tables: team, team_player, facility
-- @ben
CREATE OR ALTER PROCEDURE JoinTeam
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

    BEGIN TRANSACTION;

    -- Check if the team exists
    IF NOT EXISTS (SELECT 1 FROM team WHERE team_id = @team_id)
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN -1;
    END;

    BEGIN TRY
        INSERT INTO team_player (player_id, team_id, join_date, position)
        VALUES (@played_id, @team_id, @join_date, position);

        -- Return team details to the application
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

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        RETURN -1;
    END CATCH;
END;
GO


-- ------------------------------- GENERAL PROCEDURES - Player Relation ------------------------------------
CREATE OR ALTER PROCEDURE InsertPlayer
    @first_name VARCHAR(50),
    @last_name VARCHAR(50),
    @email VARCHAR(100),
    @phone_number VARCHAR(20),
    @age INT,
    @state VARCHAR(50),
    @city VARCHAR(50),
    @zip VARCHAR(20),
    @skill_level VARCHAR(20),
    @handicap DECIMAL(4,1) = NULL,
    @join_date DATE,
    @profile_type VARCHAR(10),
    @player_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    SAVE TRANSACTION BeforeChanges;
    
    BEGIN TRY
        INSERT INTO player (
            first_name, 
            last_name, 
            email, 
            phone_number, 
            age, 
            [state], 
            city, 
            zip, 
            skill_level, 
            handicap, 
            join_date, 
            profile_type
        )
        VALUES (
            @first_name, 
            @last_name, 
            @email, 
            @phone_number, 
            @age, 
            @state, 
            @city, 
            @zip, 
            @skill_level, 
            @handicap, 
            @join_date, 
            @profile_type
        );
        
        SET @player_id = SCOPE_IDENTITY();
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION BeforeChanges;
        RETURN -1;
    END CATCH;
END;
GO


