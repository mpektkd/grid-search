 
-- grid --> OriginationName --> metadata_fields
-- trestle --> OriginationName --> no metadata_fields
-- bridge --> login_url --> no metadata_fields
-- spark --> password --> no metadata_fields 
  
  call find_class_similarity('fldglar', 'navicamls');
  call find_class_similarity2('fldglar', 'navicamls');

-- SET SQL_SAFE_UPDATES = 0;
	-- COLLATE utf8mb4_unicode_ci;
    SET @new_mls = 'fldglar' COLLATE utf8mb4_unicode_ci;
    SET @similar_mls = 'vaesar' COLLATE utf8mb4_unicode_ci;
    
    SET @auth_type = 'RETS' COLLATE utf8mb4_unicode_ci;
    
    SET @OriginationName = '' COLLATE utf8mb4_unicode_ci;
	
    SET @source_id = (SELECT id FROM sources WHERE mls_name=@new_mls);
    SET @similar_source_id = (SELECT id FROM sources WHERE mls_name=@similar_mls); 
    
	-- COLLATE utf8mb4_unicode_ci;

	DROP TABLE IF EXISTS TMP ;
	CREATE TEMPORARY TABLE TMP (
		id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
		source_id INT,
		new_source_id INT,
		mls_name NVARCHAR(50),
		new_mls_name NVARCHAR(50),
		ResourceID NVARCHAR(50),
        NewResourceID NVARCHAR(50),
        class_id INT,
		new_class_id INT,
		ClassNameDescription NVARCHAR(50),
		NewClassNameDescription NVARCHAR(50),
        New_SystemName	NVARCHAR(100),
        New_LongName	NVARCHAR(100),
		internal_field	NVARCHAR(100),
		Old_SystemName	NVARCHAR(100),
        Old_LongName	NVARCHAR(100),
        Official_Old_SystemName	NVARCHAR(100)
	);
    
    DROP TABLE IF EXISTS TMPClassNames ;
	CREATE TEMPORARY TABLE TMPClassNames (
		ResourceID			 NVARCHAR(50),
		ClassNameDescription NVARCHAR(50)
	);
        
	DROP TEMPORARY TABLE IF EXISTS Splits ;
	CREATE TEMPORARY TABLE Splits (indexing INT);
	INSERT INTO Splits VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

	DROP TEMPORARY TABLE IF EXISTS Mls_LongNames ;
	CREATE TEMPORARY TABLE Mls_LongNames (
		id INT,
        class_id INT,
        ClassNameDescription	nvarchar(100),
        SystemName	nvarchar(100),
        LongName	nvarchar(100)
    );
            
	DROP TEMPORARY TABLE IF EXISTS SplitedNames ;
	CREATE TEMPORARY TABLE SplitedNames (
		id INT,
        class_id INT,
        ClassNameDescription	nvarchar(100),
        SystemName	nvarchar(100),
        LongName	nvarchar(100),
        SplitedName	nvarchar(100),
        indexing	INT
    );

	DROP TEMPORARY TABLE IF EXISTS GridSearchMatches ;
	CREATE TEMPORARY TABLE GridSearchMatches (
		LongNameRatio DOUBLE, 
        InternalFieldRatio DOUBLE,
		LongNameMatches INT, 
        InternalFieldMatches INT, 
		id INT,  
        class_id INT,  
        ClassNameDescription NVARCHAR(100), 
        SystemName NVARCHAR(100), 
        LongName NVARCHAR(100), 
        SplitedName NVARCHAR(100), 
        indexing INT, 
        internal_field NVARCHAR(100), 
        Old_LongName NVARCHAR(100), 
        mls_field NVARCHAR(100)
    );
	
    DROP TEMPORARY TABLE IF EXISTS Mapping ;
    CREATE TEMPORARY TABLE Mapping ( 
		id INT,  
        class_id INT,  
        ClassNameDescription NVARCHAR(100), 
        SystemName NVARCHAR(100),  
        LongName NVARCHAR(100), 
        internal_field NVARCHAR(100),  
        mls_field NVARCHAR(100),
        Old_LongName NVARCHAR(100)
    );
	
	DROP TEMPORARY TABLE IF EXISTS Dublicates ;
    CREATE TEMPORARY TABLE Dublicates ( 
		Quantity INT,
        class_id INT,  
        ClassNameDescription NVARCHAR(100), 
        internal_field NVARCHAR(100)
    );
	
    DROP TEMPORARY TABLE IF EXISTS CorrectedMapping ;
    CREATE TEMPORARY TABLE CorrectedMapping ( 
		id INT,  
        class_id INT,  
        ClassNameDescription NVARCHAR(100), 
        SystemName NVARCHAR(100),  
        LongName NVARCHAR(100), 
        internal_field NVARCHAR(100),  
        mls_field NVARCHAR(100),
        Old_LongName NVARCHAR(100)
    );

	DROP TABLE IF EXISTS FinalMapping ;
	CREATE TEMPORARY TABLE FinalMapping (
		id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
		source_id INT,
		new_source_id INT,
		mls_name NVARCHAR(50),
		new_mls_name NVARCHAR(50),
		ResourceID NVARCHAR(50),
        NewResourceID NVARCHAR(50),
		class_id INT,
		new_class_id INT,
		ClassNameDescription NVARCHAR(50),
		NewClassNameDescription NVARCHAR(50),
        New_SystemName	NVARCHAR(100),
        New_LongName	NVARCHAR(100),
		internal_field	NVARCHAR(100),
		Old_SystemName	NVARCHAR(100),
        Old_LongName	NVARCHAR(100),
        Official_Old_SystemName	NVARCHAR(100)
	);
    
	DROP TABLE IF EXISTS Map ;
	CREATE TEMPORARY TABLE Map (
		id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
		new_class_id INT,
        New_SystemName	NVARCHAR(100),
		internal_field	NVARCHAR(100),
		Old_SystemName	NVARCHAR(100)
	);
    
    
	-- COLLATE utf8mb4_unicode_ci;

	/**
		Populate TMP table with the data from similar MLS
	*/
	INSERT INTO TMP (source_id, mls_name, ResourceID, class_id, ClassNameDescription, internal_field)
	SELECT 
		sources.id,
		sources.mls_name,
        metadata_resources.ResourceID,
		metadata_classes.id AS class_id,
		metadata_classes.Description,
		source_default_mapping.internal_field
	FROM
		sources
			JOIN
		source_default_mapping ON sources.id = source_default_mapping.source_id
			JOIN
		metadata_classes ON source_default_mapping.class_id = metadata_classes.id
			JOIN
		metadata_resources ON metadata_resources.id = metadata_classes.resource_id
	WHERE
		mls_name = @similar_mls;
        

	-- COLLATE utf8mb4_unicode_ci;
	/*
		Essential updates and different class mappings
	*/
	INSERT INTO TMPClassNames(ClassNameDescription, ResourceID)
    SELECT	DISTINCT ClassNameDescription, ResourceID
    FROM	TMP;
    
