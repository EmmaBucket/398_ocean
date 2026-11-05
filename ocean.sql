-- formatting is different as I created the views in the duckdb gui and then copied them over to this file.
CREATE OR REPLACE VIEW chl_dineof AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(chlor_a AS "DOUBLE") AS chl_filled FROM "datasets/chlorophyll_*_dineof.csv" WHERE TRY_CAST(latitude AS DOUBLE) IS NOT NULL AND TRY_CAST(chlor_a AS DOUBLE) IS NOT NULL AND NOT isnan(TRY_CAST(chlor_a AS DOUBLE));

CREATE OR REPLACE VIEW chl_erd AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(chla AS "DOUBLE") AS chl_obs FROM "datasets/erd_chlorophyll_*.csv" WHERE TRY_CAST(latitude AS DOUBLE) IS NOT NULL AND TRY_CAST(chla AS DOUBLE) IS NOT NULL AND NOT isnan(TRY_CAST(chla AS DOUBLE));
CREATE OR REPLACE VIEW cuti AS SELECT DISTINCT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS DOUBLE) AS lat, CAST(CUTI AS DOUBLE) AS cuti FROM "datasets/erdCUTIdaily_*.csv" WHERE (TRY_CAST(latitude AS DOUBLE) IS NOT NULL);

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


-- creating quarterly averages
CREATE OR REPLACE TABLE kelp_quarter AS
SELECT lat,
       lon,
       date_trunc('quarter', date) AS quarterly_kelp,
       avg(biomass_kg) AS mean_biomass_kg,
       avg(area_m2) AS mean_area_m2
FROM kelp
WHERE date >= '2008-01-01' AND date < '2026-04-01'
GROUP BY lat, lon, date_trunc('quarter', date);


CREATE OR REPLACE TABLE kelp_pre AS
  SELECT lat,
       lon,
       quarter(date)  AS quarter_num,
       avg(biomass_kg) AS mean_biomass_kg,
       avg(area_m2) AS mean_area_m2
FROM kelp
WHERE date >= '2008-01-01' AND date < '2014-01-01'
GROUP BY lat, lon, quarter(date);



-- look for anaomalies in kelp biomass and area
CREATE OR REPLACE VIEW kelp_anomaly AS
SELECT kq.lat,
       kq.lon,
       kq.quarterly_kelp,
       kp.mean_biomass_kg AS clim_biomass_kg,
       kp.mean_area_m2 AS clim_area_m2,
       kq.mean_biomass_kg - kp.mean_biomass_kg AS anomaly_biomass_kg_pre,
       kq.mean_area_m2    - kp.mean_area_m2    AS anomaly_area_m2_pre
FROM kelp_quarter as kq
JOIN kelp_pre as kp
  ON  kq.lat = kp.lat
  AND kq.lon = kp.lon
  AND quarter(kq.quarterly_kelp) = kp.quarter_num;



-- Reef dataset
-- looking for the names of the species that have kelp in their common name and then calculating the mean density for those species.

-- Code isn't being used for anything
--SELECT species, 
--common_name,
 --avg(density) AS mean_density
--FROM reef
--WHERE common_name ILIKE '%kelp%'
--GROUP BY species, common_name;

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

-- side-by-side comparison
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
GROUP BY lat, lon, month(ts)
ORDER BY lat, lon, month(ts); 

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
  AND month(p.ts) = a.month_num
Order BY p.ts, p.lat, p.lon;

---CUTI 
CREATE OR REPLACE TABLE cuti_average AS
SELECT
  month(ts) AS month_ts,
   lat,
   avg(cuti) AS average_upwell
FROM CUTI
GROUP BY lat, month_ts
ORDER BY Lat, month_ts;

--pdo
CREATE OR REPLACE TABLE pdo_phase AS
SELECT
    date,
    pdo,
    CASE WHEN pdo > 0 THEN 'warm' ELSE 'cool' END AS pdo_phase
FROM pdo
Order By date;


CREATE OR REPLACE TABLE pdo_quarter AS
SELECT
       date_trunc('quarter', date) AS quarterly_pdo,
       avg(pdo) AS mean_pdo
FROM pdo
GROUP BY  date_trunc('quarter', date)
ORDER BY quarterly_pdo;


    
-- rain 

CREATE OR REPLACE TABLE rain_quarter AS
SELECT
    region,
    date_trunc('quarter', date) AS quarter,
    avg(prcp) AS mean_daily_rain_mm,
    count(DISTINCT station) AS n_stations
FROM rain
GROUP BY region, date_trunc('quarter', date)
ORDER BY region, quarter;

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
GROUP BY depth, date_trunc('month', ts)
ORDER BY depth, month;
  

