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

Input data (soil samples and predictor rasters) are in [`05/input/`](05/input/); prediction maps are written to `05/output/`. Run the notebooks and the R script from inside the `05/` folder.

## Running the notebooks

We recommend running the Notebook on the [BDC-Lab](https://geolab.inpe.br/bdc/lab/hub/login?next=%2Fbdc%2Flab%2Fhub%2Fspawn) or using a Conda environment for the course:

```bash
conda create -n cap423 -c conda-forge python numpy pandas scipy shapely fiona geopandas gdal rasterio \
    scikit-learn libpysal esda scikit-gstat matplotlib jupyterlab
conda activate cap423
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
