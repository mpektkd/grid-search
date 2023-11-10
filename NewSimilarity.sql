	SET @new_mls = 'catcaor' COLLATE utf8mb4_unicode_ci;
	SET @mls_url = 'paragonrels' COLLATE utf8mb4_unicode_ci;
    
	DROP TABLE IF EXISTS SimilarityCount ;
	CREATE TEMPORARY TABLE SimilarityCount (
		id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
		ResourceID	NVARCHAR(100),
		Plurality	INT,
        Weight		DOUBLE
	);
    
    DROP TABLE IF EXISTS ResourceClasses ;
	CREATE TEMPORARY TABLE ResourceClasses (
		id 					INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
		ResourceID			NVARCHAR(100),
        ClassName			NVARCHAR(50),
        ClassDescription	NVARCHAR(50)
	);
    
    DROP TABLE IF EXISTS MatchedResourceClasses ;
	CREATE TEMPORARY TABLE MatchedResourceClasses (
		id 							INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
		created_at 					DATETIME,
		Similarsource_id 			INT, 
		SimilarName 				NVARCHAR(50),
		SimilarResourceID 			NVARCHAR(50),
		NewResourceID 				NVARCHAR(50), 
		SimilarClassName 			NVARCHAR(50),
		NewClassName 				NVARCHAR(50),  
		SimilarClassDescription 	NVARCHAR(50),
		NewClassDescription			NVARCHAR(50)
	);
    
    DROP TABLE IF EXISTS CountPerResource ;
	CREATE TEMPORARY TABLE CountPerResource (
		id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
		Plurality INT,
		SimilarName NVARCHAR(50), 
		SimilarResourceID NVARCHAR(50)
	);
    
    INSERT INTO SimilarityCount(ResourceID, Plurality)
	SELECT 
			metadata_resources.ResourceID, COUNT(*) AS Plurality 
	FROM	sources
			INNER JOIN	metadata_resources ON sources.id = metadata_resources.source_id
			INNER JOIN	metadata_classes ON metadata_resources.id = metadata_classes.resource_id
	WHERE	mls_name = @new_mls
	GROUP BY metadata_resources.ResourceID;
    
    SET @PropertyWeight = 0.7;
    UPDATE SimilarityCount
    SET Weight = @PropertyWeight
    WHERE	ResourceID = 'Property';
    
    SET @N = ( SELECT	COUNT(*) AS TotalResources	FROM	SimilarityCount);
    UPDATE SimilarityCount
    SET Weight = @PropertyWeight / (@N - 1)
    WHERE	ResourceID != 'Property';
    
    INSERT INTO ResourceClasses(ResourceID, ClassName, ClassDescription)
	SELECT 
			metadata_resources.ResourceID AS ResourceID,
			metadata_classes.ClassName AS ClassName,
			metadata_classes.Description AS class_description
	FROM	configurations
			INNER JOIN	sources ON configurations.source_id = sources.id
			INNER JOIN	metadata_resources ON configurations.source_id = metadata_resources.source_id
			INNER JOIN	metadata_classes ON metadata_resources.id = metadata_classes.resource_id
	WHERE	configurations.name = @new_mls ;
	
	/* FIND MOST SIMILAR MLS */
	INSERT INTO MatchedResourceClasses (created_at,	Similarsource_id, SimilarName, SimilarResourceID, NewResourceID, SimilarClassName, NewClassName, SimilarClassDescription, NewClassDescription)
	SELECT 
			sources.created_at,
			sources.id AS Similarsource_id, 
			sources.mls_name AS SimilarName,
			metadata_resources.ResourceID AS SimilarResourceID,
			ResourceClasses.ResourceID AS NewResourceID, 
			metadata_classes.ClassName AS SimilarClassName,
			ResourceClasses.ClassName AS NewClassName, 
			metadata_classes.Description AS SimilarClassDescription,
			ResourceClasses.ClassDescription AS NewClassDescription
			-- count(*)
	FROM	configurations
			INNER JOIN	sources ON configurations.source_id = sources.id
			INNER JOIN	metadata_resources ON configurations.source_id = metadata_resources.source_id
			INNER JOIN	metadata_classes ON metadata_resources.id = metadata_classes.resource_id
			INNER JOIN	ResourceClasses ON	ResourceClasses.ResourceID = metadata_resources.ResourceID 
											AND
											(
												ResourceClasses.ClassDescription LIKE CONCAT('%', metadata_classes.Description  ,'%') 
												OR 
												metadata_classes.Description LIKE CONCAT('%', ResourceClasses.ClassDescription  ,'%') 
											)
	WHERE	
			-- login_url LIKE CONCAT('%', @mls_url, '%') AND
			configurations.name != @new_mls AND
            sources.status = 1 AND
			-- configurations.name = 'akseamls' AND
			1=1
	ORDER BY mls_name ASC, ResourceClasses.ResourceID;
        
	SELECT	*
    FROM	MatchedResourceClasses;
    
	INSERT INTO CountPerResource(Plurality,	SimilarName, SimilarResourceID)
    SELECT 
			COUNT(*) AS Plurality,
			SimilarName, 
			SimilarResourceID
	FROM	MatchedResourceClasses
	GROUP BY SimilarName, SimilarResourceID
	ORDER BY MatchedResourceClasses.SimilarName ASC, MatchedResourceClasses.SimilarResourceID ASC, COUNT(*) DESC, MatchedResourceClasses.created_at DESC;
            
	SELECT 	
			CountPerResource.Plurality / SimilarityCount.Plurality * 100 AS MatchedPercentage, SimilarName,
            SimilarResourceID, ResourceID
    FROM	CountPerResource
			INNER JOIN SimilarityCount ON SimilarityCount.ResourceID=CountPerResource.SimilarResourceID
            -- WHERE	ResourceID='Property'
            ORDER BY SimilarName ASC, MatchedPercentage DESC
            -- HAVING MathcedPercentage > 100
            ;
    
	SELECT 	
			SUM(WeightMatchedPercentage) * 100 AS TotalMatchedPercentage, SimilarName, sources.created_at,
			configurations.login_url
    FROM	(
					SELECT 	
							CountPerResource.Plurality / SimilarityCount.Plurality * Weight AS WeightMatchedPercentage, SimilarName,
							SimilarResourceID, ResourceID
					FROM	CountPerResource
							INNER JOIN SimilarityCount ON SimilarityCount.ResourceID=CountPerResource.SimilarResourceID
			) AS Weighted 
            INNER JOIN sources ON sources.mls_name=Weighted.SimilarName
            INNER JOIN configurations ON configurations.source_id=sources.id
            GROUP BY SimilarName
            ORDER BY TotalMatchedPercentage DESC, sources.created_at DESC
            -- HAVING MathcedPercentage > 100
            ;
    
    
    SET @total = (SELECT SUM(Plurality) FROM SimilarityCount);
    
    SELECT 	
			SUM(CountPerResource.Plurality) / @total * 100 AS MatchedPercentage, SimilarName, sources.created_at,
			configurations.login_url
    FROM	CountPerResource
			INNER JOIN SimilarityCount ON SimilarityCount.ResourceID=CountPerResource.SimilarResourceID
            INNER JOIN sources ON sources.mls_name=CountPerResource.SimilarName
            INNER JOIN configurations ON configurations.source_id=sources.id
            GROUP BY SimilarName
            ORDER BY MatchedPercentage DESC, sources.created_at DESC
            -- HAVING MathcedPercentage > 100
            ;
    