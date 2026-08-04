library(dplyr)
library(stringr)
library(readr)
library(purrr)
library(openxlsx)

# Cargar y limpiar datos
ruta_csv <- "Adolescentes.csv"
Adolescentes <- read_csv(ruta_csv, locale = locale(encoding = "UTF-8"), show_col_types = FALSE)
names(Adolescentes) <- trimws(names(Adolescentes))
names(Adolescentes) <- gsub("[[:space:]]+", " ", names(Adolescentes))

# Recuento inicial
registro_inicial <- nrow(Adolescentes)

# Variables clave
vars_llave_madre <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO",
  "Numero gestas previas", "Numero de Partos previos",
  "Cesáreas previas CODIGO", "Embarazo planeado CODIGO",
  "ANTICONCEPTIVO CODIGO", "Número Consultas prenatales",
  "TIPO DE PARTO", "CESAREA"
)

asignar_cluster_gestacional <- function(eg_vals, umbral_semanas = 3) {
  n <- length(eg_vals)
  if (n == 0) return(integer(0))
  if (n == 1) return(1L)
  if (all(is.na(eg_vals))) return(rep(1L, n))
  ord <- order(eg_vals, na.last = TRUE)
  eg_sorted <- eg_vals[ord]
  cluster_sorted <- integer(n)
  cluster_sorted[1] <- 1L
  cl <- 1L
  for (i in 2:n) {
    if (!is.na(eg_sorted[i]) && !is.na(eg_sorted[i - 1]) && (eg_sorted[i] - eg_sorted[i - 1]) >= umbral_semanas) {
      cl <- cl + 1L
    }
    cluster_sorted[i] <- cl
  }
  cluster_out <- integer(n)
  cluster_out[ord] <- cluster_sorted
  cluster_out
}

# Eliminación de duplicados exactos y deduplicación de embarazos múltiples
Adolescentes_limpia <- Adolescentes %>% distinct()
duplicados_exactos <- registro_inicial - nrow(Adolescentes_limpia)

multiples_antes <- Adolescentes_limpia %>% filter(`Embarazo múltiple CODIGO` == 1)

multiples_dedup <- multiples_antes %>%
  group_by(across(all_of(vars_llave_madre))) %>%
  mutate(
    subgrupo_gestacional = asignar_cluster_gestacional(`Edad gestaciol RN`, umbral_semanas = 3)
  ) %>%
  ungroup() %>%
  distinct(
    across(all_of(c(vars_llave_madre, "subgrupo_gestacional"))),
    .keep_all = TRUE
  )

registros_consolidados <- nrow(multiples_antes) - nrow(multiples_dedup)

Adolescentes_por_madre <- bind_rows(
  Adolescentes_limpia %>% filter(`Embarazo múltiple CODIGO` != 1 | is.na(`Embarazo múltiple CODIGO`)),
  multiples_dedup
) %>%
  filter(
    !is.na(`Edad materna`),
    `Edad materna` >= 10,
    `Edad materna` <= 19
  )

# Muestra materna final
n_final_madre_parto <- nrow(Adolescentes_por_madre)

# Conteos por grupo etario
conteo_etario_final <- Adolescentes_por_madre %>%
  mutate(
    grupo_edad = if_else(`Edad materna` < 15, "10-14", "15-19")
  ) %>%
  count(grupo_edad)

# Conteo de embarazos múltiples en la muestra final
eventos_multiples <- sum(Adolescentes_por_madre$`Embarazo múltiple CODIGO` == 1, na.rm = TRUE)

# Variables neonatales y denominadores
variables_neonatales <- c(
  "PREMATURO CODIGO",
  "CODIGO Apgar 1 minuto <7",
  "CODIGO Apgar 5to. < 7",
  "RCIU",
  "MACROSÓMICO",
  "BEBE Ictericia",
  "RN vivo CODIGO",
  "Lactancia exclusiva SI NO"
)

# Subconjunto neonatal excluyendo múltiples
Adolescentes_neonatal <- Adolescentes_por_madre %>%
  filter(`Embarazo múltiple CODIGO` != 1 | is.na(`Embarazo múltiple CODIGO`)) %>%
  mutate(grupo_edad = if_else(`Edad materna` < 15, "10-14", "15-19"))

conteo_neonatal_etario <- Adolescentes_neonatal %>% count(grupo_edad)

# Denominadores por variable neonatal en la muestra neonatal única
denominadores_neonatales <- map_dfr(variables_neonatales, function(var) {
  tibble(
    variable = var,
    denominador = sum(!is.na(Adolescentes_neonatal[[var]]))
  )
})

# Guardado de auditoría
reconciliation <- tibble(
  elemento = c(
    "registros_iniciales",
    "duplicados_exactos",
    "registros_consolidados",
    "eventos_finales",
    "eventos_multiples"
  ),
  valor = c(
    registro_inicial,
    duplicados_exactos,
    registros_consolidados,
    n_final_madre_parto,
    eventos_multiples
  )
)

write_csv(reconciliation, "output/reconciliation/reconciliation_summary.csv")
write_csv(conteo_etario_final, "output/reconciliation/conteo_etario_final.csv")
write_csv(conteo_neonatal_etario, "output/reconciliation/conteo_neonatal_etario.csv")
write_csv(denominadores_neonatales, "output/reconciliation/denominadores_neonatales.csv")

saveRDS(list(
  reconciliation = reconciliation,
  conteo_etario_final = conteo_etario_final,
  conteo_neonatal_etario = conteo_neonatal_etario,
  denominadores_neonatales = denominadores_neonatales
), "output/reconciliation/auditoria_gestaciones_multiples.rds")

cat("Auditoría completada. Archivos guardados en output/reconciliation/\n")
