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

-- Create additional facilities
INSERT INTO facility (name, address, city, state, zip, phone, website, opening_time, closing_time, number_of_bays)
VALUES
('TopGolf', '123 Main St',         'Cleveland', 'Ohio', '44132', '216-101-0001', 'www.topgolf.com/cleveland-east', '08:00:00', '22:00:00',  50),
('Five Iron', '456 Oak Ave',        'Cleveland', 'Ohio', '44133', '216-101-0002', 'www.fiveirongolf.com/cleveland-west','09:00:00','21:00:00',  12),
('TopGolf', '789 Elm Blvd',         'Cleveland', 'Ohio', '44134', '216-101-0003', 'www.topgolf.com/cleveland-north','10:00:00','20:00:00',  60),
('Five Iron','234 Pine St',         'Cleveland', 'Ohio', '44135', '216-101-0004', 'www.fiveirongolf.com/cleveland-south','07:00:00','23:00:00',   8),
('TopGolf', '567 Maple Rd',         'Cleveland', 'Ohio', '44136', '216-101-0005', 'www.topgolf.com/cleveland-uptown','09:00:00','22:00:00',  40),
('Five Iron','890 Birch Ln',        'Cleveland', 'Ohio', '44137', '216-101-0006', 'www.fiveirongolf.com/cleveland-downtown','08:00:00','21:00:00',14),
('TopGolf', '135 Cedar Pkwy',       'Cleveland', 'Ohio', '44138', '216-101-0007', 'www.topgolf.com/cleveland-park','09:00:00','22:00:00',  55),
('Five Iron','246 Spruce Dr',       'Cleveland', 'Ohio', '44139', '216-101-0008', 'www.fiveirongolf.com/cleveland-hills','07:00:00','20:00:00', 10),
('TopGolf', '357 Walnut Ct',        'Cleveland', 'Ohio', '44140', '216-101-0009', 'www.topgolf.com/cleveland-bay','10:00:00','23:00:00',  70),
('Five Iron','468 Poplar St',       'Cleveland', 'Ohio', '44141', '216-101-0010', 'www.fiveirongolf.com/cleveland-river','09:00:00','22:00:00', 12);

-- Create memberships
INSERT INTO membership (facility_id, membership_type, monthly_fee, annual_fee, benefits, guest_allowance)
VALUES
(1, 'TopGolf Platinum', 49.99, 499.99, 'Unlimited play during non-peak hours, 10% off food and beverages', 2),
(1, 'TopGolf Gold', 29.99, 299.99, '20 free games per month, 5% off food and beverages', 1),
(2, 'Five Iron Elite', 199.99, 1999.99, 'Unlimited simulator access, pro lessons monthly, locker access', 3),
(2, 'Five Iron Basic', 99.99, 999.99, '2+ hour simulator time per day, 20% off food and beverages', 1),
(3, 'TopGolf Platinum Plus',   59.99,  599.99, 'Unlimited play + free lessons',          3),
(3, 'TopGolf Gold Plus',       39.99,  399.99, '25 free games, 10% off food',             2),
(4, 'Five Iron Elite Plus',   249.99, 2499.99, 'Unlimited access + gear rental',         4),
(4, 'Five Iron Basic Plus',   149.99, 1499.99, '3 hours/day + 25% off food',             2),
(5, 'TopGolf Silver',         19.99,  199.99, '15 free games per month',                1),
(6, 'Five Iron Bronze',       49.99,  499.99, '1 hour/day access',                      1),
(7, 'TopGolf Bronze',         24.99,  249.99, '5 free games + 5% off food',            1),
(8, 'Five Iron Standard',     129.99, 1299.99, 'Unlimited simulator access',             3),
(9, 'TopGolf Weekend Warrior',34.99,  349.99,'Unlimited weekend play',                2),
(10,'Five Iron Weekday',       89.99,  899.99, '2+ hour/day M–F + 10% off lessons',      1);

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
('LeBron', 'James', 'lebron.james@email.com', '216-999-9999', 40, 'Ohio', 'Akron', '44308', 'Intermediate', 14.8, '2024-02-20', 'Public'),
('Jordan',     'Spieth',    'jordan.spieth@example.com',    '216-123-0001', 27, 'Ohio','Euclid',       '44119','Advanced',            5.2,    '2024-03-01','Public'),
('Brooks',     'Koepka',    'brooks.koepka@example.com',    '216-123-0002', 32, 'Ohio','Lakewood',    '44107','Professional',         0.0,    '2024-03-02','Public'),
('Justin',     'Thomas',    'justin.thomas@example.com',    '216-123-0003', 30, 'Ohio','Shaker Heights','44120','Advanced',            4.1,    '2024-03-03','Public'),
('Collin',     'Morikawa',  'collin.morikawa@example.com', '216-123-0004', 25, 'Ohio','Cleveland',    '44115','Advanced',            3.8,    '2024-03-04','Hidden'),
('Xander',     'Schauffele','xander.schauffele@example.com','216-123-0005', 28, 'Ohio','Cleveland',    '44131','Professional',         0.0,    '2024-03-05','Public'),
('Matt',       'Kuchar',    'matt.kuchar@example.com',     '216-123-0006', 46, 'Ohio','Akron',        '44308','Intermediate',       13.2,    '2024-03-06','Public'),
('Bubba',      'Watson',    'bubba.watson@example.com',     '216-123-0007', 44, 'Ohio','Cleveland',    '44113','Professional',         0.0,    '2024-03-07','Hidden'),
('Phil',       'Mickelson', 'phil.mickelson@example.com',  '216-123-0008', 53, 'Ohio','Westlake',     '44145','Professional',         0.0,    '2024-03-08','Public'),
('Annika',     'Sorenstam', 'annika.sorenstam@example.com', '216-123-0009', 55, 'Ohio','Parma',        '44129','Professional',         0.0,    '2024-03-09','Public'),
('Ricky',      'Fowler',    'ricky.fowler@example.com',    '216-123-0010', 33, 'Ohio','Beachwood',    '44122','Advanced',            6.0,    '2024-03-10','Public');

