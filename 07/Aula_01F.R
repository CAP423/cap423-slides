# ==============================================================================
# CURSO PRATICO SITS - AULA 1: BDC-Lab, BDC, SITS e Construcao do Cubo
# Area de Estudo: Luis Eduardo Magalhaes - BA (LEM)
# Duracao estimada: 1h15m
# Referencia de tiles Sentinel-2: https://dpird-dma.github.io/Sentinel-2-grid-explorer/
# Livro SITS:  https://e-sensing.github.io/sitsbook/setup.html
# Caracteristicas SENTINEL - https://data.inpe.br/dados/sentinel-2/
# Versao revisada - correcoes indicadas nos comentarios
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. AMBIENTE E BIBLIOTECAS
# ------------------------------------------------------------------------------
library(sits)
library(sf)
options(timeout = 600)

cat("SITS carregado com sucesso! Versao:", as.character(packageVersion("sits")), "\n")


parallel::detectCores()
n_cores <- 30

# ------------------------------------------------------------------------------
# 2. EXPLORACAO DAS COLECOES DO BDC
# ------------------------------------------------------------------------------
sits_list_collections(source = "BDC")

# ------------------------------------------------------------------------------
# 3. AREA DE ESTUDO (ROI) E PERIODO TEMPORAL
# ------------------------------------------------------------------------------
# Luis Eduardo Magalhaes - BA (~5km x 5km)
roi_lem <- c(
  lon_min = -45.85,
  lat_min = -12.12,
  lon_max = -45.80,
  lat_max = -12.07
)

# Periodo temporal (ano-safra)
# ATENCAO: se a data final ainda nao tiver ocorrido, a timeline do cubo
# ficara incompleta perto do fim do periodo (nao havera cenas para o futuro).
start_date <- "2025-10-01"
end_date   <- "2026-10-01"

# ------------------------------------------------------------------------------
# 4. CRIACAO DO CUBO DE DADOS IRREGULAR - OBS. O cubo SENTINEL-2-16D já vem
# regularizado.
# ------------------------------------------------------------------------------
cube_s2_irregular <- sits_cube(
  source     = "BDC",
  collection = "SENTINEL-2-16D",
  roi        = roi_lem,
  start_date = start_date,
  end_date   = end_date,
  bands      = c("NDVI", "B02", "B03", "B04", "B08", "B11", "B12", "CLOUD")
)

print(cube_s2_irregular)
summary(cube_s2_irregular)

# ------------------------------------------------------------------------------
# 5. REGULARIZACAO DO CUBO DE DADOS. O cubo ja vem regularizado aqui usamos apenas
# de forma didatica. 
# Lembre-se de ajustar a sua pasta de saida
# ------------------------------------------------------------------------------
sits_timeline(cube_s2_irregular)

output_dir <- "Alarcon/Curso_SITS"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

cube_s2_regular <- sits_regularize(
  cube       = cube_s2_irregular,
  period     = "P16D",
  res        = 10,
  roi        = roi_lem,
  output_dir = output_dir,
  multicores = n_cores    
)

print(cube_s2_regular)

#Uma construcao alternativa do cubo regular é:

#cube_s2_regular <- sits_regularize(
#  cube       = cube_s2_irregular,
#  period     = "P16D",
#  res        = 10,
#  roi        = roi_lem,
#  multicores = 4,                   
#  memsize    = 8,
#  multicores = n_cores    
#)

# A timeline e armazenada e usada para escolher as datas
# dos plots abaixo, em vez de "chutar" datas fixas que podem nao existir
# no cubo regularizado.
timeline_regular <- sits_timeline(cube_s2_regular)
print(timeline_regular)

data_inicio <- timeline_regular[1]
data_meio   <- timeline_regular[ceiling(length(timeline_regular) / 2)]
data_fim    <- timeline_regular[length(timeline_regular)]

# ------------------------------------------------------------------------------
# 6. VISUALIZACAO E EXTRACAO DE SERIES TEMPORAIS
# ------------------------------------------------------------------------------

