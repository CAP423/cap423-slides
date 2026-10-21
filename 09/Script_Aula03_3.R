###==================================================================
# Curso Introdução ao SITS — Script consolidado
# Sentinel-2 (BDC) + Índices + SOM + Agrupamento Hierárquico
###==================================================================

# ------------------------------------------------------------------
# 0. INSTALAÇÃO DOS PACOTES (executar apenas uma vez)
# ------------------------------------------------------------------
# Descomente as linhas abaixo caso ainda não tenha os pacotes instalados.
# if (!require("sits"))     install.packages("sits")
# if (!require("sitsdata")) install.packages("sitsdata")
# if (!require("sf"))       install.packages("sf")
# if (!require("tidyverse")) install.packages("tidyverse")

# ------------------------------------------------------------------
# 1. CARREGAMENTO DOS PACOTES
# ------------------------------------------------------------------
library(sits)       # análise de séries temporais de imagens de satélite
library(sitsdata)   # conjuntos de dados de exemplo
library(sf)         # dados vetoriais / espaciais
library(tidyverse)  # dplyr, purrr, ggplot2, tibble, etc.

# ------------------------------------------------------------------
# 2. PARÂMETROS GERAIS
# ------------------------------------------------------------------
diretorio_saida   <- "Alarcon/Curso_SITS"
n_cores           <- 30    # ajuste ao número de núcleos da sua máquina
semente_aleatoria <- 13    # reprodutibilidade do SOM

if (!dir.exists(diretorio_saida)) dir.create(diretorio_saida, recursive = TRUE)
set.seed(semente_aleatoria)

# ------------------------------------------------------------------
# 3. CUBO SENTINEL-2 (BDC)
# ------------------------------------------------------------------
cubo_s2 <- sits_cube(
  source     = "BDC",
  collection = "SENTINEL-2-16D",
  bands      = c("B02", "B04", "B08", "B11", "B12"),
  roi        = c(
    lon_min = -46.55, lat_min = -12.35,
    lon_max = -45.45, lat_max = -11.95
  ),
  start_date = "2019-09-30",
  end_date   = "2020-09-29"
)


# ------------------------------------------------------------------
# 3.1 CUBO SENTINEL-2 (BDC)
# ------------------------------------------------------------------
#roi = roi <- st_read("sua_pasta/pasta/arquivo.gpkg")

#cubo_s2 <- sits_cube(
  #source     = "BDC",
  #collection = "SENTINEL-2-16D",
  #bands      = c("B02", "B04", "B08", "B11", "B12"),
  #roi        = roi,
  #start_date = "2019-09-30",
  #end_date   = "2020-09-29"
#)





# ------------------------------------------------------------------
# 4. ÍNDICES ESPECTRAIS
# ------------------------------------------------------------------
# NDVI — vigor/densidade da vegetação
cubo_s2 <- sits_apply(
  data       = cubo_s2,
  NDVI       = (B08 - B04) / (B08 + B04),
  output_dir = diretorio_saida,
  multicores = n_cores
)
plot(cubo_s2, band = "NDVI")

# EVI — corrige efeitos de solo e atmosfera (útil em dossel denso)
cubo_s2 <- sits_apply(
  data       = cubo_s2,
  EVI        = 2.5 * (B08 - B04) / (B08 + 6 * B04 - 7.5 * B02 + 1),
  output_dir = diretorio_saida,
  multicores = n_cores
)
plot(cubo_s2, band = "EVI")

# NBR — detecção de áreas queimadas / estresse hídrico
cubo_s2 <- sits_apply(
  data       = cubo_s2,
  NBR        = (B08 - B12) / (B08 + B12),
  output_dir = diretorio_saida,
  multicores = n_cores
)
plot(cubo_s2, band = "NBR")

sits_bands(cubo_s2)

