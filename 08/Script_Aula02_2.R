# ==============================================================================
# AULA II PRÁTICA: Análise de Cubos de Dados, Amostras e Séries Temporais
# Prof. Dr. Alarcon Matos de Oliveira | INPE - DIOTG
#
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. CONFIGURAÇÃO DO AMBIENTE, PARÂMETROS E BIBLIOTECAS
# ------------------------------------------------------------------------------
install.packages("tidyverse")
install.packages(c("leaflet", "leaflet.extras"))
library(leaflet)
library(sits)
library(sf)
library(tidyverse)

# Autenticação no Brazil Data Cube (BDC)
# Insira seu token individual obtido na plataforma do BDC:
# Sys.setenv(BDC_ACCESS_KEY = "SEU_TOKEN_BDC_AQUI")

n_cores <- 30  # nº de núcleos para processamento paralelo (ajustar à máquina)

# ==============================================================================
# 1. EXPLORAÇÃO E DEFINIÇÃO DO CUBO DE DADOS
# ==============================================================================

# 1.1 Conexão ao Cubo Sentinel-2 do BDC (Composição de 16 dias)
# Região de estudo: Luís Eduardo Magalhães (LEM) / Oeste da Bahia (Matopiba)
# NDVI e EVI já estão disponíveis como bandas pré-calculadas nesta coleção do BDC
cubo_s2 <- sits_cube(
  source     = "BDC",
  collection = "SENTINEL-2-16D",
  bands      = c("B02", "B03", "B04", "B08", "B11", "NDVI", "EVI"),
  roi        = c(
    lon_min = -46.55,
    lat_min = -12.35,
    lon_max = -45.45,
    lat_max = -11.95
  ),
  start_date = "2019-09-30",
  end_date   = "2020-09-29"
)

# 1.2 Inspeção da estrutura do cubo de dados
print(cubo_s2)

# 1.3 Verificação das dimensões temporais (timeline)
sits_timeline(cubo_s2)

# 1.4 Verificação das bandas e atributos espectrais
sits_bands(cubo_s2)

# ==============================================================================
# 2. VISUALIZAÇÃO ESPACIAL E TEMPORAL
# ==============================================================================

# 2.1 Visualização em cor verdadeira (RGB: B04, B03, B02) - período seco/transição
plot(
  cubo_s2,
  red   = "B04",
  green = "B03",
  blue  = "B02",
  dates = "2019-09-30",
  title = "Sentinel-2 BDC - Cor Verdadeira (2019-09-30)"
)

# 2.2 Visualização em falso colorido/infravermelho (RGB: B08, B04, B03) - pico vegetativo
plot(
  cubo_s2,
  red   = "B08",
  green = "B04",
  blue  = "B03",
  dates = "2020-05-08",
  title = "Sentinel-2 BDC - Falso Colorido NIR (2020-05-08)"
)

# 2.3 Dinâmica temporal do NDVI ao longo do ano agrícola
plot(cubo_s2, band = "NDVI", dates = "2019-09-30", title = "NDVI - Transição Seca/Chuvosa (2019-09-30)")
plot(cubo_s2, band = "NDVI", dates = "2020-05-24", title = "NDVI - Pico Vegetativo (2020-05-24)")
plot(cubo_s2, band = "NDVI", dates = "2020-07-11", title = "NDVI - Início da Estação Seca (2020-07-11)")
plot(cubo_s2, band = "NDVI", dates = "2020-09-29", title = "NDVI - Final da Estação Seca (2020-09-29)")

# ==============================================================================
# 3. IMPORTAÇÃO E INSPEÇÃO DAS AMOSTRAS DE CAMPO
# ==============================================================================

# 3.1 Carregamento do conjunto de dados de amostragem (LEM - Cerrado)
# Nome padronizado como "amostras_brutas" para manter consistência com a Aula 3
samples_dir     <- system.file("data", package = "sitsdata")
amostras_brutas <- readRDS(file.path(samples_dir, "df_samples_cerrado_lem.rds"))

#Para usar as amostras adquiridas no seu trabalho vc pode usar
#samples <- st_read("Endereco/armazenamento/pontos_controle.gpkg")

# 3.2 Inspeção da estrutura e distribuição das classes de amostragem
head(amostras_brutas)
table(amostras_brutas$label)


# 3.3 Mapa com a geolocalização das amostras sobre imagem de satélite (Google)
# Converte as amostras para objeto espacial (sf), caso ainda não seja
pontos_sf <- sf::st_as_sf(
  amostras_brutas,
  coords = c("longitude", "latitude"),
  crs    = 4326,
  remove = FALSE
)

