-- formatting is different as I created the views in the duckdb gui and then copied them over to this file.
CREATE OR REPLACE VIEW chl_dineof AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(chlor_a AS "DOUBLE") AS chl_filled FROM "datasets/chlorophyll_*_dineof.csv" WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);

CREATE OR REPLACE VIEW chl_erd AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(chla AS "DOUBLE") AS chl_obs FROM "datasets/erd_chlorophyll_*.csv" WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);

CREATE OR REPLACE VIEW cuti AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS DOUBLE) AS lat, CAST(CUTI AS DOUBLE) AS cuti FROM "datasets/erdCUTIdaily_c010_b954_09c2.csv" WHERE (TRY_CAST(latitude AS DOUBLE) IS NOT NULL);

CREATE OR REPLACE VIEW glider AS SELECT CAST(mission AS INTEGER) AS mission, CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(depth AS "DOUBLE") AS depth, CASE  WHEN ((doxy = 'NaN')) THEN (NULL) ELSE TRY_CAST(doxy AS "DOUBLE") END AS doxy, CASE  WHEN ((temperature = 'NaN')) THEN (NULL) ELSE TRY_CAST(temperature AS "DOUBLE") END AS temperature, CASE  WHEN ((salinity = 'NaN')) THEN (NULL) ELSE TRY_CAST(salinity AS "DOUBLE") END AS salinity, CASE  WHEN ((chlorophyll = 'NaN')) THEN (NULL) ELSE TRY_CAST(chlorophyll AS "DOUBLE") END AS chl_glider FROM read_csv_auto('datasets/binnedCUGN80_52e6_d0ac_a341.csv', (all_varchar = CAST('t' AS BOOLEAN))) WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);

CREATE OR REPLACE VIEW kelp AS SELECT * FROM "datasets/kelp_landsat.parquet";

CREATE OR REPLACE VIEW pdo AS SELECT make_date("Year", "month"(strptime(month_name, '%b')), 1) AS date, pdo FROM (SELECT * FROM (SELECT * FROM "datasets/pdo_data.csv") UNPIVOT (pdo FOR month_name IN (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, "Dec")));

CREATE OR REPLACE VIEW rain AS SELECT STATION AS station, "NAME" AS "name", CAST(LATITUDE AS "DOUBLE") AS lat, CAST(LONGITUDE AS "DOUBLE") AS lon, CAST(DATE AS "DATE") AS date, CASE  WHEN ((PRCP = -9999)) THEN (NULL) ELSE (CAST(PRCP AS "DOUBLE") * 25.4) END AS prcp, CASE  WHEN ((filename ~~ '%SB%')) THEN ('santa_barbara') ELSE 'ventura' END AS region FROM read_csv_auto('datasets/land_weather_*.csv', (union_by_name = CAST('t' AS BOOLEAN)), (filename = CAST('t' AS BOOLEAN))) WHERE (PRCP IS NOT NULL);

CREATE OR REPLACE VIEW reef AS SELECT SITE AS site, TRANSECT AS transect, CAST(DATE AS "DATE") AS date, "YEAR" AS "year", "MONTH" AS "month", SCIENTIFIC_NAME AS species, COMMON_NAME AS common_name, "nullif"(DENSITY, -99999) AS density, "nullif"(PERCENT_COVER, -99999) AS percent_cover, "nullif"(WM_GM2, -99999) AS wet_biomass FROM read_csv_auto('datasets/SBS_All_Species_Biomass_at_transect_20260311.csv');

--CREATE OR REPLACE VIEW sst AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(analysed_sst AS "DOUBLE") AS sst_c FROM "datasets/SST_MUR_*.csv" WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);

-- extented my time period for the sst data to include 2008 -2026 filter for longitude to be less than or equal to -118.98
CREATE OR REPLACE VIEW sst AS
SELECT CAST("time" AS TIMESTAMP) AS ts,
       TRY_CAST(latitude AS DOUBLE) AS lat,
       TRY_CAST(longitude AS DOUBLE) AS lon,
       TRY_CAST(analysed_sst AS DOUBLE) AS sst_c
FROM read_csv_auto('datasets/SST_MUR_*.csv')
WHERE TRY_CAST(latitude AS DOUBLE) IS NOT NULL
  AND TRY_CAST(longitude AS DOUBLE) <= -118.98
  AND TRY_CAST(analysed_sst AS DOUBLE) IS NOT NULL
  AND NOT isnan(TRY_CAST(analysed_sst AS DOUBLE))
  AND TRY_CAST(mask AS INTEGER) = 1;

--- add the kdpar datasets 
CREATE OR REPLACE VIEW photo AS
SELECT DISTINCT CAST("time" AS TIMESTAMP) AS ts, -- added distinct to get rid of duplicates
       TRY_CAST(latitude AS DOUBLE) AS lat,
       TRY_CAST(longitude AS DOUBLE) AS lon,
       TRY_CAST(kd_par AS DOUBLE) AS kdpar