# ------------------------------------------------------------------
# 5. AMOSTRAS E EXTRAÇÃO DAS SÉRIES TEMPORAIS
# ------------------------------------------------------------------
samples_dir     <- system.file("data", package = "sitsdata")
amostras_brutas <- readRDS(file.path(samples_dir, "df_samples_cerrado_lem.rds"))
#-------------------------------------------------------------------
# --- Opção B: SUAS próprias amostras ---
# Basta um data.frame (ou sf) com colunas de coordenadas e uma coluna "label".
# Exemplo com um arquivo vetorial (gpkg, shp, etc.):
#
# samples <- sf::st_read("caminho/para/suas_amostras.gpkg")
# samples$label <- samples$Descri          # usa a coluna de descrição como rótulo
# table(samples$label)                     # confere as classes
# amostras_brutas <- samples               # substitui pelo seu conjunto
#
# Também funciona com data.frame simples, desde que tenha:
#   longitude | latitude | label



amostras_sits <- sits_get_data(
  cube       = cubo_s2,
  samples    = amostras_brutas,
  start_date = "2019-09-30",
  end_date   = "2020-09-29",
  multicores = n_cores
)
print(amostras_sits)




# ------------------------------------------------------------------
# 6. ESTATÍSTICAS AGREGADAS POR CLASSE E DATA
# ------------------------------------------------------------------
estatisticas_amostras <- purrr::map2_dfr(
  amostras_sits$time_series,
  amostras_sits$label,
  ~ .x |>
    dplyr::select(Index, NDVI, EVI, NBR) |>
    dplyr::mutate(label = .y)
) |>
  dplyr::group_by(label, Index) |>
  dplyr::summarise(
    ndvi_media   = mean(NDVI, na.rm = TRUE),
    ndvi_mediana = median(NDVI, na.rm = TRUE),
    ndvi_sd      = sd(NDVI, na.rm = TRUE),
    .groups      = "drop"
  )
head(estatisticas_amostras)

# Gráfico comparativo entre classes
ggplot(estatisticas_amostras, aes(x = Index, y = ndvi_media, color = label)) +
  geom_line(linewidth = 1.2) +
  geom_ribbon(
    aes(ymin = ndvi_media - ndvi_sd, ymax = ndvi_media + ndvi_sd, fill = label),
    alpha = 0.2, color = NA
  ) +
  labs(
    title    = "Comparação da Distribuição Temporal do NDVI entre Classes",
    subtitle = "Média ± Desvio Padrão por data de aquisição",
    x = "Data", y = "NDVI", color = "Classe", fill = "Classe"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14))



# ==================================================================
# 7. DIAGNÓSTICO — DENDROGRAMA NAS AMOSTRAS BRUTAS
# ------------------------------------------------------------------
# O agrupamento hierárquico organiza as amostras em uma árvore
# (dendrograma) com base na similaridade das séries temporais.
# Usamos DTW (Dynamic Time Warping), que compara a FORMA das curvas,
# e o método de ligação Ward.D2, que minimiza a variância intra-grupo.
#
# >> PAPEL PEDAGÓGICO <<
# Rodar o dendrograma ANTES da limpeza serve para DIAGNOSTICAR:
#   - amostras mal rotuladas aparecem no cluster "errado";
#   - a tabela de frequência revela mistura entre classes;
#   - o aluno VÊ o problema antes de propor a solução.
# ==================================================================
clusters_brutos <- sits_cluster_dendro(
  samples     = amostras_sits,
  bands       = c("NDVI", "EVI"),
  dist_method = "dtw_basic",
  linkage     = "ward.D2"
)



cat("\n--- Frequência de clusters nas amostras BRUTAS ---\n")
sits_cluster_frequency(clusters_brutos)

