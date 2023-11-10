-- Creating the table
DROP TEMPORARY TABLE IF EXISTS countries ;
CREATE TEMPORARY TABLE countries (countryName VARCHAR(100));

-- Inserting values
INSERT INTO countries VALUES
('United States America'),
('New Zeland'),
('United Kingdom');

-- Create a table that contains the numbers
DROP TEMPORARY TABLE IF EXISTS numberList ;
CREATE TEMPORARY TABLE numberList (indexing INT);
INSERT INTO numberList VALUES (1),(2),(3),(4),(5),(6);

-- Deriving the substrings
SELECT	SUBSTRING_INDEX(SUBSTRING_INDEX(countries.countryName, ' ', numberList.indexing), ' ', -1) countryName, 
		countries.countryName as Country,
        numberList.indexing
FROM numberList
INNER JOIN countries
ON CHAR_LENGTH(countries.countryName) -CHAR_LENGTH(REPLACE(countries.countryName, ' ', '')) >= numberList.indexing - 1
ORDER BY Country DESC;