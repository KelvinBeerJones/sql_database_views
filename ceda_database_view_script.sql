-- Views begin with the person_table

-- Make basic view of person_table without ID column, with first_names and last_name AS Name, and IF NULL AS 'NA'
DROP VIEW [vw_hddt_person_tables];

CREATE VIEW [vw_hddt_person_table]
AS
SELECT (first_names || " " || family_name) AS Name, 
IFNULL(title,'NA') AS title, 
IFNULL(gender_id,'NA') AS gender_id, 
IFNULL(birth_year,'NA') AS birth_year, 
IFNULL(death_year,'NA') AS death_year, 
data_source_id, 
notes
FROM person;

SELECT *
FROM vw_hddt_person_table;


-- Make a 'Names' table from vw_hddt_person_table
DROP VIEW [vw_hddt_person_name];

CREATE VIEW vw_hddt_person_name
AS 
SELECT DISTINCT Name
FROM vw_hddt_person_table;



-- Add attributes from the person_table
DROP VIEW [vw_hddt_person_attributes];

CREATE VIEW [vw_hddt_person_attributes]
AS 
SELECT Name, birth_year, death_year
FROM vw_hddt_person_table;

-----------------------------------------------------------------------------------------------------------------------------------------------
-- Quakers

--add religion to the person_table Name attributes (no person has 2 religions)
DROP VIEW [vw_hddt_person_attributes_religion];

CREATE VIEW [vw_hddt_person_attributes_religion] 
AS 
SELECT (first_names || " " || family_name) AS Name, 
	IFNULL(birth_year,'NA') AS birth_year, 
	IFNULL(death_year,'NA') AS death_year, 
	IFNULL(religion_id,'NA') AS religion_1_quaker
FROM person
LEFT JOIN m2m_person_religion
ON person.id = m2m_person_religion.person_id;

-- Quakers only

DROP VIEW [vw_hddt_quakers];

CREATE VIEW [vw_hddt_quakers]
AS 
SELECT Name, 
	IFNULL(birth_year,'NA') AS birth_year, 
	IFNULL(death_year,'NA') AS death_year
FROM vw_hddt_person_attributes_religion 
WHERE religion_1_quaker = 1;
	

-- quakers person to person relationships. This is a 3 part build!

--this view contributes to person1_person2 DO NOT DELETE
DROP VIEW vw_hddt_person1;

Create VIEW vw_hddt_person1
AS
SELECT
		m2m_person_person.id,
		m2m_person_person.relationship_type_id, 
		m2m_person_person.person1_id,
		(person.first_names || " " || person.family_name) AS person1_name 
FROM m2m_person_person, person
WHERE m2m_person_person.person1_id = person.id;

--this view contributes to person1_person2 DO NOT DELETE
DROP VIEW vw_hddt_person2;

Create VIEW vw_hddt_person2
AS
SELECT
		m2m_person_person.id,
		m2m_person_person.person2_id,
		(person.first_names || " " || person.family_name) AS person2_name 
FROM m2m_person_person, person
WHERE m2m_person_person.person2_id = person.id;

-- This view combines person1 with person2
DROP VIEW vw_hddt_person1_person2;

CREATE VIEW vw_hddt_person1_person2
AS
SELECT
	vw_5_person1.person1_name AS "Source",
	vw_5_person2.person2_name AS "Target",
	vw_5_person1.relationship_type_id AS "relationship_type_id"
FROM vw_5_person1
LEFT JOIN vw_5_person2
ON vw_5_person1.id = vw_5_person2.id; 


               
-- These three views capture each relationship type               
DROP VIEW vw_hddt_person_person_distant;

CREATE VIEW vw_hddt_person_person_distant
AS
SELECT 'Source', Target, relationship_type_id AS 'distant'
FROM vw_5_person1_person2
WHERE vw_5_person1_person2.relationship_type_id = 1;



DROP VIEW vw_hddt_person_person_close;

CREATE VIEW vw_hddt_person_person_close
AS
SELECT 'Source', Target, relationship_type_id AS 'close'
FROM vw_5_person1_person2
WHERE vw_5_person1_person2.relationship_type_id = 2;


DROP VIEW vw_hddt_person_person_immediate;

CREATE VIEW vw_hddt_person_person_immediate
AS
SELECT 'Source', Target, relationship_type_id AS 'immediate'
FROM vw_5_person1_person2
WHERE vw_5_person1_person2.relationship_type_id = 3;               

---------------------------------------------------------------------------------------------------------------------------------------
--ceda


DROP VIEW vw_hddt_ceda_tuples; 

CREATE VIEW IF NOT EXISTS vw_hddt_ceda_tuples as 
SELECT (p.first_names || " " || p.family_name) AS Source, c.name AS Target 
FROM m2m_person_ceda m, person p, ceda c 
WHERE m.person_id = p.id AND m.ceda_id = c.id; 

SELECT * 
FROM vw_hddt_ceda_tuples
WHERE vw_hddt_ceda_tuples.Target = 'QCA';



DROP VIEW [vw_hddt_ceda_tuples_attributes]; 

CREATE VIEW vw_hddt_ceda_tuples_attributes
AS 
SELECT (first_names || " " || family_name) AS 'Source',
       ceda.name AS Target,
       m2m_person_ceda.first_year AS first_year,
       m2m_person_ceda.last_year AS last_year, 
       IFNULL(birth_year,'NA') AS birth_year, 
		IFNULL(death_year, 'NA') AS death_year