# ==================================================================
# 8. LIMPEZA — SOM (MAPA AUTO-ORGANIZÁVEL DE KOHONEN)
# ------------------------------------------------------------------
# O SOM agrupa amostras com comportamento espectro-temporal semelhante
# em neurônios. Depois avaliamos a qualidade da mistura das classes
# nos neurônios e removemos as amostras inconsistentes.
#
# ATENÇÃO: o grid deve ter MENOS neurônios que o número de amostras.
# Como temos 42 amostras, usamos 5x5 = 25 neurônios (dentro do
# intervalo recomendado de 3 a 8 por dimensão).
# Regra de Kohonen: total de neurônios ≈ 5 vezes a raiz quadrada 
# do numero de amostras
# ==================================================================
n_amostras <- nrow(amostras_sits)
grid_dim   <- min(5, floor(sqrt(n_amostras)) - 1)  # ex.: 5 para 42 amostras

som_mapa <- sits_som_map(
  data      = amostras_sits,
  grid_xdim = grid_dim,
  grid_ydim = grid_dim,
  alpha     = 1.0,
  distance  = "euclidean"
)
plot(som_mapa)

# Avaliação da qualidade e mistura das classes nos neurônios
som_aval <- sits_som_evaluate_cluster(som_mapa)
plot(som_aval)

# Limpeza das amostras (remoção de ruído via SOM)
# Em versões recentes do sits, o argumento "prior_threshold" foi removido.
# O controle agora é feito pelo argumento "keep":
#   "clean"   -> boas amostras
#   "analyze" -> casos-limite
#   "remove"  -> prováveis outliers
amostras_limpas <- sits_som_clean_samples(
  som_map = som_mapa,
  keep    = "clean"
)

cat("\n--- Comparação antes/depois da limpeza ---\n")
cat("Amostras originais:", nrow(amostras_sits), "\n")
cat("Amostras refinadas:", nrow(amostras_limpas), "\n")

table(amostras_sits$label)
table(amostras_limpas$label)

# ==================================================================
# 9. VALIDAÇÃO — DENDROGRAMA NAS AMOSTRAS LIMPAS
# ------------------------------------------------------------------
# >> PAPEL PEDAGÓGICO <<
# Rodar o dendrograma DEPOIS da limpeza serve para VALIDAR:
#   - a árvore deve ficar mais coerente, com classes melhor separadas;
#   - a tabela de frequência deve mostrar menos mistura entre classes;
#   - comparar com o dendrograma bruto evidencia o efeito da limpeza.
# ==================================================================
clusters_limpos <- sits_cluster_dendro(
  samples     = amostras_limpas,
  bands       = c("NDVI", "EVI"),
  dist_method = "dtw_basic",
  linkage     = "ward.D2"
)


cat("\n--- Frequência de clusters nas amostras LIMPAS ---\n")
sits_cluster_frequency(clusters_limpos)

# ------------------------------------------------------------------
# 9.1 (Opcional) Comparação com o conjunto cerrado_2classes
#     Mostra como o algoritmo lida com volume maior de amostras.
#     Útil para discussão sobre escalabilidade e legibilidade do
#     dendrograma quando há muitas amostras.
# ------------------------------------------------------------------
clusters_cerrado <- sits_cluster_dendro(
  samples     = cerrado_2classes,
  bands       = c("NDVI", "EVI"),
  dist_method = "dtw_basic",
  linkage     = "ward.D2"
)

sits_cluster_frequency(clusters_cerrado)

# ------------------------------------------------------------------
# 10. EXPORTAÇÃO DAS AMOSTRAS LIMPAS (para a Aula 4)
# ------------------------------------------------------------------
saveRDS(
  amostras_limpas,
  file = file.path(diretorio_saida, "amostras_limpas_matopiba.rds")
)

###==================================================================
# OBSERVAÇÃO SOBRE sits_from_hf
# ------------------------------------------------------------------
# A função sits_from_hf NÃO existe na versão 1.5.4 do sits (CRAN).
# O conjunto cerrado_2classes já está disponível diretamente após
# carregar o pacote sits (veja `?cerrado_2classes`).
#
# 
###==================================================================