FROM read_csv_auto('datasets/photo_*.csv')
WHERE TRY_CAST(latitude AS DOUBLE) IS NOT NULL
  AND TRY_CAST(kd_par AS DOUBLE) IS NOT NULL
  AND NOT isnan(TRY_CAST(kd_par AS DOUBLE));

  -- Running new queries to create the tables so that I don't need to query the views every time I want to use them. This will speed up the queries and make it easier to work with the data.

-- 1. Climatology: normal SST for each pixel and calendar month.
--    Baseline = 2008–2013 (before the 2014–16 heatwave).
CREATE OR REPLACE TABLE sst_clim_pre AS
SELECT lat,
       lon,
       month(ts)  AS month_num,
       avg(sst_c) AS clim_sst
FROM sst
WHERE ts >= '2008-01-01' AND ts < '2014-01-01'
GROUP BY lat, lon, month(ts);

-- post heatwave climatology
CREATE OR REPLACE TABLE sst_clim_post AS
SELECT lat,
       lon,
       month(ts)  AS month_num,
       avg(sst_c) AS clim_sst
FROM sst
WHERE ts >= '2017-01-01' AND ts < '2026-01-01'
GROUP BY lat, lon, month(ts);

-- 2. Monthly series: mean SST for each pixel in each month of each year.
CREATE OR REPLACE TABLE sst_monthly AS
SELECT lat,
       lon,
       date_trunc('month', ts) AS monthly_date,
       avg(sst_c) AS mean_sst_c
FROM sst
GROUP BY lat, lon, date_trunc('month', ts);

-- 3. Anomaly: how far each month was from normal for that pixel and month.
CREATE OR REPLACE VIEW sst_anomaly AS
SELECT m.lat,
       m.lon,
       m.monthly_date,
       m.mean_sst_c,
       c_pre.clim_sst,
       m.mean_sst_c - c_pre.clim_sst AS anomaly_c_pre,
       m.mean_sst_c - c_post.clim_sst AS anomaly_c_post
FROM sst_monthly AS m
JOIN sst_clim_pre AS c_pre
  ON  m.lat = c_pre.lat
  AND m.lon = c_pre.lon
  AND month(m.monthly_date) = c_pre.month_num
JOIN sst_clim_post AS c_post
  ON  m.lat = c_post.lat
  AND m.lon = c_post.lon
  AND month(m.monthly_date) = c_post.month_num;

  
  
-- next will be working on the kelp


-- creating monthly averages
CREATE OR REPLACE TABLE kelp_quarter AS
SELECT lat,
       lon,
       date_trunc('quarter', date) AS quarterly_kelp,
       avg(biomass_kg) AS mean_biomass_kg,
       avg(area_m2) AS mean_area_m2
FROM kelp
WHERE date >= '2008-01-01' AND date < '2026-05-01'
GROUP BY lat, lon, date_trunc('quarter', date);

-- look for anaomalies in kelp biomass and area
CREATE OR REPLACE VIEW kelp_anomaly AS
SELECT lat,
       lon,
        quarterly_kelp,
        mean_biomass_kg,
        mean_area_m2,
        avg(mean_biomass_kg) OVER (PARTITION BY lat, lon, quarter(quarterly_kelp)) AS clim_biomass_kg,
        avg(mean_area_m2) OVER (PARTITION BY lat, lon, quarter(quarterly_kelp)) AS clim_area_m2,
        mean_biomass_kg - avg(mean_biomass_kg) OVER (PARTITION BY lat, lon, quarter(quarterly_kelp)) AS anomaly_biomass_kg,
        mean_area_m2 - avg(mean_area_m2) OVER (PARTITION BY lat, lon, quarter(quarterly_kelp)) AS anomaly_area_m2
FROM kelp_quarter;


-- Reef dataset
-- looking for the names of the species that have kelp in their common name and then calculating the mean density for those species.
SELECT species, 
common_name,
 avg(density) AS mean_density
FROM reef
WHERE common_name ILIKE '%kelp%'
GROUP BY species, common_name;

-- creating a table for the species that have kelp or urchin in their common name and then calculating the mean density for those species.
-- species with kelp or urchin in their common name: mean density per species per year
CREATE OR REPLACE VIEW reef_species AS
SELECT 
     species, 
     common_name, 
     site,
     year,
     avg(density) AS mean_density
FROM reef
WHERE common_name ILIKE '%kelp%' OR common_name ILIKE '%urchin%'
GROUP BY species, common_name, site, year;