--     DELETE FROM TMP
--     WHERE	ResourceID != 'Property'
-- 			OR ClassNameDescription != 'RESIDENTIAL';
--           
-- 	SELECT	*
-- 	FROM	TMP;

-- 	UPDATE TMP
--     SET NewClassNameDescription='SINGLE FAMILY SITE BUILT',
-- 		NewResourceID='Property';
--         
-- 	SELECT	*
-- 	FROM	vu_Resources_Classes
-- 	WHERE	mls_name = 'catcaor';

    -- We take as granted that the TMP/metadata_classes.(ClassName)Description is unique 
    -- Wrong assumption there are same classes among resources
    SELECT	CONCAT('%', SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(TMPClassNames.ClassNameDescription, '[^A-Za-z]+', ' ')), ' ', 1) ,'%')
    FROM	TMPClassNames;
    
	UPDATE TMP
    TMPClassNames
    INNER JOIN (
		SELECT	metadata_classes.*, metadata_resources.ResourceID
		FROM	metadata_classes 
				JOIN metadata_resources ON metadata_classes.resource_id=metadata_resources.id
				-- JOIN metadata_fields ON metadata_fields.class_id=metadata_classes.id
		WHERE	metadata_resources.source_id=@source_id
    )AS new_classes 
	ON	(
			TMPClassNames.ClassNameDescription LIKE CONCAT('%', SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(new_classes.Description, '[^A-Za-z]+', ' ')), ' ', 1) ,'%') -- just for sample we take 1st word
		OR 
			new_classes.Description LIKE CONCAT('%', SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(TMPClassNames.ClassNameDescription, '[^A-Za-z]+', ' ')), ' ', 1) ,'%')
		)
		AND	TMPClassNames.ResourceID = new_classes.ResourceID    
	SET NewClassNameDescription=new_classes.Description,
		NewResourceID=new_classes.ResourceID;
    
    SELECT	*
    FROM	TMP;