-- Assign memberships to players (2 TopGolf, 2 Five Iron)
INSERT INTO player_membership (player_id, membership_id, start_date, end_date, payment_status)
VALUES
(1, 1, '2023-01-20', '2024-01-20', 'Completed'), -- Dorian has TopGolf Platinum
(2, 2, '2023-02-25', '2024-02-25', 'Completed'), -- William has TopGolf Gold
(3, 3, '2023-03-15', '2024-03-15', 'Completed'), -- Ben has Five Iron Elite
(4, 4, '2023-04-10', '2024-04-10', 'Completed'), -- Tim has Five Iron Basic
(7, 1, '2023-12-15', '2024-12-15', 'Completed'), -- Rory has TopGolf Platinum
(8, 1, '2024-01-20', '2025-01-20', 'Completed'), -- Min Woo has TopGolf Platinum
(9, 2, '2024-02-25', '2025-02-25', 'Completed'), -- LeBron has TopGolf Gold
(10, 5, '2024-03-05', '2025-03-05', 'Scheduled'),
(11, 6, '2024-03-06', '2025-03-06', 'Scheduled'),
(12, 7, '2024-03-07', '2025-03-07', 'Scheduled'),
(13, 8, '2024-03-08', '2025-03-08', 'Scheduled'),
(14, 9, '2024-03-09', '2025-03-09', 'Scheduled'),
(15, 10, '2024-03-10', '2025-03-10', 'Scheduled'),
(16, 11, '2024-03-11', '2025-03-11', 'Scheduled'),
(17, 12, '2024-03-12', '2025-03-12', 'Scheduled'),
(18, 13, '2024-03-13', '2025-03-13', 'Scheduled'),
(19, 14, '2024-03-14', '2025-03-14', 'Scheduled');

-- Create teams
INSERT INTO team (name, creation_date, home_facility_id)
VALUES
('Birdie Bandits', '2023-07-01', 1), -- Home at TopGolf
('Holy Strokes', '2023-07-15', 2),   -- Home at Five Iron
('Drive Dynasty', '2024-01-05', 1),  -- Home at TopGolf
('Eagle Elites', '2024-02-10', 1),   -- Home at TopGolf
('Swing Kings',           '2024-03-01', 3),
('Ace Putters',           '2024-03-02', 4),
('Drive Force',           '2024-03-03', 5),
('Iron Maidens',          '2024-03-04', 6),
('Fairway Fanatics',      '2024-03-05', 7),
('Rough Riders',          '2024-03-06', 8),
('Birdie Hunters',        '2024-03-07', 9),
('Eagle Eyes',            '2024-03-08', 10),
('Putt Masters',          '2024-03-09', 11),
('Chip Shot Champions',   '2024-03-10', 12);

