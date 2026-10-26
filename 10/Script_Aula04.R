# ------------------------------------------------------------------------------
# Script: Classificação de Uso do Solo e Validação (SITS)
# Área de Estudo: Luís Eduardo Magalhães (LEM) - BDC (Landsat)
# ------------------------------------------------------------------------------

# 1. Pacotes Principais
library(sits)
library(sf)
library(tidyverse)

# 2. Configuração dos Diretórios de Saída
dir_probs   <- "LEM_probs"
dir_smooth  <- "LEM_smooth"
dir_maps    <- "LEM_maps"
dir_metrics <- "LEM_metrics"

purrr::walk(
  c(dir_probs, dir_smooth, dir_maps, dir_metrics),
  ~ if (!dir.exists(.x)) dir.create(.x, recursive = TRUE)
)

# ------------------------------------------------------------------------------
# 1. Definição do Cubo de Dados e Obtenção de Amostras
# ------------------------------------------------------------------------------

# 1.1 Conexão ao Cubo Landsat no BDC (Matopiba / LEM)
# Bandas do Landsat no BDC usam nomes RED, NIR08, SWIR16, SWIR22, NDVI, EVI

cubo_landsat <- sits_cube(
  source     = "BDC",
  collection = "LANDSAT-OLI-16D",
  bands      = c("RED", "NIR08", "SWIR16", "SWIR22", "NDVI", "EVI"),
  roi        = c(
    lon_min = -45.85, lat_min = -12.12,
    lon_max = -45.80, lat_max = -12.07
  ),
  start_date = "2019-09-30",
  end_date   = "2020-09-29"
)


plot(cubo_landsat, bands = "RED", "NIR08", "SWIR22")
plot(cubo_landsat, band = "NDVI")



# 1.2 Carregamento e extração das séries temporais nas amostras
#samples_dir  <- system.file("data", package = "sitsdata")
#amostras_raw <- readRDS(file.path(samples_dir, "df_samples_cerrado_lem.rds"))
#amostras_raw <- amostras_raw |> filter(label %in% c("Cerrado", "Pasture"))


## SUAS próprias amostras ---
# Basta um data.frame (ou sf) com colunas de coordenadas e uma coluna "label".

amostras_limpas <- readRDS("amostras_limpas_matopiba.rds")
# Filtrar só as 2 classes que você quer
amostras_filtradas <- amostras_limpas |>
  dplyr::filter(label %in% c("Cerrado", "Pasture"))

table(amostras_filtradas$label)   



# amostras_brutas <- samples              
amostras_sits <- sits_get_data(
  cube       = cubo_landsat,   
  samples    = amostras_raw,
  start_date = "2019-09-30",
  end_date   = "2020-09-29",
  multicores = 3
)

# Visualizar distribuição das amostras
print(table(amostras_sits$label))

# ------------------------------------------------------------------------------
# 2. Treinamento e Classificação
# ------------------------------------------------------------------------------

# 2.1 Treinamento do modelo Random Forest
modelo_rf <- sits_train(
  samples   = amostras_sits,
  ml_method = sits_rfor(num_trees = 200)
)

# 2.2 Geração do cubo de probabilidades
cubo_probs <- sits_classify(
  data       = cubo_landsat,   # <- cubo Landsat
  ml_model   = modelo_rf,
  output_dir = dir_probs,
  multicores = 4
)

plot(cubo_probs, title = "Probabilidades por Classe (Landsat)")

# ------------------------------------------------------------------------------
# 3. Pós-Processamento: Incerteza, Suavização e Rotulagem
# ------------------------------------------------------------------------------

# 3.1 Cálculo da Incerteza da Classificação (Entropia)
cubo_incerteza <- sits_uncertainty(
  cube       = cubo_probs,
  type       = "entropy",
  output_dir = dir_probs,
  multicores = 4
)

plot(cubo_incerteza, title = "Mapa de Incerteza da Classificação (Entropia)")

# 3.2 Filtro Bayesiano para redução de ruído espacial
cubo_smooth <- sits_smooth(
  cube        = cubo_probs,
  type        = "bayes",
  window_size = 7,
  smoothness  = 20,
  output_dir  = dir_smooth,
  multicores  = 4
)