-- select * from metadata_classes
	
	UPDATE  TMP 
	JOIN metadata_classes ON	TMP.NewClassNameDescription = metadata_classes.Description
	JOIN metadata_resources ON metadata_classes.resource_id=metadata_resources.id
								AND TMP.NewResourceID = metadata_resources.ResourceID
	JOIN sources ON metadata_resources.source_id = sources.id
	SET 
		TMP.new_source_id=sources.id,
		TMP.new_mls_name=sources.mls_name,
		TMP.new_class_id=metadata_classes.id
	WHERE sources.id=@source_id;

SELECT	*
FROM	TMP ;

	/*
    
		This part does not work for API, as there is no records in metadata_fields
        for API feeds. 

		
    */

    
	INSERT INTO Mls_LongNames(id, class_id, ClassNameDescription, SystemName, LongName)
    SELECT	
			metadata_fields.id,
            metadata_fields.class_id,
            metadata_classes.Description,
            metadata_fields.SystemName,
            metadata_fields.LongName
    FROM	metadata_fields
			INNER JOIN metadata_classes ON metadata_fields.class_id=metadata_classes.id
            INNER JOIN metadata_resources ON metadata_resources.id=metadata_classes.resource_id
	WHERE	source_id = @source_id;
    
    -- Here we will distinguish cases, based on New_SystemName or not.  -- 
        
    INSERT INTO SplitedNames(id, class_id, ClassNameDescription, SystemName, LongName, SplitedName, indexing)
    SELECT	
			Mls_LongNames.*,
            TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(REGEXP_REPLACE(Mls_LongNames.LongName, '[^A-Za-z0-9]+', ' ')), ' ', Splits.indexing), ' ', -1)) SplitedName, 
			Splits.indexing
	FROM Splits
	INNER JOIN Mls_LongNames
	ON CHAR_LENGTH(TRIM(REGEXP_REPLACE(Mls_LongNames.LongName, '[^A-Za-z0-9]+', ' '))) - CHAR_LENGTH(REGEXP_REPLACE(TRIM(REGEXP_REPLACE(Mls_LongNames.LongName, '[^A-Za-z0-9]+', ' ')), ' ', '')) >= Splits.indexing - 1
	ORDER BY SystemName DESC, class_id ASC, indexing ASC;

    
	/* 
		Remove short words , in order to avoid voting in gridsearch
        We keep number, so in case that we have numbered field the partition(fraction) 
		further down gives us the answer and avoid dublicates
        */
    DELETE 
    FROM	SplitedNames
    WHERE	CHAR_LENGTH(SplitedName) <= 2 
			AND SplitedName REGEXP '[^0-9]'; 
    
  --   SELECT * FROM SplitedNames;
    
   --  SELECT * FROM GridSearchMatches;
    /* 
		We search which SplitedNames are matched better into the given internal_fields 
		Although, the comparion becomes through LongNames of the old Feed, because of the more descriptiveness
        
        We group by GridSearch.id, GridSearch.Old_LongName, GridSearch.interna_field, in case we need to match the same SystemName in diferrent internal_fieldsin ordr to match the same 
    */
	INSERT INTO GridSearchMatches
	SELECT	
            NULL,
            NULL,
			COUNT(*) LongNameMatches,
            NULL,
			GridSearch.*
	FROM	(
		SELECT	
				SplitedNames.*,
				TMP.internal_field,
				metadata_fields.LongName AS Old_LongName,
				source_default_mapping.mls_field
		FROM	SplitedNames
				INNER JOIN TMP ON	TMP.new_class_id=SplitedNames.class_id 
							-- AND	TMP.internal_field LIKE CONCAT('%', SplitedNames.SplitedName, '%') -- it causes the gridsearch
				INNER JOIN	source_default_mapping ON source_default_mapping.internal_field=TMP.internal_field
							AND TMP.class_id=source_default_mapping.class_id
							AND TMP.source_id=source_default_mapping.source_id
				INNER JOIN	metadata_fields ON metadata_fields.SystemName=source_default_mapping.mls_field
							AND metadata_fields.class_id=source_default_mapping.class_id
							AND metadata_fields.Longname LIKE CONCAT('%', SplitedNames.SplitedName , '%')
		WHERE	TMP.new_source_id=@source_id
		ORDER BY SplitedNames.class_id ASC, SystemName ASC, indexing ASC
	) AS GridSearch
	GROUP BY GridSearch.id, GridSearch.Old_LongName, GridSearch.internal_field
	-- GridSearch.internal_field
	ORDER BY SplitedNames.class_id ASC, SystemName ASC, indexing ASC;
    -- SELECT  REGEXP_LIKE('Agent Email', 'Email') 

