-- For procedures, functions, triggers, and views

-- ------------------------------ Use Case 1: Player Joins a Team ------------------------------------------
-- TODO

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
            state, 
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


