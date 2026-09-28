# cap423-slides

Lecture materials (slides and notebooks) for the course **CAP-423 – Geospatial Data Science** at INPE (Brazil's National Institute for Space Research).

**Instructors:** Édipo Cremon and Rennan Marujo

## Lectures

| Lecture | Topic | Slides | Notebook |
|---------|-------|--------|----------|
| 03 | Geospatial file formats and packages | [PDF](03_Geospatial_formats_and_packages.pdf) | [Python](03_Geospatial_formats_and_packages_python.ipynb) |

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
