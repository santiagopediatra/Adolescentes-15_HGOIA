# Configuración central de reproducibilidad.
# No reemplaza las semillas explícitas históricas de cada modelo.

SEED_ANALISIS <- 1234L
SEED_CONSULTAS_PRENATALES <- 1707L
SEED_DIAGNOSTICOS_PRIORS <- 1808L
SEED_HETEROGENEIDAD_TEMPORAL <- 1909L

SEMILLAS_ANALISIS <- c(
  principal = SEED_ANALISIS,
  consultas_prenatales = SEED_CONSULTAS_PRENATALES,
  diagnosticos_priors = SEED_DIAGNOSTICOS_PRIORS,
  heterogeneidad_temporal = SEED_HETEROGENEIDAD_TEMPORAL
)

set.seed(SEED_ANALISIS)

RUTA_BASE_FUENTE <- "Adolescentes.csv"
RUTA_RESULTADOS_RDS <- "resultados_RBSMI_DEFINITIVO_CORREGIDO.rds"
RUTA_RESULTADOS_XLSX <- "resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx"
RUTA_OUTPUT <- "output"