UPDATE GridSearchMatches
INNER JOIN (
	
    SELECT	
			COUNT(*) InternalFieldMatches, GridSearch.id, GridSearch.Old_LongName, GridSearch.internal_field
	FROM	(
		SELECT	
				SplitedNames.*,
				TMP.internal_field,
				metadata_fields.LongName AS Old_LongName,
				source_default_mapping.mls_field
		FROM	SplitedNames
				INNER JOIN TMP ON	TMP.new_class_id=SplitedNames.class_id 
							AND	TMP.internal_field LIKE CONCAT('%', SplitedNames.SplitedName, '%') -- it causes the gridsearch
				INNER JOIN	source_default_mapping ON source_default_mapping.internal_field=TMP.internal_field
							AND TMP.class_id=source_default_mapping.class_id
							AND TMP.source_id=source_default_mapping.source_id
				INNER JOIN	metadata_fields ON metadata_fields.SystemName=source_default_mapping.mls_field
							AND metadata_fields.class_id=source_default_mapping.class_id
							-- AND metadata_fields.Longname LIKE CONCAT('%', SplitedNames.SplitedName , '%')
		WHERE	TMP.new_source_id=@source_id
		ORDER BY SplitedNames.class_id ASC, SystemName ASC, indexing ASC
	) AS GridSearch
	GROUP BY GridSearch.id, GridSearch.Old_LongName, GridSearch.internal_field
    
)AS GridSearchInternalMatches	ON GridSearchInternalMatches.id=GridSearchMatches.id 
								AND GridSearchInternalMatches.Old_LongName=GridSearchMatches.Old_LongName
                                AND GridSearchInternalMatches.internal_field=GridSearchMatches.internal_field
SET	GridSearchMatches.InternalFieldMatches = GridSearchInternalMatches.InternalFieldMatches;

SELECT	*
FROM 	TMP;

	
/* Second Version -- Apply Statistic Normalization */
-- SET @Average = ( SELECT SUM(Matches) / COUNT(*) FROM GridSearchMatches );
-- SET @Deviation = (
-- 		SELECT	SQRT(SUM(SquaredDiff) / COUNT(SquaredDiff)) 
--         FROM	(
-- 			SELECT	POW(Matches - @Average, 2) AS SquaredDiff
-- 			FROM	GridSearchMatches 
-- 		)AS SquaredDiffs
--     );

