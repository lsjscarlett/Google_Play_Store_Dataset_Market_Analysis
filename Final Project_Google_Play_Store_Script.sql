DROP DATABASE IF EXISTS Google_Play_Store;
CREATE DATABASE Google_Play_Store;
USE Google_Play_Store;
CREATE TABLE Google_Play_Store.`Records` (
    `App` VARCHAR(300) DEFAULT NULL,
    `Category` VARCHAR(300) DEFAULT NULL,
    `Rating` DOUBLE DEFAULT NULL,
    `Reviews` INTEGER DEFAULT NULL,
    `Size` VARCHAR(300) DEFAULT NULL,
    `Installs` INTEGER DEFAULT NULL,
    `Type` VARCHAR(300) DEFAULT NULL,
    `Price` DOUBLE DEFAULT NULL,
    `Content_Rating` VARCHAR(300) DEFAULT NULL,
    `Genres` VARCHAR(300) DEFAULT NULL,
    `Last_Updated` DATE,
    `Current_Ver` VARCHAR(300) DEFAULT NULL,
    `Android_Ver` VARCHAR(300) DEFAULT NULL
);
TRUNCATE Google_Play_Store.Records;

LOAD DATA LOCAL INFILE '/Users/sijialiu/Desktop/Fall 2023/ITC 6000/final project/Google Play Store Apps/google_play_store_cleaned.csv'
INTO TABLE Google_Play_Store.Records
# Each column in a CSV file is separated by ','
FIELDS TERMINATED BY ',' 
# Each line in a CSV file is separated by '\n'
LINES TERMINATED BY '\n' 
# Because we want to ignore the header of the .csv file. If your .csv does not have a header remove this line
IGNORE 1 LINES; 

CREATE TABLE IF NOT EXISTS `App`(
   `App_ID` INT  AUTO_INCREMENT,
   `App_Name` VARCHAR(300) NOT NULL,
   PRIMARY KEY ( `App_ID` )
);
INSERT INTO `Google_Play_Store`.`App` (`App_Name`)
SELECT DISTINCT `App`
FROM `Google_Play_Store`.`Records`;

CREATE TABLE IF NOT EXISTS `Genres`(
   `Genre_ID` INT  AUTO_INCREMENT,
   `Genre_Name` VARCHAR(300) NOT NULL,
   PRIMARY KEY ( `Genre_ID` )
);
INSERT INTO `Google_Play_Store`.`Genres` (`Genre_Name`)
SELECT DISTINCT `Genres`
FROM `Google_Play_Store`.`Records`;

CREATE TABLE IF NOT EXISTS `Content`(
   `Content_ID` INT  AUTO_INCREMENT,
   `Content_Name` VARCHAR(300) NOT NULL,
   PRIMARY KEY ( `Content_ID` )
);
INSERT INTO `Google_Play_Store`.`Content` (`Content_Name`)
SELECT DISTINCT `Content_Rating`
FROM `Google_Play_Store`.`Records`;

CREATE TABLE IF NOT EXISTS `Category`(
   `Category_ID` INT  AUTO_INCREMENT,
   `Category_Name` VARCHAR(300) NOT NULL,
   PRIMARY KEY ( `Category_ID` )
);
INSERT INTO `Google_Play_Store`.`Category` (`Category_Name`)
SELECT DISTINCT `Category`
FROM `Google_Play_Store`.`Records`;

CREATE TABLE IF NOT EXISTS `Finance` (
   `Finance_ID` INT AUTO_INCREMENT,
   `Type` VARCHAR(300) DEFAULT NULL,
   `Price` DOUBLE DEFAULT NULL,
   `Installs` INTEGER DEFAULT NULL,
   `Size` VARCHAR(300) DEFAULT NULL,
   `App_ID` INT,
   PRIMARY KEY (`Finance_ID`),
   CONSTRAINT FK_App_ID FOREIGN KEY (`App_ID`) REFERENCES `App` (`App_ID`)
);
INSERT INTO `Finance` (`Type`, `Price`, `Installs`, `Size`, `App_ID`)
SELECT
    r.`Type`,
    r.`Price`,
    r.`Installs`,
    r.`Size`,
    a.`App_ID`
FROM
    `Records` r
JOIN
    `App` a ON r.`App` = a.`APP_Name`;
    
CREATE TABLE IF NOT EXISTS `Classification` (
   `Classification_ID` INT AUTO_INCREMENT,
   `Genre_ID` INT,
   `Content_ID` INT,
   `Category_ID` INT,
   `App_ID` INT,
   PRIMARY KEY (`Classification_ID`),
   CONSTRAINT FK_Genre_ID FOREIGN KEY (`Genre_ID`) REFERENCES `Genres` (`Genre_ID`),
   CONSTRAINT FK_Content_ID FOREIGN KEY (`Content_ID`) REFERENCES `Content` (`Content_ID`),
   CONSTRAINT FK_Category_ID FOREIGN KEY (`Category_ID`) REFERENCES `Category` (`Category_ID`),
   CONSTRAINT FK_App_ID_Classification FOREIGN KEY (`App_ID`) REFERENCES `App` (`App_ID`)
);
INSERT INTO `Classification` (`Genre_ID`, `Content_ID`, `Category_ID`, `App_ID`)
SELECT
    g.`Genre_ID`,
    c.`Content_ID`,
    cat.`Category_ID`,
    a.`App_ID`
FROM
    `Records` r
