USE baby_names_db; -- select the schema 

SELECT * FROM regions;

SELECT Region, COUNT(State) as state_count
FROM regions
GROUP BY Region;

SELECT COUNT(State) as state_count
FROM regions;

-- Objective: Fix the Region inconsistency in the Region table.

ALTER TABLE regions
ADD PRIMARY KEY (State); -- adding a primary key sets NOT NULL automatically

UPDATE regions
SET Region = "New_England" -- correct naming convention
WHERE State = "NH";

/*Note: The primary key was set and the inconsistency was corrected. */

-- Objective: Add Michigan (MI) to the table.

INSERT INTO regions VALUES
("MI","Midwest");