-- SET @Deviation = (
-- 		SELECT	SUM(AbsDiff) / COUNT(AbsDiff)
--         FROM	(
-- 			SELECT	ABS(Matches - @Average) AS AbsDiff
-- 			FROM	GridSearchMatches 
-- 		)AS AbsDiffs
--     );
    
    
    -- SELECT * FROM GridSearchMatches ORDER BY internal_field DESC, class_id DESC;
    
    UPDATE	GridSearchMatches
	INNER JOIN (
			SELECT	COUNT(*) AS Splits, id
			FROM	SplitedNames
			GROUP BY id
        )AS MaxSplits ON MaxSplits.id=GridSearchMatches.id
        SET GridSearchMatches.LongNameRatio = (GridSearchMatches.LongNameMatches / Splits),
			GridSearchMatches.InternalFieldRatio = (IFNULL(GridSearchMatches.InternalFieldMatches, 0) / Splits);
    

    /* 
		Based on Matches per each class_id, internal_field, we map the SystemName with the max matches
        
        Partition by () order by Rqatio, Matches. When a ratio tie happens, we take the one with the most matches.
        
        */
	INSERT INTO Mapping
	SELECT	
			OrderedTupleCounts.id,
            OrderedTupleCounts.class_id,
            OrderedTupleCounts.ClassNameDescription,
            OrderedTupleCounts.SystemName,
            OrderedTupleCounts.LongName,
            OrderedTupleCounts.internal_field,
            OrderedTupleCounts.mls_field,
            OrderedTupleCounts.Old_LongName
	FROM	(
		SELECT 
				RANK() OVER (
							PARTITION BY class_id, internal_field -- we search map for the tuple (class_id, internal_field)
							ORDER BY LongNameRatio DESC, LongNameMatches DESC, InternalFieldRatio DESC, InternalFieldMatches DESC   
						)AS row_num,
				GridSearchMatches.*
		FROM	GridSearchMatches
                -- WHERE	GridSearchMatches.Matches >= @Average-- It cuts outliers from mapping, in order to avoid dublicates
                -- WHERE	GridSearchMatches.Matches BETWEEN @Average - @Deviation AND @Average + @Deviation -- Second Version
		)AS OrderedTupleCounts
		WHERE	OrderedTupleCounts.row_num = 1 ;

/*   
	
    Many to Many in Mapping for (id, internal_field)
	
*/
-- 	SELECT	COUNT(*)
--     FROM	Mapping
--     GROUP BY ID
--     HAVING	COUNT(*) > 1;

	INSERT INTO Dublicates
	SELECT 	COUNT(*) AS Quantity, class_Id, ClassNameDescription, internal_field
	FROM	Mapping
	GROUP BY class_id, internal_field
	HAVING COUNT(*) > 1
	ORDER BY class_id ASC, internal_field ASC;

-- 	INSERT INTO CorrectedMapping
-- 	SELECT	*
-- 	FROM	Mapping
-- 			INNER JOIN Dublicates ON	Dublicates.class_id=Mapping.class_id
-- 								AND Dublicates.internal_field=Mapping.internal_field
-- 			WHERE	SystemName = mls_field;
--             

	DELETE
	-- SELECT 	*
    FROM	Mapping
    WHERE	EXISTS (
		
        SELECT	*
        FROM	Dublicates
		WHERE	Dublicates.class_id=Mapping.class_id
				AND Dublicates.internal_field=Mapping.internal_field
    ) AND SystemName != mls_field;
	
    
    /*
		
        No dublicates
    
    */
-- SELECT	COUNT(*), class_id, internal_field
-- FROM	Mapping
-- GROUP BY class_id, internal_field
-- HAVING COUNT(*) > 1;
select * from vu_Sources where id=99;
select * from metadata_classes;
UPDATE TMP
INNER JOIN	Mapping	ON Mapping.class_id=TMP.new_class_id
					AND Mapping.internal_field=TMP.internal_field
SET TMP.New_SystemName = Mapping.SystemName,
	TMP.New_LongName = Mapping.LongName,
	TMP.Old_SystemName = Mapping.mls_field,
	TMP.Old_LongName = Mapping.Old_LongName
;

UPDATE TMP 
INNER JOIN source_default_mapping ON	source_default_mapping.internal_field=TMP.internal_field
										AND source_default_mapping.class_id=TMP.class_id
SET TMP.Official_Old_SystemName=source_default_mapping.mls_field;


/*
restruct

	At this point, all the internal_fields have their own New_SystemName.
		1. There is a case that New_SystemName is null for RETS. 
		2. If New_SystemName is null for all the records --> We have API feed
			--> Update New_SystemName = Official_Old_SystemName

*/

/*

	When errors occured, fix it with this

*/

-- UPDATE TMP
-- SET New_SystemName = 'L_ListingID',
-- 	New_LongName = 'SystemID'
--     WHERE	id = 74
--     ;

INSERT INTO FinalMapping
SELECT	*
FROM	TMP
WHERE	New_SystemName IS NOT NULL OR
		@auth_type = 'API' 
;

-- Only for API 
UPDATE FinalMapping
TMP
SET New_SystemName = TMP.Official_Old_SystemName		
WHERE EXISTS (SELECT * FROM TMP WHERE New_SystemName IS NULL) 
							AND @auth_type = 'API';