-- Create table to run queries on for model this is for kelp
-- needs SST, PDO, CUTI, 

CREATE OR REPLACE TABLE model_long AS
WITH kelp_q AS (
    SELECT quarterly_kelp AS quarter,
           avg(mean_biomass_kg) AS kelp_biomass
    FROM kelp_quarter
    GROUP BY quarterly_kelp
),
sst_q AS (
    SELECT date_trunc('quarter', monthly_date) AS quarter,
           avg(mean_sst_c) AS avg_sst
    FROM sst_monthly
    GROUP BY 1
),
pdo_q AS (
    SELECT date_trunc('quarter', date) AS quarter,
           avg(pdo) AS avg_pdo
    FROM pdo
    GROUP BY 1
),
cuti_q AS (
    SELECT date_trunc('quarter', ts) AS quarter,
           avg(cuti) AS avg_cuti
    FROM cuti
    WHERE lat = 34
    GROUP BY 1
)
SELECT k.quarter,
       k.kelp_biomass,
       s.avg_sst,
       p.avg_pdo,
       c.avg_cuti
FROM kelp_q AS k
JOIN sst_q AS s ON k.quarter = s.quarter
JOIN pdo_q AS p ON k.quarter = p.quarter
JOIN cuti_q AS c ON k.quarter = c.quarter
ORDER BY k.quarter;

-- building one that also includes light attenuation (kdpar) which would give less quarterly data but more accurate for the model.

CREATE OR REPLACE TABLE light_model AS
WITH kelp_q AS (
    SELECT quarterly_kelp AS quarter,
           avg(mean_biomass_kg) AS kelp_biomass
    FROM kelp_quarter
    GROUP BY quarterly_kelp
),
sst_q AS (
    SELECT date_trunc('quarter', monthly_date) AS quarter,
           avg(mean_sst_c) AS avg_sst
    FROM sst_monthly
    GROUP BY 1
),
pdo_q AS (
    SELECT date_trunc('quarter', date) AS quarter,
           avg(pdo) AS avg_pdo
    FROM pdo
    GROUP BY 1
),
cuti_q AS (
    SELECT date_trunc('quarter', ts) AS quarter,
           avg(cuti) AS avg_cuti
    FROM cuti
    WHERE lat = 34
    GROUP BY 1
), 
kdpar_q AS (
    SELECT date_trunc('quarter', ts) AS quarter,
           avg(kdpar) AS avg_kdpar
    FROM photo
    GROUP BY 1
)
SELECT k.quarter,
       k.kelp_biomass,
       s.avg_sst,
       p.avg_pdo,
       c.avg_cuti,
       kd.avg_kdpar
FROM kelp_q AS k
JOIN sst_q AS s ON k.quarter = s.quarter
JOIN pdo_q AS p ON k.quarter = p.quarter
JOIN cuti_q AS c ON k.quarter = c.quarter
JOIN kdpar_q AS kd ON k.quarter = kd.quarter
ORDER BY k.quarter;


--- CHLOROPHYLL model to include SST, CUTI, RAIN -- DAILY 

CREATE OR REPLACE TABLE chl_pixel_clim AS
SELECT
    lat,
    lon,
    round(lat, 2) AS lat_round,   
    round(lon, 2) AS lon_round,
    round(lat, 0) AS lat_band,    -- this will be needed for the CUTI data which is only available in lat
    count(*) AS n_obs_chl,
    avg(ln(chl_obs)) AS log_mean_chl,   -- log scale: many small values, few huge ones
    exp(avg(ln(chl_obs))) AS geo_mean_chl,   -- back to mg/m3, interpretable
    stddev_samp(ln(chl_obs)) AS log_sd_chl      -- lets me z-score each pixel against itself
FROM chl_erd
WHERE chl_obs > 0
GROUP BY lat, lon, round(lat, 2), round(lon, 2), round(lat, 0);

-- Fixed pixel -> nearest rain stations. 
CREATE OR REPLACE TABLE pixel_rain_sites AS
WITH stations AS (
    SELECT DISTINCT station, 
      lat AS st_lat, 
      lon AS st_lon
    FROM rain
), pixels AS (
    SELECT 
      DISTINCT lat, 
      lon
    FROM chl_erd
), pairs AS (
    SELECT p.lat,
           p.lon,
           s.station,
           sqrt( power((p.lat - s.st_lat) * 111.0, 2)   
               + power((p.lon - s.st_lon) *  92.0, 2) ) AS dist_km
    FROM pixels AS p
    CROSS JOIN stations AS s
), ranked AS (
    SELECT *,
           row_number() OVER (PARTITION BY lat, lon ORDER BY dist_km) AS rk
    FROM pairs
)
SELECT lat,
       lon,
       station,
       dist_km,
       1.0 / (dist_km + 1.0) AS weight   -- +1 avoids divide-by-zero and softens weighting
