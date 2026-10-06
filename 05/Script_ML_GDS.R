# ============================================================
# GEOSPATIAL MACHINE LEARNING: RANDOM FOREST REGRESSION
# ============================================================

# Load packages for vector data, raster data, machine learning,
# data manipulation, plotting, and parallel processing.
library(sf)
library(terra)
library(caret)
library(dplyr)
library(tibble)
library(ggplot2)
library(ranger)
library(doParallel)

# Paths are relative to this script's folder (05/).
# In RStudio, use Session > Set Working Directory > To Source File Location.
input_dir  <- "input"
output_dir <- "output"
dir.create(output_dir, showWarnings = FALSE)


# ============================================================
# 1. LOAD THE SAMPLE DATA
# ============================================================

# Define the path to the point dataset containing the response variable.
samples_path <- file.path(input_dir, "c3_soildata_psd_modeling_0_50cm.gpkg")

# Read the point dataset as an sf object.
samples <- st_read(samples_path)

# Drop layers made only of coarse fragments (esqueleto = 1000 g/kg).
# They contain no fine earth, so sand = 0 there is not a measurement.
samples <- samples[samples$esqueleto < 1000, ]
cat("Samples after removing esqueleto = 1000:", nrow(samples), "\n")

# Inspect the sample data.
summary(samples)


# ============================================================
# 2. LOAD THE RASTER PREDICTORS
# ============================================================

# Define the directory containing the predictor rasters.
workdir_xvars <- input_dir

# List all GeoTIFF files in the predictor directory.
vars <- list.files(
  path = workdir_xvars,
  pattern = "\\.tif$",
  full.names = TRUE
)

# Stack all predictor rasters into a single SpatRaster object.
xvars <- terra::rast(vars)

# Check the names of the raster layers.
names(xvars)


# ============================================================
# 3. EXTRACT RASTER VALUES AT SAMPLE LOCATIONS
# ============================================================

# Reproject the sample points if their CRS differs from the rasters.
if (sf::st_crs(samples) != sf::st_crs(terra::crs(xvars))) {
  samples <- sf::st_transform(samples, terra::crs(xvars))
}

# Extract predictor values from each raster at the sample locations.
# The extracted values are appended to the original point attributes.
samples <- sf::st_as_sf(
  terra::extract(
    xvars,
    terra::vect(samples),
    bind = TRUE
  )
)

# Inspect the resulting variables and summary statistics.
names(samples)
summary(samples)


# ============================================================
# 4. PREPARE THE MODELING DATASET
# ============================================================

# Remove the geometry and variables that will not be used as predictors.
samples_df <- samples %>%
  st_drop_geometry() %>%
  dplyr::select(
    -dplyr::any_of(c(
      "id",
      "longitude",
      "latitude",
      "profundidade",
      "esqueleto",
      "silte",
      "argila",
      "log_silte1p_argila1p",
      "log_areia1p_argila1p",
      "log_esqueleto1p_argila1p"
    ))
  )

# Report the number of samples before removing missing values.
cat("Number of samples before removing NA:", nrow(samples_df), "\n")

# Remove observations with missing values in the response or predictors.
samples_df <- samples_df %>%
  dplyr::filter(complete.cases(.))

# Report the final number of complete samples.
cat("Number of complete samples:", nrow(samples_df), "\n")

# Inspect the structure and summary of the modeling dataset.
str(samples_df)
summary(samples_df)

# Convert sand content to percent.
samples_df$areia <- samples_df$areia / 10


# ============================================================
# 5. SPLIT THE DATA INTO TRAINING AND TEST SETS
# ============================================================

# Set a random seed to make the split reproducible.
set.seed(123)

# Use 70% of the observations for training.
# The response variable is used to preserve its distribution
# approximately across the training and test subsets.
trainIndex <- caret::createDataPartition(
  samples_df$areia,
  p = 0.70,
  list = FALSE,
  times = 1
)

# Create the training and independent test datasets.
points_train <- samples_df[trainIndex, ]
points_test  <- samples_df[-trainIndex, ]

# Check the number of observations in each subset.
nrow(points_train)
nrow(points_test)


# ============================================================
# 6. DEFINE THE CROSS-VALIDATION STRATEGY
# ============================================================

# Register a parallel backend so caret fits the folds in parallel.
# One core is left free for the operating system.
n_cores <- max(1, parallel::detectCores() - 1)
cl <- parallel::makePSOCKcluster(n_cores)
doParallel::registerDoParallel(cl)

# Configure 10-fold cross-validation.
# Predictions from the final tuning combination are retained.
ctrl <- trainControl(
  method = "cv",
  number = 10,
  savePredictions = "final",
  verboseIter = TRUE
)


# ============================================================
# 7. TRAIN THE RANDOM FOREST MODEL
# ============================================================

# Set the random seed for reproducible model training.
set.seed(123)