SELECT 	COUNT(*) AS Quantity, new_class_id, ClassNameDescription, internal_field
FROM	FinalMapping
GROUP BY new_class_id, internal_field
HAVING COUNT(*) > 1
ORDER BY new_class_id ASC, internal_field ASC;

SELECT	*
FROM	FinalMapping;


-- WHERE	new_class_id IS NULL OR internal_field IS NULL;




-- INSERT INTO Map(new_class_id, New_SystemName, internal_field, Old_SystemName)
-- SELECT	new_class_id, New_SystemName, internal_field, Old_SystemName
-- FROM	FinalMapping
-- ;

--  	-- POPULATE SOURCE DEFAULT MAPPING
--  INSERT INTO source_default_mapping(source_id, class_id, internal_field, mls_field, created_at, updated_at)
-- 	SELECT 
-- 		new_source_id,
-- 		new_class_id,
-- 		internal_field,
-- 		New_SystemName,
-- 		NOW(),
-- 		NOW()
-- 	FROM FinalMapping
-- 	WHERE NOT EXISTS (SELECT * FROM source_default_mapping WHERE source_id=@source_id);

-- 	-- POPULATE USER SOURCE 
-- 	INSERT INTO user_source
-- 	SELECT user_id, @source_id, NOW(), NOW()
-- 	FROM user_source WHERE source_id=(SELECT id FROM sources WHERE mls_name=@similar_mls);
-- 	-- COLLATE utf8mb4_unicode_ci;

-- 	-- POPULATE SOURCE MAPPING
-- 	INSERT INTO source_mapping(user_id, source_id, class_id, internal_field, mls_field) 
-- 	SELECT user_source.user_id,
-- 		   source_default_mapping.source_id, 
-- 		   source_default_mapping.class_id, 
-- 		   source_default_mapping.internal_field, 
-- 		   source_default_mapping.mls_field
-- 	FROM user_source
-- 	JOIN source_default_mapping USING(source_id)
-- 	WHERE source_default_mapping.source_id = @source_id
-- 	ON DUPLICATE KEY UPDATE
-- 	mls_field = VALUES(mls_field);
    
-- 	-- POPULATE PHOTO JOBS
-- 	INSERT INTO photo_jobs (source_id, service_pid, failure_counter, strategy, options, query_time, created_at, updated_at)
-- 	SELECT 
-- 		@source_id,
-- 		service_pid,
-- 		failure_counter,
--         strategy,
--         REGEXP_REPLACE(options, "OriginatingSystemName eq '[A-Z]+'", CONCAT("OriginatingSystemName eq '", @OriginationName, "'")) AS options, -- only for API and tresle
--         query_time,
-- 		NOW(),
-- 		NOW()
-- 	FROM photo_jobs
-- 	WHERE source_id=(SELECT id FROM sources WHERE mls_name=@similar_mls)
-- 	AND NOT EXISTS (SELECT * FROM photo_jobs WHERE source_id=@source_id);
    
-- 	-- POPULATE GEO JOBS
-- 	INSERT INTO geo_jobs (source_id, service_pid, options, created_at, updated_at)
-- 	SELECT 
-- 		@source_id,
-- 		service_pid,
-- 		options,
-- 		NOW(),
-- 		NOW()
-- 	FROM geo_jobs
-- 	WHERE source_id=(SELECT id FROM sources WHERE mls_name=@similar_mls)
-- 	AND NOT EXISTS (SELECT * FROM geo_jobs WHERE source_id=@source_id);

-- 	-- POPULATE GEO FIELDS
-- 	INSERT INTO geo_fields (class_id, street_name, city, state, zip, street_number, street_suffix, street_direction, latitude, longitude, created_at, updated_at)
-- 	SELECT t.new_class_id, street_name, city, state, zip, street_number, street_suffix, street_direction, latitude, longitude, NOW(), NOW() FROM geo_fields 
-- 	JOIN (
-- 		SELECT 
-- 			class_id,
-- 			new_class_id,
-- 			ClassNameDescription,
-- 			NewClassNameDescription
-- 		FROM FinalMapping 
-- 		GROUP BY class_id, new_class_id, ClassNameDescription, NewClassNameDescription
-- 	) t ON geo_fields.class_id = t.class_id
-- 	WHERE NOT EXISTS (SELECT * FROM geo_fields WHERE class_id=t.new_class_id);