JOIN
    `App` a ON r.`App` = a.`App_Name`
JOIN
    `Genres` g ON r.`Genres` = g.`Genre_Name`
JOIN
    `Content` c ON r.`Content_Rating` = c.`Content_Name`
JOIN
    `Category` cat ON r.`Category` = cat.`Category_Name`;
    

CREATE TABLE IF NOT EXISTS `Environment` (
   `Environment_ID` INT AUTO_INCREMENT,
   `Android_Ver` VARCHAR(300) DEFAULT NULL,
   `Current_Ver` VARCHAR(300) DEFAULT NULL,
   `Last_Updated` DATE,
   `App_ID` INT,
   PRIMARY KEY (`Environment_ID`),
   CONSTRAINT FK_App_ID_Environment FOREIGN KEY (`App_ID`) REFERENCES `App` (`App_ID`)
);
INSERT INTO `Environment` (`Android_Ver`, `Current_Ver`, `Last_Updated`, `App_ID`)
SELECT
    r.`Android_Ver`,
    r.`Current_Ver`,
    r.`Last_Updated`,
    a.`App_ID`
FROM
    `Records` r
JOIN
    `App` a ON r.`App` = a.`App_Name`;
    
CREATE TABLE IF NOT EXISTS `Performance` (
   `Performance_ID` INT AUTO_INCREMENT,
   `Reviews` INTEGER DEFAULT NULL,
   `Rating` DOUBLE DEFAULT NULL,
   `App_ID` INT,
   PRIMARY KEY (`Performance_ID`),
   CONSTRAINT FK_App_ID_Performance FOREIGN KEY (`App_ID`) REFERENCES `App` (`App_ID`)
);
INSERT INTO `Performance` (`Reviews`, `Rating`, `App_ID`)
SELECT
    r.`Reviews`,
    r.`Rating`,
    a.`App_ID`
FROM
    `Records` r
JOIN
    `App` a ON r.`App` = a.`App_Name`;
	
/*
1. Find the most popular genres based on the number of installations:
*/
SELECT g.Genre_Name, SUM(r.Installs) AS Total_Installs
FROM Genres g
JOIN Classification cl ON g.Genre_ID = cl.Genre_ID
JOIN App a ON cl.App_ID = a.App_ID
JOIN Records r ON a.App_Name = r.App
GROUP BY g.Genre_Name
ORDER BY Total_Installs DESC
LIMIT 3;


/*
2. Identify the categories with the highest average user ratings (only considering apps with more than 100,000 reviews):
*/
SELECT cat.Category_Name, AVG(p.Rating) AS Average_Rating
FROM Category cat
JOIN Classification cl ON cat.Category_ID = cl.Category_ID
JOIN Performance p ON cl.App_ID = p.App_ID
WHERE p.Reviews > 100000
GROUP BY cat.Category_Name
ORDER BY Average_Rating DESC
LIMIT 10;


/*
3. Identify content ratings that have the highest number of highly rated apps (rating >= 4.5):
*/
SELECT c.Content_Name, COUNT(*) AS HighRatedAppCount
FROM Content c
JOIN Classification cl ON c.Content_ID = cl.Content_ID
JOIN Performance p ON cl.App_ID = p.App_ID
WHERE p.Rating >= 4.5
GROUP BY c.Content_Name
ORDER BY HighRatedAppCount DESC;

/*
4. Determine the top 10 most active categories based on the number of updates in the last year:
*/
SELECT cat.Category_Name, COUNT(*) AS UpdateCount
FROM Category cat
JOIN Classification cl ON cat.Category_ID = cl.Category_ID
JOIN Environment e ON cl.App_ID = e.App_ID
WHERE YEAR(e.Last_Updated) = 2018
GROUP BY cat.Category_Name
ORDER BY UpdateCount DESC
LIMIT 10;

/*
5. List the genres that have the most free versus paid apps:
*/
SELECT 
    g.Genre_Name,
    SUM(CASE WHEN r.Type = 'Free' THEN 1 ELSE 0 END) AS Free_Count,
    SUM(CASE WHEN r.Type = 'Paid' THEN 1 ELSE 0 END) AS Paid_Count
FROM Genres g
JOIN Classification cl ON g.Genre_ID = cl.Genre_ID
JOIN App a ON cl.App_ID = a.App_ID
JOIN Records r ON a.App_Name = r.App
GROUP BY g.Genre_Name
ORDER BY Free_Count DESC
LIMIT 10;


/*
6. Average rating and review count for apps in each category with different content ratings:
*/
SELECT cat.Category_Name, c.Content_Name, AVG(p.Rating) AS AverageRating, AVG(p.Reviews) AS AverageReviews
FROM Category cat
JOIN Classification cl ON cat.Category_ID = cl.Category_ID
JOIN Content c ON cl.Content_ID = c.Content_ID
JOIN Performance p ON cl.App_ID = p.App_ID
GROUP BY cat.Category_Name, c.Content_Name
ORDER BY AverageReviews DESC
LIMIT 10;

/*
7. Identify categories with the most diverse range of genres:
*/
SELECT cat.Category_Name, COUNT(DISTINCT g.Genre_ID) AS GenreDiversity
FROM Category cat
JOIN Classification cl ON cat.Category_ID = cl.Category_ID
JOIN Genres g ON cl.Genre_ID = g.Genre_ID
GROUP BY cat.Category_Name
ORDER BY GenreDiversity DESC;