# Paleta de cores por classe
pal_classes <- leaflet::colorFactor(
  palette = "Set1",
  domain  = pontos_sf$label
)

# Mapa interativo: base de satélite do Google + rótulos (híbrido) e ponto por classe
mapa_amostras <- leaflet::leaflet(pontos_sf) |>
  leaflet::addTiles(
    urlTemplate = "https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
    attribution = "Imagery © Google",
    group       = "Google Satélite"
  ) |>
  leaflet::addTiles(
    urlTemplate = "https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}",
    attribution = "Imagery © Google",
    group       = "Google Híbrido"
  ) |>
  leaflet::addTiles(group = "OpenStreetMap") |>
  leaflet::addCircleMarkers(
    radius      = 5,
    color       = "white",
    weight      = 1,
    fillColor   = ~pal_classes(label),
    fillOpacity = 0.9,
    popup       = ~paste0("<b>Classe:</b> ", label,
                          "<br><b>Lon:</b> ", round(longitude, 5),
                          "<br><b>Lat:</b> ", round(latitude, 5))
  ) |>
  leaflet::addLegend(
    position = "bottomright",
    pal      = pal_classes,
    values   = ~label,
    title    = "Classe"
  ) |>
  leaflet::addLayersControl(
    baseGroups = c("Google Satélite", "Google Híbrido", "OpenStreetMap"),
    options    = leaflet::layersControlOptions(collapsed = FALSE)
  ) |>
  leaflet::addScaleBar(position = "bottomleft")

mapa_amostras  # exibe no painel Viewer do RStudio

# ==============================================================================
# 4. EXTRAÇÃO DAS SÉRIES TEMPORAIS DOS PONTOS DE AMOSTRA
# ==============================================================================

# 4.1 Extração dos dados espectrais do cubo para os pontos de amostragem
amostras_sits <- sits_get_data(
  cube       = cubo_s2,
  samples    = amostras_brutas,
  start_date = "2019-09-30",
  end_date   = "2020-09-29",
  multicores = n_cores
)

# 4.2 Inspeção do objeto tibble retornado pelo sits
print(amostras_sits)

# Exemplo de inspeção da série temporal do primeiro ponto de amostra
# se mudar o numero interno da para visualizar novos pontos
amostras_sits$time_series[[1]]

# ==============================================================================
# 5. ANÁLISE E VISUALIZAÇÃO DAS ASSINATURAS TEMPORAIS
# ==============================================================================

# 5.1 Perfis temporais de NDVI individuais por classe (sits nativo)
amostras_sits |>
  dplyr::filter(label == "Pasture") |>
  plot(band = "NDVI", title = "Padrão Temporal: Pastagem")

amostras_sits |>
  dplyr::filter(label == "Cerrado") |>
  plot(band = "NDVI", title = "Padrão Temporal: Cerrado")

# 5.2 Comparação geral de assinaturas temporais (sits nativo)
plot(
  amostras_sits,
  band  = "NDVI",
  title = "Assinaturas Temporais Médias: Cerrado × Pastagem"
)

# 5.3 Customização avançada com ggplot2
# Extrai a série temporal de cada amostra com um identificador único (id_amostra)
dados_ndvi <- purrr::map2_dfr(
  amostras_sits$time_series,
  seq_len(nrow(amostras_sits)),
  function(ts, id) {
    ts |>
      dplyr::select(Index, NDVI) |>
      dplyr::mutate(
        id_amostra = id,
        label      = amostras_sits$label[id]
      )
  }
)

# Gráfico comparativo com trajetórias individuais (group = id_amostra) e perfil médio
ggplot(dados_ndvi, aes(x = Index, y = NDVI, color = label)) +
  # Linhas individuais opacas para cada ponto de amostra
  geom_line(aes(group = id_amostra), alpha = 0.15) +
  # Linha média mais espessa para destacar o perfil da classe
  stat_summary(
    aes(group = label),
    fun      = mean,
    geom     = "line",
    linewidth = 1.3
  ) +
  labs(
    title    = "Assinaturas Temporais de NDVI: Cerrado × Pastagem",
    subtitle = "Trajetórias individuais (opacas) e média da classe (sólida)",
    x = "Data",
    y = "NDVI",
    color = "Classe"
  ) +
  scale_color_manual(values = c("Cerrado" = "#228B22", "Pasture" = "#E69F00")) +
  theme_minimal() +
  theme(
    plot.title      = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  )

# 5.4 Padrões temporais médios (smooth/patterns) a partir das amostras
# Requer o pacote "mgcv" instalado (usado internamente por sits_patterns)
samples_patterns <- sits_patterns(amostras_sits)

# Visualização dos padrões espectrais por classe gerados pelo GAM/sits
plot(samples_patterns)

