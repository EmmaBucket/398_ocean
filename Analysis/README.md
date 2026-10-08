Datasets explained and sources cited: 

Coordinates used for erddap datasets: 
Lat: 33.69 , 34.51
Longitude: -120.52 , -118.98 

Time used: 
Start 2018-01-01
End  2026-05-01
- for some I have extended the time period - will include in their section

## Datasets:

### Glider
Name Database: Glider<br>
Glider temperature and oxygen - CUGN Line 80<br>
Source: California Underwater Glider Network, Scripps Institution of Oceanography<br>
Download: (the link above)<br>
Accessed: 2026-09-19<br>
Save as: datasets/ventura_3D_glider_data.csv<br>
Cite: Rudnick, D. L., R. E. Davis, and J. T. Sherman. 2016. Spray Underwater Glider Operations. J. Atmos. Oceanic Technol. 33(6): 1113–1122. https://doi.org/10.1175/JTECH-D-15-0252.1<br>
Notes: oxygen (doxy) is in µmol/kg and starts in 2017. The file has an ERDDAP units row.

--- 

### Chl_dineof
Name Database: chl_dineof<br>
Name: Dataset Title: 	Chlorophyll (Gap-filled DINEOF), NOAA S-NPP NOAA-20 VIIRS and Copernicus S-3AOLCI, Science Quality, Global 2km, 2018-recent, Daily <br>  
<!-- Link -->
Source : https://coastwatch.noaa.gov/erddap/griddap/noaacwNPPN20S3ASCIDINEOF2kmDaily.html
Download: link above provides<br>
Accessed: 2026-08-01<br>
Save as: chl_dineof<br>
Cite: National Oceanic and Atmospheric Administration, National Centers for Environmental Information. (2018). Chlorophyll (Gap-filled DINEOF), NOAA S-NPP NOAA-20 VIIRS and Copernicus S-3A.  https://coastwatch.noaa.gov/erddap/griddap/noaacwNPPN20S3ASCIDINEOF2kmDaily.html Accessed: 2026-08-01<br>
Notes: Dineof estimates to what the chlorophyll numbers would have been in case there is cloud coverage.<br>

---
### chl_erd
Name: chl_erd<br>
Source:	Chlorophyll a, North Pacific, NOAA VIIRS, 750m resolution, 2015-present (1 Day
Composite) <br>
<!-- Link -->
Download: https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdVHNchla1day.html
Accessed: 2026-07-01<br>
Cite: National Oceanic and Atmospheric Administration, National Centers for Environmental Information. (2018). Chlorophyll a, North Pacific, NOAA VIIRS, 750m resolution, 2015-present (1 Day
Composite)https://coastwatch.pfeg.noaa.gov/erddap/griddap/erdVHNchla1day.html Accessed: 2026-07-01<br>
Notes: In addition to dineof chlorophyll, I wanted to be able to verify and estimate to how much data was observed versus predicted.


--- 
### kelp
Name: kelp<br>
Source : SBC LTER: Time series of quarterly NetCDF files of kelp biomass in the canopy from Landsat 5, 7 and 8, since 1984 (ongoing)<br>
<!-- Link -->
Download:https://doi.org/10.6073/pasta/8d67f78530eadd77aefd85e66f5643de
Accessed: 2026-09-01<br>
Save as: kelp<br>
Cite: Bell, T., K. Cavanaugh, and D. Siegel. 2026. SBC LTER: Time series of quarterly NetCDF files of kelp biomass in the canopy from Landsat 5, 7 and 8, since 1984 (ongoing) ver 34. Environmental Data Initiative. https://doi.org/10.6073/pasta/8d67f78530eadd77aefd85e66f5643de (Accessed 2026-09-01).<br>
Notes: reviews the number of kelp biomass in canopy.<br>
kelp_landsat.parquet is derived, not downloaded:
  scripts/step9_kelp.py reads LandsatKelpBiomass_2026_Q2_withmetadata.nc,
  keeps the 111,222 pixels inside the study box, converts the -1
  no-data values to NULL, and writes build/_cache_kelp_domain.parquet,
  which was renamed to datasets/kelp_landsat.parquet.

---
### PDO 
Name: pdo<br>
Source : NOAA, Pacific Decadal Oscillation(PDO)<br>
<!-- Link -->
Download:https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/v6/index/ersst.v6.pdo.dat
Accessed: 2026-06-20<br>
Save as: pdo<br>
Cite: National Oceanic and Atmospheric Administration, National Centers for Environmental Information. (2018).Pacific Decadal Oscillation(PDO), https://www.ncei.noaa.gov/access/monitoring/pdo/ Accessed 2026-06-20<br>
Notes