-- Assign players to teams - Only team_ids 1-14 are valid
INSERT INTO team_player (player_id, team_id, join_date, position)
VALUES
(1, 1, '2023-07-01', 'Captain'),
(2, 1, '2023-07-05', 'Member'), 
(3, 2, '2023-07-15', 'Captain'),
(4, 2, '2023-07-20', 'Member'),
(9, 4, '2024-02-10', 'Captain'),
(6, 4, '2024-02-15', 'Member'),
(5, 1, '2024-04-01', 'Member'),  -- to Team 1
(6, 2, '2024-04-01', 'Member'),  -- to Team 2
(7, 3, '2024-04-01', 'Member'),  -- to Team 3
(8, 4, '2024-04-01', 'Member'),  -- to Team 4
(9, 5, '2024-04-01', 'Member'),  -- to Team 5
(10, 6, '2024-04-01', 'Member'),  -- to Team 6
(11, 7, '2024-04-01', 'Member'),  -- to Team 7
(12, 8, '2024-04-01', 'Member'),  -- to Team 8
(13, 9, '2024-04-01', 'Member'),  -- to Team 9
(14, 10, '2024-04-01', 'Member'),  -- to Team 10
(15, 11, '2024-04-01', 'Member'),  -- to Team 11
(16, 12, '2024-04-01', 'Member'),  -- to Team 12
(17, 13, '2024-04-01', 'Member'),  -- to Team 13
(18, 14, '2024-04-01', 'Member');  -- to Team 14

-- Create leagues
INSERT INTO league (name, state, city, zip, skill_level, status, start_date, end_date, max_teams, league_format)
VALUES
('Cleveland Metro Golf League', 'Ohio', 'Cleveland', '44115', 'Intermediate', 'In Season', '2023-08-01', '2023-10-30', 8, 'Round Robin'),
('Spring Swing Invitational','Ohio','Cleveland','44115','Intermediate','Setting Up','2024-03-01','2024-05-31',6,'Elimination'),
('Summer Smash League',      'Ohio','Cleveland','44115','Beginner','Setting Up','2024-06-01','2024-08-31',8,'Round Robin'),
('Autumn Cup',               'Ohio','Cleveland','44115','Advanced','Setting Up','2024-09-01','2024-11-30',10,'RR-E'),
('Winter Classic',           'Ohio','Cleveland','44115','Professional','Setting Up','2024-12-01','2025-02-28',4,'Elimination'),
('Charity Open',             'Ohio','Cleveland','44115','Intermediate','Setting Up','2024-04-01','2024-04-30',5,'Round Robin'),
('Corporate Challenge',      'Ohio','Cleveland','44115','Beginner','Setting Up','2024-05-01','2024-05-31',6,'RR-E'),
('Night Golf',               'Ohio','Cleveland','44115','Advanced','Setting Up','2024-07-01','2024-07-31',4,'Elimination'),
('Family Fun',               'Ohio','Cleveland','44115','Complete Beginner','Setting Up','2024-08-01','2024-08-15',8,'Round Robin'),
('Junior League',            'Ohio','Cleveland','44115','Beginner','Setting Up','2024-09-01','2024-10-01',10,'RR-E'),
('Senior Cup',               'Ohio','Cleveland','44115','Advanced','Setting Up','2024-10-01','2024-11-01',6,'Elimination');

-- Add teams to the league
INSERT INTO league_team (league_id, team_id, join_date)
VALUES
(1, 1, '2023-07-25'), -- Birdie Bandits join the league
(1, 2, '2023-07-27'), -- Holy Strokes join the league
(1, 3, '2024-04-02'),
(1, 4, '2024-04-02'),
(1, 5, '2024-04-02'),
(1, 6, '2024-04-02'),
(1, 7, '2024-04-02'),
(1, 8, '2024-04-02'),
(6, 9, '2024-03-09'),
(7, 10, '2024-03-10'),
(8, 11, '2024-03-11'),
(9, 12, '2024-03-12'),
(10, 13, '2024-03-13'),
(11, 14, '2024-03-14');

