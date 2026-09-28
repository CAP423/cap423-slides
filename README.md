# cap423-slides

Lecture materials (slides and notebooks) for the course **CAP-423 – Geospatial Data Science** at INPE (Brazil's National Institute for Space Research).

**Instructors:** Édipo Cremon and Rennan Marujo

## Lectures

| Lecture | Topic | Slides | Notebook |
|---------|-------|--------|----------|
| 01 | What is Geo Data Science? | [PDF](01_what_is_geo_data_science.pdf) | – |
| 02 | Spatial representation and CRS | [PDF](02_Spatial_representation_and_CRS.pdf) | – |
| 03 | Geospatial file formats and packages | [PDF](03_Geospatial_formats_and_packages.pdf) | [Python](03_Geospatial_formats_and_packages_python.ipynb) |

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

## Running the notebooks

We recommend running the Notebook on the [BDC-Lab](https://geolab.inpe.br/bdc/lab/hub/login?next=%2Fbdc%2Flab%2Fhub%2Fspawn) or using a Conda environment for the course:

```bash
conda create -n cap423 -c conda-forge python numpy pandas shapely fiona geopandas gdal rasterio jupyterlab
conda activate cap423
jupyter lab
```

Then open the lecture's notebook in Jupyter.

## Further reading

- [Introdução à Programação com Dados Geoespaciais (SER-347/CAP-419)](https://prog-geo.github.io/introducao-programacao/index.html) (in Portuguese)
- [Array programming with NumPy (Nature, 2020)](https://www.nature.com/articles/s41586-020-2649-2)
- [JSON](https://www.json.org/json-en.html)
