-- For populating all relations with mock data for testing

-- Clear all existing data (if any)
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'
EXEC sp_MSforeachtable 'DELETE FROM ?'
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'

-- Reset identity columns (only for tables that have them)
DBCC CHECKIDENT ('player', RESEED, 0)
DBCC CHECKIDENT ('facility', RESEED, 0)
DBCC CHECKIDENT ('team', RESEED, 0)
DBCC CHECKIDENT ('league', RESEED, 0)
DBCC CHECKIDENT ('membership', RESEED, 0)
DBCC CHECKIDENT ('game', RESEED, 0)

-- Create facilities (1 TopGolf, 1 Five Iron in Cleveland)
INSERT INTO facility (name, address, city, state, zip, phone, website, opening_time, closing_time, number_of_bays)
VALUES
('TopGolf', '5820 Rockside Woods Blvd', 'Cleveland', 'Ohio', '44131', '216-555-1234', 'www.topgolf.com/cleveland', '09:00:00', '23:00:00', 102),
('Five Iron', '2000 East 9th Street', 'Cleveland', 'Ohio', '44115', '216-555-5678', 'www.fiveirongolf.com/cleveland', '07:00:00', '22:00:00', 14);

-- Create memberships
INSERT INTO membership (facility_id, membership_type, monthly_fee, annual_fee, benefits, guest_allowance)
VALUES
(1, 'TopGolf Platinum', 49.99, 499.99, 'Unlimited play during non-peak hours, 10% off food and beverages', 2),
(1, 'TopGolf Gold', 29.99, 299.99, '20 free games per month, 5% off food and beverages', 1),
(2, 'Five Iron Elite', 199.99, 1999.99, 'Unlimited simulator access, pro lessons monthly, locker access', 3),
(2, 'Five Iron Basic', 99.99, 999.99, '2+ hour simulator time per day, 20% off food and beverages', 1);

-- Create players
INSERT INTO player (first_name, last_name, email, phone_number, age, state, city, zip, skill_level, handicap, join_date, profile_type)
VALUES
('Dorian', 'Hawkins', 'dorian.hawkins@email.com', '216-111-1111', 32, 'Ohio', 'Cleveland', '44115', 'Advanced', 6.5, '2023-01-15', 'Public'),
('William', 'Zhu', 'william.zhu@email.com', '216-222-2222', 28, 'Ohio', 'Cleveland Heights', '44118', 'Intermediate', 12.3, '2023-02-20', 'Public'),
('Ben', 'Luo', 'ben.luo@email.com', '216-333-3333', 35, 'Ohio', 'Shaker Heights', '44120', 'Advanced', 8.7, '2023-03-10', 'Hidden'),
('Timothy', 'Cronin', 'timothy.cronin@email.com', '216-444-4444', 42, 'Ohio', 'Lakewood', '44107', 'Intermediate', 15.2, '2023-04-05', 'Public'),
('Pranav', 'Balabhadra', 'pranav.balabhadra@email.com', '216-555-5555', 31, 'Ohio', 'Cleveland', '44114', 'Beginner', 20.1, '2023-05-12', 'Public'),
('Tiger', 'Woods', 'tiger.woods@email.com', '216-666-6666', 49, 'Ohio', 'Cleveland', '44113', 'Professional', 0.0, '2023-06-15', 'Hidden'),
('Rory', 'McIlroy', 'rory.mcilroy@email.com', '216-777-7777', 36, 'Ohio', 'Cleveland', '44131', 'Professional', 0.2, '2023-12-10', 'Public'),
('Min Woo', 'Lee', 'minwoo.lee@email.com', '216-888-8888', 27, 'Ohio', 'Cleveland', '44131', 'Advanced', 3.4, '2024-01-15', 'Public'),
('LeBron', 'James', 'lebron.james@email.com', '216-999-9999', 40, 'Ohio', 'Akron', '44308', 'Intermediate', 14.8, '2024-02-20', 'Public');

-- Assign memberships to players (2 TopGolf, 2 Five Iron)
INSERT INTO player_membership (player_id, membership_id, start_date, end_date, payment_status)
VALUES
(1, 1, '2023-01-20', '2024-01-20', 'Completed'), -- Dorian has TopGolf Platinum
(2, 2, '2023-02-25', '2024-02-25', 'Completed'), -- William has TopGolf Gold
(3, 3, '2023-03-15', '2024-03-15', 'Completed'), -- Ben has Five Iron Elite
(4, 4, '2023-04-10', '2024-04-10', 'Completed'), -- Tim has Five Iron Basic
(7, 1, '2023-12-15', '2024-12-15', 'Completed'), -- Rory has TopGolf Platinum
(8, 1, '2024-01-20', '2025-01-20', 'Completed'), -- Min Woo has TopGolf Platinum
(9, 2, '2024-02-25', '2025-02-25', 'Completed'); -- LeBron has TopGolf Gold

-- Create teams
INSERT INTO team (name, creation_date, home_facility_id)
VALUES
('Birdie Bandits', '2023-07-01', 1), -- Home at TopGolf
('Holy Strokes', '2023-07-15', 2),   -- Home at Five Iron
('Drive Dynasty', '2024-01-05', 1),  -- Home at TopGolf
('Eagle Elites', '2024-02-10', 1);   -- Home at TopGolf

-- Assign players to teams
-- Team 1: Dorian (Captain) and William
-- Team 2: Ben (Captain) and Timothy
-- Team 3: Rory (Captain) and Min Woo
-- Team 4: LeBron (Captain) and Tiger
INSERT INTO team_player (player_id, team_id, join_date, position)
VALUES
(1, 1, '2023-07-01', 'Captain'),
(2, 1, '2023-07-05', 'Member'), 
(3, 2, '2023-07-15', 'Captain'),
(4, 2, '2023-07-20', 'Member'),
(9, 4, '2024-02-10', 'Captain'),
(6, 4, '2024-02-15', 'Member');

-- Create a league
INSERT INTO league (name, state, city, zip, skill_level, status, start_date, end_date, max_teams, league_format)
VALUES
('Cleveland Metro Golf League', 'Ohio', 'Cleveland', '44115', 'Intermediate', 'In Season', '2023-08-01', '2023-10-30', 8, 'Round Robin');

-- Add teams to the league
INSERT INTO league_team (league_id, team_id, join_date)
VALUES
(1, 1, '2023-07-25'), -- Birdie Bandits join the league
(1, 2, '2023-07-27'); -- Holy Strokes join the league

-- Create a game between the two teams
INSERT INTO game (league_id, facility_id, date_time, status, game_type)
VALUES
(1, 1, '2023-09-15 18:00:00', 'Completed', 'Regular Season');

-- Record the game results
INSERT INTO game_team (game_id, team_id, score)
VALUES
(1, 1, 42), -- Birdie Bandits score
(1, 2, 39); -- Holy Strokes score