-- Add teams to additional leagues - Only team_ids 1-14 are valid
INSERT INTO league_team (league_id, team_id, join_date)
VALUES
-- League 4: Autumn Cup (max_teams = 10)
(4, 1, '2024-04-05'), 
(4, 2, '2024-04-05'),
(4, 3, '2024-04-05'), 
(4, 4, '2024-04-05'),
(4, 5, '2024-04-05'), 
(4, 6, '2024-04-05'),
(4, 7, '2024-04-05'), 
(4, 8, '2024-04-05'),
(4, 9, '2024-04-05'), 
(4, 10, '2024-04-05'),

-- League 5: Winter Classic (max_teams = 4)
(5, 1, '2024-04-05'), 
(5, 2, '2024-04-05'),
(5, 3, '2024-04-05'), 
(5, 4, '2024-04-05'),

-- League 6: Charity Open (max_teams = 5)
(6, 1, '2024-04-05'), 
(6, 2, '2024-04-05'),
(6, 3, '2024-04-05'), 
(6, 4, '2024-04-05'),
(6, 5, '2024-04-05'),

-- League 7: Corporate Challenge (max_teams = 6)
(7, 1, '2024-04-05'), 
(7, 2, '2024-04-05'),
(7, 3, '2024-04-05'), 
(7, 4, '2024-04-05'),
(7, 5, '2024-04-05'), 
(7, 6, '2024-04-05'),

-- League 8: Night Golf (max_teams = 4)
(8, 1, '2024-04-05'), 
(8, 2, '2024-04-05'),
(8, 3, '2024-04-05'), 
(8, 4, '2024-04-05'),

-- League 9: Family Fun (max_teams = 8)
(9, 1, '2024-04-05'), 
(9, 2, '2024-04-05'),
(9, 3, '2024-04-05'), 
(9, 4, '2024-04-05'),
(9, 5, '2024-04-05'), 
(9, 6, '2024-04-05'),
(9, 7, '2024-04-05'), 
(9, 8, '2024-04-05'),

-- League 10: Junior League (max_teams = 10)
(10, 1, '2024-04-05'), 
(10, 2, '2024-04-05'),
(10, 3, '2024-04-05'), 
(10, 4, '2024-04-05'),
(10, 5, '2024-04-05'), 
(10, 6, '2024-04-05'),
(10, 7, '2024-04-05'), 
(10, 8, '2024-04-05'),
(10, 9, '2024-04-05'), 
(10, 10, '2024-04-05'),

-- League 11: Senior Cup (max_teams = 6)
(11, 1, '2024-04-05'), 
(11, 2, '2024-04-05'),
(11, 3, '2024-04-05'), 
(11, 4, '2024-04-05'),
(11, 5, '2024-04-05'), 
(11, 6, '2024-04-05');

-- Create games
INSERT INTO game (league_id, facility_id, date_time, status, game_type)
VALUES
(1, 1, '2023-09-15 18:00:00', 'Completed', 'Regular Season'),
(2, 2, '2024-04-03 12:30:00', 'Scheduled', 'Regular Season'),
(1, 1, '2024-03-01 10:00:00', 'Scheduled', 'Regular Season'),
(2, 2, '2024-03-02 11:00:00', 'Scheduled', 'Regular Season'),
(3, 3, '2024-03-03 12:00:00', 'Scheduled', 'Elimination'),
(4, 4, '2024-03-04 13:00:00', 'Scheduled', 'Elimination'),
(5, 5, '2024-03-05 14:00:00', 'Scheduled', 'Round Robin'),
(6, 6, '2024-03-06 15:00:00', 'Scheduled', 'Round Robin'),
(7, 7, '2024-03-07 16:00:00', 'Scheduled', 'RR-E'),
(8, 8, '2024-03-08 17:00:00', 'Scheduled', 'RR-E'),
(9, 9, '2024-03-09 18:00:00', 'Scheduled', 'Regular Season'),
(10, 10, '2024-03-10 19:00:00', 'Scheduled', 'Regular Season');

-- Record the game results - Only team_ids 1-14 are valid
INSERT INTO game_team (game_id, team_id, score)
VALUES
(1, 1, 42), -- Birdie Bandits score
(1, 2, 39), -- Holy Strokes score
(3, 5, 36),
(4, 6, 38),
(5, 7, 34),
(6, 8, 35),
(7, 9, 37),
(8, 10, 33),
(9, 11, 32),
(10, 12, 39),
(11, 13, 30),
(12, 14, 31);