# Train a Random Forest regression model using ranger.
# Hyperparameters are evaluated by 10-fold cross-validation,
# and RMSE is used to select the final model.
model_rf <- caret::train(
  areia ~ .,
  data = points_train,
  method = "ranger",
  trControl = ctrl,
  metric = "RMSE",
  importance = "permutation",
  num.trees = 500,
  # caret already runs the folds in parallel; one thread per
  # ranger fit avoids oversubscribing the cores.
  num.threads = 1
)

# Release the parallel workers.
parallel::stopCluster(cl)
foreach::registerDoSEQ()

# Display the model results.
model_rf

# Visualize model performance across tuning combinations.
plot(model_rf)

# Display the hyperparameters selected for the final model.
model_rf$bestTune


# ============================================================
# 8. EVALUATE CROSS-VALIDATION PERFORMANCE
# ============================================================

# Keep only the out-of-fold predictions associated with
# the best hyperparameter combination.
pred_cv <- model_rf$pred %>%
  dplyr::filter(
    mtry == model_rf$bestTune$mtry,
    splitrule == model_rf$bestTune$splitrule,
    min.node.size == model_rf$bestTune$min.node.size
  )

# Calculate performance metrics from the cross-validation predictions.
metrics_cv <- caret::postResample(
  pred = pred_cv$pred,
  obs = pred_cv$obs
)

# Display cross-validation metrics.
metrics_cv


# ============================================================
# 9. EXAMINE VARIABLE IMPORTANCE
# ============================================================

# Calculate predictor importance from the final Random Forest model.
var_imp <- caret::varImp(model_rf)

# Display the variable importance values.
var_imp

# Plot the 20 most important predictors.
plot(
  var_imp,
  top = 20,
  main = "Variable importance"
)


# ============================================================
# 10. PREDICT THE INDEPENDENT TEST DATA
# ============================================================

# Predict sand content for observations that were not used
# during model training or cross-validation.
points_test$pred_areia <- predict(
  model_rf,
  newdata = points_test
)


# ============================================================
# 11. EVALUATE THE INDEPENDENT TEST DATA
# ============================================================

# Calculate RMSE for the independent test set.
rmse_test <- RMSE(
  pred = points_test$pred_areia,
  obs = points_test$areia
)

# Calculate R-squared for the independent test set.
r2_test <- R2(
  pred = points_test$pred_areia,
  obs = points_test$areia
)

# Calculate MAE for the independent test set.
mae_test <- MAE(
  pred = points_test$pred_areia,
  obs = points_test$areia
)

# Combine the test metrics into a single table.
metrics_test <- tibble(
  Dataset = "Independent test",
  RMSE = rmse_test,
  R2 = r2_test,
  MAE = mae_test
)

# Display independent validation metrics.
metrics_test


# ============================================================
# 12. COMPARE OBSERVED AND PREDICTED VALUES
# ============================================================

# Plot observed versus predicted sand content.
# The dashed 1:1 line represents perfect agreement.
# Define common axis limits from both observed and predicted values.
lims <- range(
  c(
    points_test$areia,
    points_test$pred_areia
  ),
  na.rm = TRUE
)

# Plot observed versus predicted values using identical axis limits.
ggplot(
  points_test,
  aes(
    x = areia,
    y = pred_areia
  )
) +
  geom_point(
    size = 1.6,
    alpha = 0.45,
    color = "#C2A46D"
  ) +
  geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    linewidth = 0.8,
    color = "gray40"
  ) +
  scale_x_continuous(limits = lims) +
  scale_y_continuous(limits = lims) +
  coord_equal() +
  labs(
    x = "Observed sand (%)",
    y = "Predicted sand (%)",
    title = "Random Forest — Independent Validation",
    subtitle = paste0(
      "R² = ", round(r2_test, 3),
      " | RMSE = ", round(rmse_test, 2),
      " | MAE = ", round(mae_test, 2)
    )
  ) +
  theme_bw(base_size = 13)


# ============================================================
# 13. APPLY THE MODEL TO THE RASTER PREDICTORS
# ============================================================

# Identify the predictor names used during model training.
pred_names <- setdiff(
  names(points_train),
  "areia"
)

# Check whether all model predictors are available in the raster stack.
missing_vars <- setdiff(
  pred_names,
  names(xvars)
)

if (length(missing_vars) > 0) {
  stop(
    paste(
      "Missing raster predictors:",
      paste(missing_vars, collapse = ", ")
    )
  )
}

# Select the raster predictors used by the model
# and place them in the same order as the training variables.
xvars_pred <- xvars[[pred_names]]

# Predict sand content for every raster cell with complete predictor data.
pred_areia <- terra::predict(
  xvars_pred,
  model_rf,
  na.rm = TRUE
)

# Display the spatial prediction.
plot(pred_areia)


# ============================================================
# 14. SAVE THE PREDICTION MAP
# ============================================================

# Export the prediction as a compressed GeoTIFF.
terra::writeRaster(
  pred_areia,
  file.path(output_dir, "pred_areia_rf.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = c(
    "COMPRESS=DEFLATE",
    "PREDICTOR=3",
    "ZLEVEL=9"
  )
)