-- 	-- POPULATE CLASS JOBS
/*
	
    For RetsFake:
	 1. Execute the subquery and get new_class_id for the Residential and incremental type
     2. Comment in the AND predicates with the appropriate new_class_id
     
*/


	-- INSERT INTO class_jobs (type, metadata_class_id, query, query_update_time, query_update_format, next_update_time, next_update_frequency, params, strategy, created_at, updated_at) 
-- 	SELECT 
-- 		type, t.new_class_id, 
--         CASE 
-- 			WHEN @auth_type = 'API' AND REGEXP_LIKE(query, "OriginatingSystemName eq") = 1 
-- 				THEN REGEXP_REPLACE(query, "OriginatingSystemName eq '[A-Z]+'", CONCAT("OriginatingSystemName eq '", @OriginationName, "'"))
--             ELSE query 
-- 		END	AS query, 
--         query_update_time, query_update_format, next_update_time, next_update_frequency, params, strategy, NOW(), NOW()
-- 	FROM class_jobs
-- 	JOIN (
-- 		SELECT 
-- 			class_id,
-- 			new_class_id,
-- 			ClassNameDescription,
-- 			NewClassNameDescription
-- 		FROM FinalMapping 
-- 		GROUP BY class_id, new_class_id, ClassNameDescription, NewClassNameDescription
-- 	) t ON class_jobs.metadata_class_id = t.class_id
-- 	WHERE	NOT EXISTS (SELECT * FROM class_jobs WHERE metadata_class_id=t.new_class_id);
-- 			AND type = 'incremental'
-- 			AND new_class_id=12690; 

-- UDPATE New_SystemName -- 
-- WITH New_ClassJobs (type, metadata_class_id, query, query_update_time, query_update_format, next_update_time, next_update_frequency, params, strategy, created_at, updated_at) AS (
-- 	SELECT DISTINCT -- Distinct --> avoiding Dublicates due for tuple (internal_field, mls_name) being not unique e.g. maybe there is (open_house_date, OH_EndDateTime)(open_house_end_date, OH_EndDateTime)
-- 			type, t.new_class_id, 
-- 			REGEXP_REPLACE(query, Map.Old_SystemName, Map.New_SystemName) AS query,
-- 			query_update_time, query_update_format, next_update_time, next_update_frequency, params, strategy, NOW(), NOW()
-- 		FROM class_jobs
-- 		JOIN (
-- 				SELECT 
-- 					class_id,
-- 					new_class_id,
-- 					ClassNameDescription,
-- 					NewClassNameDescription
-- 				FROM FinalMapping 
-- 				GROUP BY class_id, new_class_id, ClassNameDescription, NewClassNameDescription
--         ) t ON class_jobs.metadata_class_id = t.new_class_id
-- 		JOIN Map	ON Map.new_class_id=t.new_class_id AND
-- 					-- Map.class_id=t.class_id AND 
-- 					query LIKE CONCAT('%', Map.Old_SystemName ,'%')
-- 		-- WHERE	NOT EXISTS (SELECT * FROM class_jobs WHERE metadata_class_id=t.new_class_id)
--     )
-- UPDATE class_jobs
-- INNER JOIN New_ClassJobs ON New_ClassJobs.metadata_class_id=class_jobs.metadata_class_id AND
-- 							New_ClassJobs.type=class_jobs.type
-- SET class_jobs.query = New_ClassJobs.query
-- WHERE	@auth_type = 'RETS';





-- 	INSERT INTO onmarket_statuses(source_id, name, on_market, standard_id)
-- 	SELECT
-- 		@source_id, name, on_market, standard_id
-- 	FROM onmarket_statuses 
-- 	WHERE source_id=(SELECT id FROM sources WHERE mls_name=@similar_mls);

-- 	UPDATE class_jobs
-- 			JOIN
-- 		metadata_classes ON class_jobs.metadata_class_id = metadata_classes.id
-- 	SET class_jobs.failure_counter=10 -- go to panel lazy donkey !
-- 	WHERE
-- 		metadata_classes.id IN (SELECT 
-- 				metadata_classes.id
-- 			FROM
-- 				metadata_classes
-- 					JOIN
-- 				metadata_resources ON metadata_classes.resource_id = metadata_resources.id
-- 			WHERE
-- 				metadata_resources.source_id = @source_id); 