FROM person
INNER JOIN m2m_person_ceda
                ON m2m_person_ceda.person_id = person.id
LEFT JOIN ceda 
                ON ceda.id = m2m_person_ceda.ceda_id 
WHERE 
                m2m_person_ceda.first_year IS NOT NULL
                AND
                m2m_person_ceda.last_year IS NOT NULL;
               
               
     
     
DROP VIEW [vw_hddt_ceda_name_attributes]; 

CREATE VIEW vw_hddt_ceda_name_attributes
AS 
SELECT (first_names || " " || family_name) AS 'Name',
		IFNULL(m2m_person_religion.religion_id,'NA') AS quaker,
       m2m_person_ceda.first_year AS first_year,
       m2m_person_ceda.last_year AS last_year, 
       IFNULL(birth_year,'NA') AS birth_year, 
		IFNULL(death_year, 'NA') AS death_year
FROM person
INNER JOIN m2m_person_ceda
ON m2m_person_ceda.person_id = person.id
LEFT JOIN m2m_person_religion
ON m2m_person_religion.person_id = person.id
WHERE m2m_person_ceda.first_year IS NOT NULL AND m2m_person_ceda.last_year IS NOT NULL;    
     
     
     
-- quakers in the CEDA
DROP VIEW [vw_hddt_quakers_ceda_tuples]; 

CREATE VIEW vw_hddt_quakers_ceda_tuples
AS 
SELECT (first_names || " " || family_name) AS 'Source',
       ceda.name AS Target,
       IFNULL(religion.name,'NA') AS religion_name,
       m2m_person_ceda.first_year AS first_year,
       m2m_person_ceda.last_year AS last_year      
FROM person
INNER JOIN m2m_person_religion
                ON m2m_person_religion.person_id = person.id
LEFT JOIN religion
                ON religion.id = m2m_person_religion.religion_id
INNER JOIN m2m_person_ceda
                ON m2m_person_ceda.person_id = person.id
LEFT JOIN ceda 
                ON ceda.id = m2m_person_ceda.ceda_id 
WHERE 
                m2m_person_ceda.first_year IS NOT NULL
                AND
                m2m_person_ceda.last_year IS NOT NULL;
               
 ----------------------------------------------------------------------------------------------------------------------------------
 -- Bigraph views
 
 DROP VIEW vw_hddt_society_tuples; 

CREATE VIEW vw_hddt_society_tuples as 
SELECT (p.first_names || " " || p.family_name) AS Source, s.name AS Target  
FROM m2m_person_society m, person p, society s 
WHERE m.person_id = p.id AND m.society_id = s.id;


 DROP VIEW vw_hddt_club_tuples; 

CREATE VIEW vw_hddt_club_tuples as 
SELECT (p.first_names || " " || p.family_name) AS Source, c.name AS Target  
FROM m2m_person_club m, person p, club c 
WHERE m.person_id = p.id AND m.club_id = c.id;           
               

DROP VIEW vw_hddt_location_tuples; 

CREATE VIEW IF NOT EXISTS vw_hddt_location_tuples as 
SELECT (p.first_names || " " || p.family_name) AS Source, l.name AS Target  
FROM m2m_person_location m, person p, location l 
WHERE m.person_id = p.id AND m.location_id = l.id;


DROP VIEW vw_hddt_occupation_tuples; 

CREATE VIEW IF NOT EXISTS vw_hddt_occupation_tuples as 
SELECT (p.first_names || " " || p.family_name) AS Source, o.name AS Target  
FROM m2m_person_occupation m, person p, occupation o 
WHERE m.person_id = p.id AND m.occupation_id = o.id;



DROP VIEW vw_hddt_religion_tuples; 

CREATE VIEW vw_hddt_religion_tuples as 
SELECT (p.first_names || " " || p.family_name) AS Source, r.name AS Target  
FROM m2m_person_religion m, person p, religion r 
WHERE m.person_id = p.id AND m.religion_id = r.id; 



DROP VIEW vw_hddt_all_bigraph_tuples;

CREATE VIEW vw_hddt_all_bigraph_tuples
AS 
SELECT * FROM vw_hddt_ceda_tuples
UNION
SELECT * FROM vw_hddt_society_tuples
UNION
SELECT * FROM vw_hddt_club_tuples
UNION
SELECT * FROM vw_hddt_location_tuples
UNION
SELECT * FROM vw_hddt_occupation_tuples
UNION
SELECT * FROM vw_hddt_religion_tuples;




DROP VIEW [vw_hddt_bigraph_nodes];

CREATE VIEW [vw_hddt_bigraph_nodes]
AS
SELECT name AS Name FROM ceda
UNION
SELECT name AS Name FROM club
UNION
SELECT name AS Name FROM society
UNION
SELECT name AS Name FROM religion
UNION
SELECT name AS Name FROM occupation
UNION
SELECT name AS Name FROM location;

-- combine persons with bigraph data

DROP VIEW vw_hddt_all_names_and_nodes; 

CREATE VIEW vw_hddt_all_names_and_nodes 
AS
SELECT Name FROM vw_hddt_person_name
UNION
SELECT Name FROM vw_hddt_bigraph_nodes;

-- END
