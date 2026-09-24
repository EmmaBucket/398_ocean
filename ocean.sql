CREATE OR REPLACE VIEW chl_dineof AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(chlor_a AS "DOUBLE") AS chl_filled FROM "datasets/chlorophyll_*_dineof.csv" WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);

CREATE OR REPLACE VIEW chl_erd AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(chla AS "DOUBLE") AS chl_obs FROM "datasets/erd_chlorophyll_*.csv" WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);

CREATE OR REPLACE VIEW cuti AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS DOUBLE) AS lat, CAST(CUTI AS DOUBLE) AS cuti FROM "datasets/erdCUTIdaily_c010_b954_09c2.csv" WHERE (TRY_CAST(latitude AS DOUBLE) IS NOT NULL);

CREATE OR REPLACE VIEW glider AS SELECT CAST(mission AS INTEGER) AS mission, CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(depth AS "DOUBLE") AS depth, CASE  WHEN ((doxy = 'NaN')) THEN (NULL) ELSE TRY_CAST(doxy AS "DOUBLE") END AS doxy, CASE  WHEN ((temperature = 'NaN')) THEN (NULL) ELSE TRY_CAST(temperature AS "DOUBLE") END AS temperature, CASE  WHEN ((salinity = 'NaN')) THEN (NULL) ELSE TRY_CAST(salinity AS "DOUBLE") END AS salinity, CASE  WHEN ((chlorophyll = 'NaN')) THEN (NULL) ELSE TRY_CAST(chlorophyll AS "DOUBLE") END AS chl_glider FROM read_csv_auto('datasets/binnedCUGN80_52e6_d0ac_a341.csv', (all_varchar = CAST('t' AS BOOLEAN))) WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);

CREATE OR REPLACE VIEW kelp AS SELECT * FROM "datasets/kelp_landsat.parquet";

CREATE OR REPLACE VIEW pdo AS SELECT make_date("Year", "month"(strptime(month_name, '%b')), 1) AS date, pdo FROM (SELECT * FROM (SELECT * FROM "datasets/pdo_data.csv") UNPIVOT (pdo FOR month_name IN (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, "Dec")));

CREATE OR REPLACE VIEW rain AS SELECT STATION AS station, "NAME" AS "name", CAST(LATITUDE AS "DOUBLE") AS lat, CAST(LONGITUDE AS "DOUBLE") AS lon, CAST(DATE AS "DATE") AS date, CASE  WHEN ((PRCP = -9999)) THEN (NULL) ELSE (CAST(PRCP AS "DOUBLE") * 25.4) END AS prcp, CASE  WHEN ((filename ~~ '%SB%')) THEN ('santa_barbara') ELSE 'ventura' END AS region FROM read_csv_auto('datasets/land_weather_*.csv', (union_by_name = CAST('t' AS BOOLEAN)), (filename = CAST('t' AS BOOLEAN))) WHERE (PRCP IS NOT NULL);

CREATE OR REPLACE VIEW reef AS SELECT SITE AS site, TRANSECT AS transect, CAST(DATE AS "DATE") AS date, "YEAR" AS "year", "MONTH" AS "month", SCIENTIFIC_NAME AS species, COMMON_NAME AS common_name, "nullif"(DENSITY, -99999) AS density, "nullif"(PERCENT_COVER, -99999) AS percent_cover, "nullif"(WM_GM2, -99999) AS wet_biomass FROM read_csv_auto('datasets/SBS_All_Species_Biomass_at_transect_20260311.csv');

CREATE OR REPLACE VIEW sst AS SELECT CAST("time" AS TIMESTAMP) AS ts, CAST(latitude AS "DOUBLE") AS lat, CAST(longitude AS "DOUBLE") AS lon, CAST(analysed_sst AS "DOUBLE") AS sst_c FROM "datasets/SST_MUR_*.csv" WHERE (TRY_CAST(latitude AS "DOUBLE") IS NOT NULL);