FROM ranked
WHERE rk <= 3;

-- Bloom events
CREATE OR REPLACE TABLE bloom_events AS
SELECT
    c.lat, 
    c.lon,
     c.lat_round, 
     c.lon_round, 
     c.lat_band,
     c.n_obs_chl,
     c.log_mean_chl, 
     c.geo_mean_chl, 
     c.log_sd_chl,
     e.ts AS bloom_date,
     e.chl_obs AS bloom_chl,
    (ln(e.chl_obs) - c.log_mean_chl) / c.log_sd_chl AS bloom_z,  -- creates a z-score for each bloom event relative to the pixel's own climatology
    s.sst_c,
    cu.cuti,
    year(e.ts) AS year,
    month(e.ts)AS month,
    dayofyear(e.ts) AS doy
FROM chl_pixel_clim AS c
JOIN chl_erd AS e
  ON e.lat = c.lat AND e.lon = c.lon
LEFT JOIN sst AS s          -- just left join so that when there is no bloom event there isn't missing data
  ON round(s.lat, 2) = c.lat_round
 AND round(s.lon, 2) = c.lon_round
 AND CAST(s.ts AS DATE) = CAST(e.ts AS DATE)
LEFT JOIN cuti AS cu         -- just left join so that when there is no bloom event there isn't missing data
  ON cu.lat = c.lat_band    -- for cuti just have the lat band as that is there isn't lon available
 AND CAST(cu.ts AS DATE) = CAST(e.ts AS DATE)
WHERE c.n_obs_chl >= 100     
  AND c.log_sd_chl > 0        
  AND e.chl_obs > 0           
  AND e.chl_obs > exp(c.log_mean_chl + 2 * c.log_sd_chl);

-- Local rain at each event
CREATE OR REPLACE TABLE event_rain AS
SELECT
    b.lat,
    b.lon,
    b.bloom_date,
    sum(r.rain_7day * ps.weight) / sum(ps.weight) AS rain_7day_local,
    min(ps.dist_km)AS nearest_station_km,
    count(*) AS n_stations
FROM bloom_events AS b
JOIN pixel_rain_sites AS ps
  ON ps.lat = b.lat AND ps.lon = b.lon
JOIN rain_lag AS r
  ON r.station = ps.station
 AND r.date  = CAST(b.bloom_date AS DATE)
WHERE r.rain_7day IS NOT NULL
GROUP BY b.lat, b.lon, b.bloom_date;

-- Bloom frequency map. 
CREATE OR REPLACE TABLE bloom_frequency AS
SELECT
    c.lat,
    c.lon, 
    c.lat_round, 
    c.lon_round,
    c.n_obs_chl,
    c.geo_mean_chl,
    c.log_mean_chl,
    c.log_sd_chl,
    count(b.bloom_date) AS n_blooms,
    count(b.bloom_date) / c.n_obs_chl AS bloom_freq_rel,
    avg(b.bloom_z)AS mean_bloom_z,
    avg(b.sst_c) AS mean_sst_at_bloom
FROM chl_pixel_clim AS c
LEFT JOIN bloom_events AS b
  ON b.lat = c.lat AND b.lon = c.lon
WHERE c.n_obs_chl >= 100
GROUP BY c.lat, c.lon, c.lat_round, c.lon_round,
         c.n_obs_chl, c.geo_mean_chl, c.log_mean_chl, c.log_sd_chl;

CREATE OR REPLACE TABLE chl_abs_exceed AS
SELECT lat, lon,
       count(*) n_obs,
       count(*) FILTER (WHERE chl_obs > 5.0) AS n_above_5,
       count(*) FILTER (WHERE chl_obs > 5.0) / count(*) AS frac_above_5
FROM chl_erd
WHERE chl_obs > 0
GROUP BY lat, lon;

-- Chlorophyll model
CREATE OR REPLACE TABLE chl_model AS
SELECT
    b.lat,
    b.lat_round,
    b.lon,
    b.lon_round,
    b.bloom_date,
    b.bloom_chl,
    b.bloom_z,
    b.sst_c,
    b.cuti,
    e.rain_7day_local, 
    e.nearest_station_km, 
    b.year, 
    b.doy
FROM bloom_events AS b
JOIN event_rain AS e
  ON e.lat = b.lat AND e.lon = b.lon AND e.bloom_date = b.bloom_date
ORDER BY b.bloom_date, b.lat, b.lon;