# 6.1 Composicao cor verdadeira (RGB: B04, B03, B02)
plot(cube_s2_regular, red = "B04", green = "B03", blue = "B02", dates = data_inicio)

# 6.2 Falso colorido / infravermelho (RGB: B08, B04, B03)
plot(cube_s2_regular, red = "B08", green = "B04", blue = "B03", dates = data_fim)

# 6.2.1. teste cores diferentes veja o resultado
sits_bands(cube_s2_regular)

plot(cube_s2_regular, red = "B11", green = "B12", blue = "B02", dates = data_fim)


# 6.3 Comparacao temporal ao longo da safra
plot(
  cube_s2_regular,
  red   = "B08",
  green = "B04",
  blue  = "B03",
  dates = c(data_inicio, data_meio, data_fim)
)

# 6.3. Comparacao temporal ao longo da safra. Mude as datas
plot(
  cube_s2_regular,
  red   = "B04",
  green = "B03",
  blue  = "B02",
  dates = "2026-04-26"
)



# 6.4 Visualizacao do NDVI
plot(
  cube_s2_regular,
  band            = "NDVI",
  dates           = data_inicio,
  palette         = "RdYlGn",
  legend_position = "right"
)

# 6.5 Extracao e plotagem de serie temporal em pivo central
ponto_pivo <- data.frame(
  longitude = -45.825,
  latitude  = -12.095,
  label     = "Pivo Agricola"
)

serie_pivo <- sits_get_data(
  cube    = cube_s2_regular,
  samples = ponto_pivo
)

plot(serie_pivo)

# ------------------------------------------------------------------------------
# 7. CONTEUDO EXTRA - outros provedores e colecoes (exemplos independentes)
# ------------------------------------------------------------------------------
# NOTA: os exemplos abaixo sao independentes do pipeline principal (secoes 1-6)
# e nao dependem de cube_s2_regular. Rode-os separadamente se quiser explorar.

library(sitsdata)

# Cubo Sentinel-2, provedor AWS (uso correto: AWS hospeda Sentinel-2-L2A,

sits_list_collections(source = "AWS")


s2_23MMU_cube <- sits_cube(
  source     = "AWS",
  collection = "SENTINEL-2-L2A",
  tiles      = "23MMU",
  bands      = c("B02", "B8A", "B11", "CLOUD"),
  start_date = "2018-07-12",
  end_date   = "2019-07-28"
)

#Lista as datas disponiveis no cubo
summary(s2_23MMU_cube)


plot(
  s2_23MMU_cube,
  red   = "B11",
  blue  = "B02",
  green = "B8A",
  date  = "2018-10-05"
)

# Cubo Sentinel-2, Microsoft Planetary Computer (MPC)
# ATENCAO: intervalo de ~7 anos sem filtro de nuvem pode ser pesado para
# uma aula de 1h15 - considere reduzir o periodo se o tempo for curto.
sits_list_collections(source = "MPC")

s2_24LWL_cube_MPC <- sits_cube(
  source     = "MPC",
  collection = "SENTINEL-2-L2A",
  tiles      = "24LWL",
  bands      = c("B02", "B8A", "B11", "CLOUD"),
  start_date = "2019-01-01",
  end_date   = "2026-07-28"
)

print(s2_24LWL_cube_MPC)
summary(s2_24LWL_cube_MPC)

plot(
  s2_24LWL_cube_MPC,
  red   = "B11",
  blue  = "B02",
  green = "B8A",
  date  = "2025-08-02" 
)

# Cubo Sentinel-1 RTC (MPC)
cube_s1_rtc <- sits_cube(
  source     = "MPC",
  collection = "SENTINEL-1-RTC",
  bands      = c("VV", "VH"),
  orbit      = "descending",
  tiles      = "24LVN",
  start_date = "2021-08-01",
  end_date   = "2021-09-30"
)

plot(cube_s1_rtc, band = "VV", palette = "Greys")

# Modelo digital de elevacao Copernicus DEM 30m (MPC)
cube_dem_30 <- sits_cube(
  source     = "MPC",
  collection = "COP-DEM-GLO-30",
  tiles      = "24LVN",
  bands      = "ELEVATION"   
)

