-- Defines all the relations for Tee-Time along with key constraints and secondary indices

-- 1. Drop all tables first (in reverse order in case of FK constraints)
DROP TABLE IF EXISTS GameTeam;
DROP TABLE IF EXISTS Game;
DROP TABLE IF EXISTS PlayerMembership;
DROP TABLE IF EXISTS Membership;
DROP TABLE IF EXISTS LeagueTeam;
DROP TABLE IF EXISTS League;
DROP TABLE IF EXISTS TeamPlayer;
DROP TABLE IF EXISTS Team;
DROP TABLE IF EXISTS Facility;
DROP TABLE IF EXISTS Player;


-- 2. Define all tables

-- --------------------- Player Relation (1) -----------------------------
CREATE TABLE player (
    player_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    age INT NOT NULL,
    state VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    zip VARCHAR(20) NOT NULL,
    skill_level VARCHAR(20) NOT NULL CHECK (skill_level IN ('Complete Beginner', 'Beginner', 'Intermediate', 'Advanced', 'Professional')),
    handicap DECIMAL(4,1) NULL,
    join_date DATE NOT NULL,
    profile_type VARCHAR(10) NOT NULL CHECK (profile_type IN ('Public', 'Hidden'))
);

CREATE NONCLUSTERED INDEX ix_player_location_skill
ON player(state, city, skill_level);


-- --------------------- Facility Relation (2) -----------------------------
CREATE TABLE facility (
    facility_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(50) NOT NULL CHECK (name IN ('TopGolf', 'Five Iron')),
    address VARCHAR(200) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip VARCHAR(20) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    website VARCHAR(200) NULL,
    opening_time TIME NOT NULL,
    closing_time TIME NOT NULL,
    number_of_bays INT NOT NULL
);


-- --------------------- Team Relation (3) -----------------------------
CREATE TABLE team (
    team_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    creation_date DATE NOT NULL,
    home_facility_id INT NULL,
    FOREIGN KEY (home_facility_id) REFERENCES facility(facility_id)
);


-- -------------------- TeamPlayer Relation (4) -------------------------
CREATE TABLE team_player (
    player_id INT NOT NULL,
    team_id INT NOT NULL,
    join_date DATE NOT NULL,
    position VARCHAR(20) NOT NULL CHECK (position IN ('Captain', 'Member')),
    PRIMARY KEY (player_id, team_id),
    FOREIGN KEY (player_id) REFERENCES player(player_id),
    FOREIGN KEY (team_id) REFERENCES team(team_id)
);


-- --------------------- League Relation (5) -----------------------------
CREATE TABLE league (
    league_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    zip VARCHAR(20) NOT NULL,
    skill_level VARCHAR(20) NOT NULL CHECK (skill_level IN ('Complete Beginner', 'Beginner', 'Intermediate', 'Advanced', 'Professional')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('Setting Up', 'In Season', 'Paused', 'Playoffs', 'Completed')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    max_teams INT NOT NULL,
    league_format VARCHAR(20) NOT NULL CHECK (league_format IN ('Round Robin', 'Elimination', 'RR-E'))
);


-- --------------------- League Team Relation (6) -----------------------------
CREATE TABLE league_team (
    league_id INT NOT NULL,
    team_id INT NOT NULL,
    join_date DATE NOT NULL,
    PRIMARY KEY (league_id, team_id),
    FOREIGN KEY (league_id) REFERENCES league(league_id),
    FOREIGN KEY (team_id) REFERENCES team(team_id)
);


-- --------------------- Membership Relation (7) -----------------------------
CREATE TABLE membership (
    membership_id INT IDENTITY(1,1) PRIMARY KEY,
    facility_id INT NOT NULL,
    membership_type VARCHAR(100) NOT NULL,
    monthly_fee DECIMAL(10,2) NULL,
    annual_fee DECIMAL(10,2) NULL,
    benefits VARCHAR(500) NULL,
    guest_allowance INT NOT NULL,
    FOREIGN KEY (facility_id) REFERENCES facility(facility_id)
);


-- --------------------- Player Membership Relation (8) -----------------------------
CREATE TABLE player_membership (
    player_id INT NOT NULL,
    membership_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('Scheduled', 'Completed', 'Cancelled')),
    PRIMARY KEY (player_id, membership_id),
    FOREIGN KEY (player_id) REFERENCES player(player_id),
    FOREIGN KEY (membership_id) REFERENCES membership(membership_id)
);


-- --------------------------- Game Relation (9) ------------------------------------
CREATE TABLE game (
    game_id INT IDENTITY(1,1) PRIMARY KEY,
    league_id INT NULL,
    facility_id INT NOT NULL,
    date_time DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Scheduled', 'Completed', 'Cancelled')),
    game_type VARCHAR(50) NOT NULL,
    FOREIGN KEY (league_id) REFERENCES league(league_id),
    FOREIGN KEY (facility_id) REFERENCES facility(facility_id)
);


-- --------------------------- Game Team Relation (10) ------------------------------------
CREATE TABLE game_team (
    game_id INT NOT NULL,
    team_id INT NOT NULL,
    score INT NULL,
    PRIMARY KEY (game_id, team_id),
    FOREIGN KEY (game_id) REFERENCES game(game_id),
    FOREIGN KEY (team_id) REFERENCES team(team_id)
);