---
### Rain

Name: rain
Source :  NOAA NCEI Climate Data Online — Global Historical Climatology
        Network-Daily (GHCN-Daily), CSV product<br>
Timeline: 2014- 2026<br>
 <!-- Link -->
Download:https://www.ncei.noaa.gov/cdo-web/search  (two separate orders)
     Order 1 — FIPS:06111 (Ventura County), 2014-01-01 to 2026-05-31
            Types: AWND DAPR MDPR PRCP WT01 WT02 WT03 WT07 WT08
            Saved as: datasets/land_weather_Ventura.csv
     Order 2 — FIPS:06083 (Santa Barbara County), 2014-01-01 to 2026-06-14
            Types: MXPN MNPN EVAP MDPR DAPR PRCP SNWD SNOW WESD WESF
            Saved as: datasets/land_weather_SB.csv
Accessed: 2026-08-11<br>
Save as: rain <br>
Cite: NOAA NCEI Climate Data Online — Global Historical Climatology<br>
        Network-Daily (GHCN-Daily), CSV product, https://www.ncei.noaa.gov/cdo-web/search Accessed: 2026-08-11<br>
Notes: Land measured PRCP that is measured in Ventura County and Santa Barbara county<br>

---
### Reef
Name: reef<br>
Source : SBC LTER: Reef: Seasonal Kelp Forest Community Dynamics: biomass of kelp forest species, ongoing since 2008<br>
timeline: 2008-2025<br>
<!-- Link -->
Download: https://portal.edirepository.org/nis/mapbrowse?packageid=knb-lter-sbc.182.3<br>
Accessed: 2026-09-01<br>
file name Saved as: ../datasets/LandsatKelpBiomass_2026_Q2_withmetadata.nc<br>
Cite: Reed, D. and R. Miller. 2026. SBC LTER: Reef: Seasonal Kelp Forest Community Dynamics: biomass of kelp forest species, ongoing since 2008 ver 3. Environmental Data Initiative. https://doi.org/10.6073/pasta/ec39d4b993d15f127e4ab050705fed2e (Accessed 2026-09-01).<br>
Notes: 
Sea urchins
Purple Urchin Scientific name: Strongylocentrotus purpuratus<br>
Red Urchin - Mesocentrotus franciscanus<br>
Crowned Sea Urchin - Centrostephanus coronatus<br>
White Sea Urchin : Lytechinus pictus<br>
Predators<br>
Sunflower Sea Star - Pycnopodia helianthoides (predator of sea urchin with illness)<br>
California Spiny Lobster- Panulirus interruptus (another predator)<br>
Kelp<br>
Giant Kelp <br>
Palm Kelp <br>

---
### SST Sea Surface Temperature

Name: sst<br>
Source Multi-scale Ultra-high Resolution (MUR) SST Analysis fv04.1, Global, 0.01°,
2002-present, Daily<br>
timeline: 2008 - 2026<br>
<!-- Link -->
Download:https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.html
Accessed: 2026-08-01<br>
File Saved as: datasets/SST_MUR_*.csv<br>
Cite: National Oceanic and Atmospheric Administration, National Centers for Environmental Information. (2018). Multi-scale Ultra-high Resolution (MUR) SST Analysis fv04.1, Global, 0.01°,
2002-present, Daily https://coastwatch.pfeg.noaa.gov/erddap/griddap/jplMURSST41.html Accessed: 2026-08-01, 2008-2017 dataset was accessed 2026-10-07<br>
Notes: Sea Surface temperature varies between season and Pacific Decal Occilator want to see the influence of the temperature on the biodiversity<br>

---

### CUTI Coastal Upwelling Transport Index
Name: cuti<br>
Source : Coastal Upwelling Transport Index (CUTI), Daily<br>
<!-- Link -->
Download:https://oceanview.pfeg.noaa.gov/erddap/griddap/erdCUTIdaily.html<br>
Accessed: 2026-08-16<br>
Save as: cuti<br>
Cite: Source: National Oceanic and Atmospheric Administration, National Centers for Environmental Information. (2018). Coastal Upwelling Transport Index (CUTI), Daily. https://oceanview.pfeg.noaa.gov/erddap/griddap/erdCUTIdaily.html Accessed: 2026-08-16<br>
Notes: Coastal upwelling transport index with units m2 s-1.<br>