plot(cubo_smooth, title = "Cubo de Probabilidade Suavizado (Filtro Bayesiano)")

# 3.3 Atribuição do rótulo final (ArgMax)
mapa_final <- sits_label_classification(
  cube       = cubo_smooth,
  output_dir = dir_maps,
  multicores = 4
)



# Cores personalizadas (apenas Cerrado e Pasture)
minhas_cores <- c(
  "Cerrado" = "#228B22",  # verde escuro
  "Pasture" = "#F1C40F"   # amarelo
)

plot(
  mapa_final,
  title  = "Mapeamento Final de Uso do Solo - LEM",
  legend = minhas_cores
)


# Modo estático do tmap (necessário para renderizar e para tmap_save)
tmap::tmap_mode("plot")

p_mapa <- plot(
  mapa_final,
  title  = "Mapeamento Final de Uso do Solo - LEM (Landsat)",
  legend = minhas_cores
)

# Salvar mapa final em GeoTIFF (mosaico consolidado)
sits_mosaic(
  cube       = mapa_final,
  crs        = "EPSG:4326",
  output_dir = dir_maps,
  multicores = 4
)

# Salvar gráfico do mapa em PNG
tmap::tmap_save(
  tm       = p_mapa,
  filename = file.path(dir_maps, "mapa_final_LEM_landsat.png"),
  width    = 10,
  height   = 7,
  dpi      = 200
)

# ------------------------------------------------------------------------------
# 4. Validação Cruzada k-Fold e Métricas
# ------------------------------------------------------------------------------

# 4.1 Execução da validação k-Fold (5-fold)
validacao_kfold <- sits_kfold_validate(
  samples   = amostras_sits,
  folds     = 5,
  ml_method = sits_rfor(num_trees = 200)
)

# Exibe resumo das métricas no console
print(validacao_kfold)

# 4.2 Extração da Acurácia Global
acuracia_global <- as.numeric(validacao_kfold$overall["Accuracy"])
cat("Acurácia Global do Modelo:", round(acuracia_global * 100, 2), "%\n")

# 4.3 Plota Matriz de Confusão com ggplot2
matriz_df <- as.data.frame(validacao_kfold$table)

p_matriz <- ggplot(matriz_df, aes(x = Reference, y = Prediction, fill = Freq)) +
  geom_tile(color = "white") +
  geom_text(aes(label = Freq), color = "black", size = 5, fontface = "bold") +
  scale_fill_gradient(low = "#e0f3f8", high = "#056cb6") +
  labs(
    title    = "Matriz de Confusão: Random Forest (SITS - Landsat)",
    subtitle = paste0("Acurácia Global: ", round(acuracia_global * 100, 2), "%"),
    x        = "Referência (Campo)",
    y        = "Predição (Modelo)",
    fill     = "Frequência"
  ) +
  theme_minimal() +
  theme(
    plot.title  = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

print(p_matriz)

# ------------------------------------------------------------------------------
# 5. Salvamento das Métricas de Validação
# ------------------------------------------------------------------------------

# 5.1 Tabela da matriz de confusão em CSV
write.csv(
  matriz_df,
  file = file.path(dir_metrics, "matriz_confusao_landsat.csv"),
  row.names = FALSE
)

# 5.2 Resumo geral (acurácia, kappa, etc.) em CSV
resumo_overall <- as.data.frame(validacao_kfold$overall)
write.csv(
  resumo_overall,
  file = file.path(dir_metrics, "resumo_validacao_landsat.csv"),
  row.names = TRUE
)

# 5.3 Métricas por classe em CSV
write.csv(
  validacao_kfold$byClass,
  file = file.path(dir_metrics, "metricas_por_classe_landsat.csv"),
  row.names = TRUE
)

# 5.4 Matriz de confusão em PNG (ggplot → ggsave OK)
ggsave(
  filename = file.path(dir_metrics, "matriz_confusao_landsat.png"),
  plot     = p_matriz,
  width    = 8,
  height   = 6,
  dpi      = 300
)

cat("\nArquivos gerados:\n")
cat(" - Mapa final (GeoTIFF e PNG):", dir_maps, "\n")
cat(" - Métricas (CSV e PNG):      ", dir_metrics, "\n")