-- side-by-side comparison: one row per year, one column per species
CREATE OR REPLACE VIEW species_ind AS 
SELECT 
    year, 
    month,
    site,
    avg(CASE WHEN species = 'Macrocystis pyrifera' THEN density END) AS giant_kelp_density,
    avg(CASE WHEN species = 'Egregia menziesii' THEN density END) AS feather_kelp_density,
    avg(CASE WHEN species = 'Pterygophora californica' THEN density END) AS palm_kelp_density,
    avg(CASE WHEN species = 'Strongylocentrotus purpuratus' THEN density END) AS purple_urchin_density,
    avg(CASE WHEN species = 'Mesocentrotus franciscanus' THEN density END) AS red_urchin_density
FROM reef
GROUP BY year, month, site
ORDER BY year, month, site;

-- reef site coordinates, from knb-lter-sbc.182 metadata
CREATE OR REPLACE TABLE reef_sites AS
SELECT * FROM (VALUES
    ('AQUE', 'Arroyo Quemado', 34.46775, -120.11905),
    ('NAPL', 'Naples',         34.42212, -119.95154),
    ('IVEE', 'Isla Vista',     34.40278, -119.85755),
    ('MOHK', 'Mohawk',         34.39407, -119.72957),
    ('CARP', 'Carpinteria',    34.39163, -119.54169)
) AS t(site, site_name, lat, lon);

CREATE OR REPLACE VIEW reef_species_sites AS
SELECT 
    r.site,
    s.site_name, 
    r.year, 
    r.month,
    avg(CASE WHEN r.species = 'Macrocystis pyrifera' THEN r.density END) AS giant_kelp_density,
    avg(CASE WHEN r.species = 'Egregia menziesii' THEN r.density END) AS feather_kelp_density,
    avg(CASE WHEN r.species = 'Pterygophora californica' THEN r.density END) AS palm_kelp_density,
    avg(CASE WHEN r.species = 'Strongylocentrotus purpuratus' THEN r.density END) AS purple_urchin_density,
    avg(CASE WHEN r.species = 'Mesocentrotus franciscanus' THEN r.density END) AS red_urchin_density
FROM reef AS r
JOIN reef_sites AS s ON r.site = s.site
GROUP BY r.site, s.site_name, r.year, r.month
ORDER BY r.site, r.year, r.month;


--- photo

CREATE OR REPLACE TABLE kdpar_averages AS
SELECT 
    lat, 
    lon, 
    month(ts) as month_num,
    avg(kdpar) as average_kdpar,
    COUNT(*) AS n_observations, 
    9 - count(*) AS cloudy_months -- 9 years observed from 2017-2025
FROM photo
WHERE ts >= '2017-01-01' AND ts < '2026-01-01'
GROUP BY lat, lon, month(ts); 

-- same layout as the sst column 

CREATE OR REPLACE TABLE kdpar_changes AS 
SELECT 
    p.ts, 
    p.lat, 
    p.lon,
    p.kdpar, 
    a.average_kdpar,
    p.kdpar - a.average_kdpar AS changes_in_average_kdpar
FROM photo AS p
JOIN kdpar_averages AS a
  ON  p.lat = a.lat
  AND p.lon = a.lon
  AND month(p.ts) = a.month_num;

---CUTI 
CREATE OR REPLACE TABLE cuti_average AS
SELECT
  month(ts) AS month_ts,
   lat,
   avg(cuti) AS average_upwell
FROM CUTI
GROUP BY lat, month_ts;

--pdo
CREATE OR REPLACE TABLE pdo_phase AS
SELECT
    date,
    pdo,
    CASE WHEN pdo > 0 THEN 'warm' ELSE 'cool' END AS pdo_phase
FROM pdo;


CREATE OR REPLACE TABLE pdo_quarter AS
SELECT
       date_trunc('quarter', date) AS quarterly_pdo,
       avg(pdo) AS mean_pdo,
FROM pdo
GROUP BY  date_trunc('quarter', date);


    
-- rain 

CREATE OR REPLACE TABLE rain_quarter AS
SELECT
    region,
    date_trunc('quarter', date) AS quarter,
    avg(prcp) AS mean_daily_rain_mm,
    count(DISTINCT station) AS n_stations
FROM rain
GROUP BY region, date_trunc('quarter', date);

CREATE OR REPLACE TABLE rain_lag AS
SELECT 
    region, 
    station,
    date, 
    prcp,
    SUM(prcp) OVER (
      PARTITION BY station
      ORDER BY date
      RANGE BETWEEN INTERVAL 6 DAYS PRECEDING AND CURRENT ROW
    ) AS rain_7day
FROM rain
ORDER BY date; 
 

 -- Glider
-- try and see how glider affects 

CREATE OR REPLACE TABLE glider_average AS
SELECT 
  depth,
  date_trunc('month', ts) AS month,
  avg(temperature) AS avg_temp,
  avg(salinity) AS avg_sal,
  avg(doxy) AS avg_doxy
FROM Glider
GROUP BY depth, date_trunc('month', ts);
  