# cap423-slides

Lecture materials (slides and notebooks) for the course **CAP-423 – Geospatial Data Science** at INPE (Brazil's National Institute for Space Research).

**Instructors:** Édipo Cremon and Rennan Marujo

## Lectures

| Lecture | Topic | Slides | Notebook |
|---------|-------|--------|----------|
| 01 | What is Geo Data Science? | [PDF](01_what_is_geo_data_science.pdf) | – |
| 02 | Spatial representation and CRS | [PDF](02_Spatial_representation_and_CRS.pdf) | – |
| 03 | Geospatial file formats and packages | [PDF](03_Geospatial_formats_and_packages.pdf) | [Python](03_Geospatial_formats_and_packages_python.ipynb) |
| 04 | Exploratory (spatial) data analysis | [PDF](04_exploratory_spatial_analysis.pdf) | see lecture 05 |
| 05 | Geospatial machine learning | [PDF](05_Geospatial_ML.pdf) | [`05/`](05/) (Python and R) |
| 06 | Geospatial machine learning II: spatial regression and spatial ML | [PDF](06_Geospatial_ML_regression.pdf) | [`06/`](06/) (Python) |

### 01 – What is Geo Data Science?

- **Course overview:** syllabus, module structure and assessment
- **Why Geo Data Science now:** large-scale Earth observation, open geospatial data, satellite image time series and new machine learning methods
- **Data Science recap:** data, information and knowledge; the data science process
- **Learning from data:** supervised learning (regression and classification) and unsupervised learning (clustering and dimensionality reduction)
- **What makes a problem geospatial:** spatial relationships relevant to the problem

### 02 – Spatial representation and CRS

- **From the real world to digital:** conceptual, logical and physical models
- **Raster data:** cells, extent, resolution, continuous vs. categorical values, data cubes (Brazil Data Cube) and raster formats (GeoTIFF/COG, NetCDF, HDF5, JPEG 2000, Zarr)
- **Vector data:** OGC Simple Features, geometry types (Point, LineString, Polygon, Multi-geometries, GeometryCollection), WKT, topological relationships and vector formats
- **Coordinate reference systems:** datums, projections, units, choosing a CRS and checking metadata

### 03 – Geospatial file formats and packages

- **Working environment:** R, Python, Conda and IDEs (VS Code, RStudio, Jupyter, PyCharm, Spyder)
- **Vector data formats:** Shapefile, GeoPackage, GeoJSON and GeoParquet
- **JSON and GeoJSON:** structure, data types, `load`/`loads`/`dump`/`dumps`, geometries, `Feature` and `FeatureCollection`
- **Python packages:**
  - NumPy: dimensions, `dtype`, indexing, boolean masks, broadcasting and statistics
  - Pandas: selection, filtering, new columns, grouping, joins, missing values and reading/writing
  - Shapely, Fiona and GeoPandas: reading/writing vector files, area, buffer, centroids and spatial join
  - OGR/GDAL: `ogrinfo`, `ogr2ogr`, `gdalinfo`, `gdal_translate`, `gdalwarp`, `gdal_merge`, `gdal_calc`
  - Rasterio: metadata, reading, masked data and windows (`Window`)

### 04 – Exploratory (spatial) data analysis

- **From EDA to ESDA:** exploring the response (Y) and the predictors (X), then adding "where?"
- **Point patterns:** quadrat analysis, Ripley's K, edge effects, nearest-neighbor distances (Clark-Evans) and kernel density
- **Geographic space vs. feature space:** sampling coverage, representativeness and cluster-based sampling
- **Spatial relationships:** distance, neighborhood and connectivity; the spatial weights matrix W
- **Spatial autocorrelation:** global Moran's I, Moran scatterplot and local Moran (LISA)
- **Semivariogram:** how dependence changes with distance; using the range for neighborhoods, sampling, validation and feature engineering
- **ESDA → modeling decisions:** what is spatially structured (Y, X or residuals) and how it shapes the model

### 05 – Geospatial machine learning

- **Spatial ML strategies:** from classic ML with random cross-validation to spatial ML with spatial cross-validation
- **Spatial inequality:** Gini index and spatial Gini
- **Spatial feature engineering:** distance to features, counting nearby features and point interpolation (KNN)
- **Spatial sampling** and geographic vs. feature-space coverage
- **Spatial cross-validation:** why random CV is optimistic; spatial blocks, clusters, buffered leave-one-out and kNNDM; spatial CV with an independent spatial test set

Hands-on in [`05/`](05/): predicting topsoil sand content (%) in Brazil from climate and terrain rasters.

| File | Content |
|------|---------|
| [01_EDA.ipynb](05/01_EDA.ipynb) | Load samples, extract raster values, explore the response and predictors |
| [02_ESDA.ipynb](05/02_ESDA.ipynb) | Global Moran's I, Moran scatterplot, sensitivity to k, semivariogram |
| [02b_Elevation_Range_13x13.ipynb](05/02b_Elevation_Range_13x13.ipynb) | Spatial feature: local elevation range with a 13×13 moving window |
| [03_Script_ML_GDS_Python.ipynb](05/03_Script_ML_GDS_Python.ipynb) | Random Forest with random train/test split and 10-fold CV, prediction map |
| [04_Script_ML_GDS_Python_spatialCV.ipynb](05/04_Script_ML_GDS_Python_spatialCV.ipynb) | The same model with spatial blocks, spatial CV and an independent spatial test |
| [Script_ML_GDS.R](05/Script_ML_GDS.R) | R version of the Random Forest workflow (`sf`, `terra`, `caret`, `ranger`) |

Spatial feature engineering examples in [`05/feature-engineering/`](05/feature-engineering/):

| File | Content |
|------|---------|
| [fires_dist_to_road.ipynb](05/feature-engineering/fires_dist_to_road.ipynb) | Distance from each fire (BDQueimadas) to the nearest road with `sjoin_nearest` |
| [nearby_counting.ipynb](05/feature-engineering/nearby_counting.ipynb) | Number of *Araucaria angustifolia* records within a buffer around each record, with an interactive map |
| [knn-interpolation.ipynb](05/feature-engineering/knn-interpolation.ipynb) | KNN interpolation of topsoil clay content on a 10 km grid |

Input data (soil samples, Araucaria records and predictor rasters) are in [`05/input/`](05/input/); prediction maps are written to `05/output/`. Run the notebooks and the R script from inside the `05/` folder. The fire and road layers are in `05/feature-engineering/`.

### 06 – Geospatial machine learning II: spatial regression and spatial ML

- **Machine learning vs. spatial regression:** location and proximity matter; ordinary regression assumes independent residuals
- **Spatial regression models:**
  - spatial lag: neighboring values of Y influence Y
  - spatial error: spatial dependence remains in the unexplained part
  - Geographically Weighted Regression (GWR): the relationship between X and Y varies across space (spatial heterogeneity)
- **Limitations of GWR:** linear relationships, sensitivity to bandwidth and kernel, local multicollinearity, overfitting and multiple local tests, remaining residual autocorrelation, poor generalization to new areas
- **Spatial machine learning:** from classic ML with random CV to spatial ML with spatial CV; local ML models (GRF/GWRF, GW-SVM, GWANN, GW-XGBoost)
- **Spatial Random Forest variants:** coordinates as predictors, Moran eigenvectors, RF + kriging of residuals, RFsp, RFSI, RF-GLS, Geographical RF, spatial-context RF (SRF)

Hands-on in [`06/`](06/):

| File | Content |
|------|---------|
| [06_Araucaria_pseudo_absence_sampling.ipynb](06/06_Araucaria_pseudo_absence_sampling.ipynb) | Pseudo-absences for *Araucaria angustifolia*: clean the presences, 10 km exclusion buffer, random sampling inside Brazil |
| [07_Araucaria_KMeans_sampling.ipynb](06/07_Araucaria_KMeans_sampling.ipynb) | K-means (10 classes) on the standardized predictors: how presences and pseudo-absences occupy the feature space |
| [08_Araucaria_RF_Classification_SpatialCV.ipynb](06/08_Araucaria_RF_Classification_SpatialCV.ipynb) | Random Forest classification of presence/pseudo-absence with 2° spatial blocks (80/20 spatial split, 10-fold spatial CV), probability and binary occurrence maps |
| [09_RF_vs_Spatial_Lag_spatialCV.ipynb](06/09_RF_vs_Spatial_Lag_spatialCV.ipynb) | Sand content with a spatial lag model on the same spatial folds and test as `05/04`, compared with the Random Forest; prediction map |
| [10_GRF_Classification_PyGRF_spatialCV.ipynb](06/10_GRF_Classification_PyGRF_spatialCV.ipynb) | Geographical Random Forest ([PyGRF](https://github.com/geoai-lab/PyGRF)) classifying sandy (≥ 50 %) vs. non-sandy soils: global vs. local vs. combined models, local feature importance |

Notes on the data:

- Notebooks 06–08 read the Araucaria records, the Brazil boundary (`brazil.gpkg`) and the pseudo-absences (`Araucaria_pseudo_absence.gpkg`, created by notebook 06) from the course folder on the BDC-Lab. To run them elsewhere, change the paths at the top of each notebook; the Araucaria records and the rasters are in [`05/input/`](05/input/).
- Notebooks 09 and 10 read the soil samples and rasters from `input/` next to the notebook: run them from a folder that contains the data of [`05/input/`](05/input/) (for example, copy or link it as `06/input`).

### Seminars

About 20 minutes plus questions; slides by e-mail until 15/11/2026.

- **16/11/2026:** trajectory data (e.g. MovingPandas); cloud-optimized rasters (GeoTIFF, NetCDF/HDF5, GeoZarr, GRIB, JPEG 2000); cloud-optimized vectors (GeoParquet, GeoArrow, FlatGeobuf, Shapefile, GeoPackage); geospatial visualization (e.g. MapLibre, deck.gl, Kepler.gl)
- **18/11/2026:** TorchGeo; PySITS; Spatial Random Forest (RF-GLS)

## Running the notebooks

We recommend running the Notebook on the [BDC-Lab](https://geolab.inpe.br/bdc/lab/hub/login?next=%2Fbdc%2Flab%2Fhub%2Fspawn) or using a Conda environment for the course:

```bash
conda create -n cap423 -c conda-forge python numpy pandas scipy shapely fiona geopandas gdal rasterio \
    scikit-learn libpysal esda spreg scikit-gstat matplotlib folium mapclassify jupyterlab
conda activate cap423
pip install PyGRF   # lecture 06, notebook 10
jupyter lab
```

Then open the lecture's notebook in Jupyter.

The R script of lecture 05 needs R with these packages (also available from conda-forge):

```bash
conda create -n cap423-r -c conda-forge r-base r-sf r-terra r-caret r-ranger r-doparallel r-dplyr r-ggplot2 r-tibble
```

## Further reading

- [Introdução à Programação com Dados Geoespaciais (SER-347/CAP-419)](https://prog-geo.github.io/introducao-programacao/index.html) (in Portuguese)
- [Array programming with NumPy (Nature, 2020)](https://www.nature.com/articles/s41586-020-2649-2)
- [JSON](https://www.json.org/json-en.html)
- [Geographic Data Science with Python](https://geographicdata.science/book/intro.html), ch. 11–13 (spatial feature engineering, spatial regression)
- [Spatial Data Science with Applications in R](https://r-spatial.org/book/), ch. 16 (spatial regression)
- [PyGRF: Geographical Random Forest in Python](https://github.com/geoai-lab/PyGRF)
- [SpatialML: Geographically Weighted Random Forest in R](https://cran.r-project.org/web/packages/SpatialML/vignettes/SpatialML.html)
- [Random Forest for spatial prediction (RFsp)](https://doi.org/10.7717/peerj.5518)
