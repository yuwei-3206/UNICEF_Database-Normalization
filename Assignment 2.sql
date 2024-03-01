SELECT * FROM hc848.UNICEF_RAW_DATA_POP_2010_2020;
SELECT * FROM hc848.UNICEF_RAW_DATA_POP_2000_2023 WHERE REF_AREA IS NULL;

SELECT * FROM UNICEF_FACT_INDICATOR WHERE YEAR_ID = 2010;

SELECT DISTINCT UNIT_MEASURE FROM hc848.UNICEF_RAW_DATA_POP_2010_2020
;
SELECT * FROM hc848.UNICEF_RAW_DATA_POP_2000_2023 WHERE REF_AREA LIKE 'AFG%' AND SEX LIKE 'F:%' AND UNIT_MEASURE = 'PS: Persons'
;

SELECT DISTINCT AREA_ID FROM UNICEF_FACT_INDICATOR WHERE AREA_ID = 'USA';

--Insert new values into UNICEF_DIM_TIME
--Original: 11 values Updated: 24 values
INSERT INTO UNICEF_DIM_TIME (YEAR_ID)
SELECT DISTINCT nw.TIME_PERIOD
  FROM hc848.UNICEF_RAW_DATA_POP_2000_2023 nw
 WHERE NOT EXISTS ( SELECT 1 FROM UNICEF_DIM_TIME t WHERE t.YEAR_ID = nw.TIME_PERIOD );

--Insert new values into UNICEF_FACT_INDICATOR
MERGE INTO UNICEF_FACT_INDICATOR f
USING (
        SELECT 
            SUBSTR(REF_AREA, 1, INSTR(REF_AREA, ':') - 1) AREA_ID, 
            SUBSTR(SEX, 1, INSTR(SEX, ':') - 1) GENDER_ID, 
            TIME_PERIOD YEAR_ID, 
            SUBSTR(UNIT_MULTIPLIER, 1, INSTR(UNIT_MULTIPLIER, ':') - 1) UNIT_MULTIPLIER_ID, 
            SUBSTR(UNIT_MEASURE, 1, INSTR(UNIT_MEASURE, ':') - 1) UNIT_MEASURE_ID, 
            "DM_POP_GRT", 
            "DM_POP_U_GRT", 
            "DM_POP_URBN", 
            "DM_POP_TOT", 
            "DM_POP_ADLCNT", 
            "DM_POP_ADLCNT_PROP", 
            "DM_POP_U5", 
            "DM_POP_15TO24", 
            "DM_POP_U18" 
        FROM ( 
            SELECT 
                REF_AREA, 
                SEX, 
                TIME_PERIOD, 
                OBS_VALUE, 
                UNIT_MULTIPLIER, 
                UNIT_MEASURE, 
                "INDICATOR" 
            FROM 
                hc848.UNICEF_RAW_DATA_POP_2000_2023
        ) PIVOT ( 
            SUM(OBS_VALUE) 
            FOR "INDICATOR" 
            IN ( 
                'DM_POP_GRT: Population annual growth rate' AS "DM_POP_GRT",
                'DM_POP_U_GRT: Annual growth rate of urban population' AS "DM_POP_U_GRT", 
                'DM_POP_URBN: Share of urban population' AS "DM_POP_URBN", 
                'DM_POP_TOT: Total population' AS "DM_POP_TOT", 
                'DM_POP_ADLCNT: Adolescent population (10-19)' AS "DM_POP_ADLCNT", 
                'DM_POP_ADLCNT_PROP: Adolescent population as proportion of total population (%)' AS "DM_POP_ADLCNT_PROP", 
                'DM_POP_U5: Population under age 5' AS "DM_POP_U5", 
                'DM_POP_15TO24: Youth population from 15 to 24' AS "DM_POP_15TO24", 
                'DM_POP_U18: Population under age 18' AS "DM_POP_U18" 
            ) 
        )        
)r
    ON (
            f.AREA_ID = r.AREA_ID
        AND f.GENDER_ID = r.GENDER_ID
        AND f.YEAR_ID = r.YEAR_ID
        AND f.UNIT_MULTIPLIER_ID = r.UNIT_MULTIPLIER_ID
        AND f.UNIT_MEASURE_ID = r.UNIT_MEASURE_ID
    )
WHEN MATCHED THEN UPDATE 
    SET f.DM_POP_GRT = r.DM_POP_GRT,
        f.DM_POP_U_GRT = r.DM_POP_U_GRT,
        f.DM_POP_URBN = r.DM_POP_URBN,
        f.DM_POP_TOT = r.DM_POP_TOT,
        f.DM_POP_ADLCNT = r.DM_POP_ADLCNT,
        f.DM_POP_ADLCNT_PROP = r.DM_POP_ADLCNT_PROP,
        f.DM_POP_U5 = r.DM_POP_U5,
        f.DM_POP_15TO24 = r.DM_POP_15TO24,
        f.DM_POP_U18 = r.DM_POP_U18
WHEN NOT MATCHED THEN INSERT (
    AREA_ID,
	GENDER_ID,
	YEAR_ID,
	UNIT_MULTIPLIER_ID,
	UNIT_MEASURE_ID,
	DM_POP_GRT,
    DM_POP_U_GRT,
    DM_POP_URBN,
    DM_POP_TOT,
    DM_POP_ADLCNT,
    DM_POP_ADLCNT_PROP,
    DM_POP_U5,
    DM_POP_15TO24,
    DM_POP_U18
) VALUES (
    r.AREA_ID,
	r.GENDER_ID,
	r.YEAR_ID,
	r.UNIT_MULTIPLIER_ID,
	r.UNIT_MEASURE_ID,
	r.DM_POP_GRT,
    r.DM_POP_U_GRT,
    r.DM_POP_URBN,
    r.DM_POP_TOT,
    r.DM_POP_ADLCNT,
    r.DM_POP_ADLCNT_PROP,
    r.DM_POP_U5,
    r.DM_POP_15TO24,
    r.DM_POP_U18
);

--Extra Credits
--What is the population in the USA in each year from 2000 to 2023?
--Check if your query result matches with data in the UNICEF Data website.
SELECT AREA_ID, YEAR_ID, SUM(DM_POP_TOT)*1000 "Total Population"
FROM UNICEF_FACT_INDICATOR
WHERE AREA_ID = 'USA'
AND GENDER_ID IN ('F', 'M') 
GROUP BY AREA_ID, YEAR_ID
ORDER BY YEAR_ID
;

--What is the world total population in each year from 2000 to 2023?
--Check if your query result makes sense.
SELECT YEAR_ID, SUM(DM_POP_TOT)*1000 "World Total Population"
FROM UNICEF_FACT_INDICATOR
WHERE AREA_ID LIKE '___'
AND GENDER_ID IN ('F', 'M') 
GROUP BY YEAR_ID
ORDER BY YEAR_ID
;
