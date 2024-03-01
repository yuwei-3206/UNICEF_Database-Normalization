-- ========= --
-- DW Design --
-- ========= --

-- Table: UDW_DIM_COUNTRY
CREATE TABLE UDW_DIM_COUNTRY (
    COUNTRY_CODE char(3)  NOT NULL,
    COUNTRY_NAME varchar2(100)  NOT NULL,
    REGION_NAME varchar2(100)  NOT NULL,
    CONSTRAINT UDW_DIM_COUNTRY_pk PRIMARY KEY (COUNTRY_CODE)
) ;
-- Table: UDW_DIM_GENDER
CREATE TABLE UDW_DIM_GENDER (
    GENDER_CODE char(1)  NOT NULL,
    GENDER_NAME varchar2(10)  NOT NULL,
    CONSTRAINT UDW_DIM_GENDER_pk PRIMARY KEY (GENDER_CODE)
) ;
-- Table: UDW_DIM_TIME
CREATE TABLE UDW_DIM_TIME (
    YEAR_CODE integer  NOT NULL,
    DECADE_NAME char(5)  NOT NULL,
    CONSTRAINT UDW_DIM_TIME_pk PRIMARY KEY (YEAR_CODE)
) ;
-- Table: UDW_FACT_POPULATION
CREATE TABLE UDW_FACT_POPULATION (
    YEAR_CODE integer  NOT NULL,
    GENDER_CODE char(1)  NOT NULL,
    COUNTRY_CODE char(3)  NOT NULL,
    DM_POP_TOT integer  NOT NULL,
    DM_POP_U5 integer  NOT NULL,
    DM_POP_ADLCNT integer  NOT NULL,
    DM_POP_15TO24 integer  NOT NULL,
    DM_POP_U18 integer  NOT NULL,
    CONSTRAINT UDW_FACT_POPULATION_pk PRIMARY KEY (YEAR_CODE,GENDER_CODE,COUNTRY_CODE)
) ;
ALTER TABLE UDW_FACT_POPULATION ADD CONSTRAINT UDW_DIM_COUNTRY_FACT_POP_FK
    FOREIGN KEY (COUNTRY_CODE)
    REFERENCES UDW_DIM_COUNTRY (COUNTRY_CODE);
ALTER TABLE UDW_FACT_POPULATION ADD CONSTRAINT UDW_DIM_GENDER_FACT_POP_FK
    FOREIGN KEY (GENDER_CODE)
    REFERENCES UDW_DIM_GENDER (GENDER_CODE);
ALTER TABLE UDW_FACT_POPULATION ADD CONSTRAINT UDW_DIM_TIME_FACT_POP_FK
    FOREIGN KEY (YEAR_CODE)
    REFERENCES UDW_DIM_TIME (YEAR_CODE);

-- ============== --
-- Data Ingestion --
-- ============== --

--Insert dimension table data first
-- Countries
INSERT INTO UDW_DIM_COUNTRY (COUNTRY_CODE, COUNTRY_NAME, REGION_NAME)
SELECT DISTINCT substr(t.REF_AREA,1,3) COUNTRY_CODE
     , substr(t.REF_AREA,6) COUNTRY_NAME
     , 'Unknown' REGION_NAME
  FROM hc848.UNICEF_RAW_DATA_POP_ALL t
 WHERE t.REF_AREA like '___: %'
   AND NOT EXISTS (SELECT 1 FROM UDW_DIM_COUNTRY c WHERE c.COUNTRY_CODE = substr(t.REF_AREA,1,3));

--Insert dimension table data first
-- Gender
INSERT INTO UDW_DIM_GENDER (GENDER_CODE, GENDER_NAME)
SELECT DISTINCT substr(t.SEX,1,1) GENDER_CODE
     , substr(t.SEX,4) GENDER_NAME
  FROM hc848.UNICEF_RAW_DATA_POP_ALL t
 WHERE t.SEX not like '%T:%'
   AND NOT EXISTS (SELECT 1 FROM UDW_DIM_GENDER g WHERE g.GENDER_CODE = substr(t.SEX,1,1));

--Insert dimension table data first
-- Time
INSERT INTO UDW_DIM_TIME (YEAR_CODE, DECADE_NAME)
SELECT DISTINCT TIME_PERIOD YEAR_CODE
     , substr(t.TIME_PERIOD,1,3)||'0s' DECADE_NAME
  FROM hc848.UNICEF_RAW_DATA_POP_ALL t
 WHERE NOT EXISTS (SELECT 1 FROM UDW_DIM_TIME y WHERE y.YEAR_CODE = t.TIME_PERIOD);

-- 
-- FACT_POPULATION 
--
--Update fact table after updating dimension tables

INSERT INTO UDW_FACT_POPULATION (
    YEAR_CODE ,
    GENDER_CODE,
    COUNTRY_CODE,
    DM_POP_TOT,
    DM_POP_U5,
    DM_POP_ADLCNT,
    DM_POP_15TO24,
    DM_POP_U18
) 
SELECT 
     TIME_PERIOD            YEAR_CODE
    ,substr(t.SEX,1,1)      GENDER_CODE
    ,substr(t.REF_AREA,1,3) COUNTRY_CODE
    ,max(case when INDICATOR like 'DM_POP_TOT%' then OBS_VALUE end)    * 1000 DM_POP_TOT
    ,max(case when INDICATOR like 'DM_POP_U5%' then OBS_VALUE end)     * 1000 DM_POP_U5
    ,max(case when INDICATOR like 'DM_POP_ADLCNT%' then OBS_VALUE end) * 1000 DM_POP_ADLCNT
    ,max(case when INDICATOR like 'DM_POP_15TO24%' then OBS_VALUE end) * 1000 DM_POP_15TO24
    ,max(case when INDICATOR like 'DM_POP_U18%' then OBS_VALUE end)    * 1000 DM_POP_U18
 FROM hc848.UNICEF_RAW_DATA_POP_ALL t
WHERE EXISTS (SELECT 1 FROM UDW_DIM_TIME y WHERE y.YEAR_CODE = t.TIME_PERIOD)
  AND EXISTS (SELECT 1 FROM UDW_DIM_GENDER g WHERE g.GENDER_CODE = substr(t.SEX,1,1))
  AND EXISTS (SELECT 1 FROM UDW_DIM_COUNTRY c WHERE c.COUNTRY_CODE = substr(t.REF_AREA,1,3))
  AND NOT EXISTS (SELECT 1 FROM UDW_FACT_POPULATION f WHERE f.YEAR_CODE = t.TIME_PERIOD AND f.GENDER_CODE = substr(t.SEX,1,1) AND f.COUNTRY_CODE = substr(t.REF_AREA,1,3))
GROUP BY      
     TIME_PERIOD            
    ,substr(t.SEX,1,1)      
    ,substr(t.REF_AREA,1,3); 

-- Merge code
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
