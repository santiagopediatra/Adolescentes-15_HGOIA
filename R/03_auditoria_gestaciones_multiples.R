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

agregar_grupo_edad <- function(datos) {
  datos %>%
    filter(!is.na(`Edad materna`), between(`Edad materna`, 10, 19)) %>%
    mutate(grupo_edad = if_else(`Edad materna` < 15, "10-14", "15-19"))
}

conteos_por_grupo <- function(datos) {
  conteos <- agregar_grupo_edad(datos) %>% count(grupo_edad)
  c(
    total = sum(conteos$n),
    `10-14` = sum(conteos$n[conteos$grupo_edad == "10-14"]),
    `15-19` = sum(conteos$n[conteos$grupo_edad == "15-19"])
  )
}

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
  "Edad gestaciol RN",
  "Peso al nacer GRAMOS",
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

# Reconciliación completa calculada en cada etapa real del algoritmo.
conteo_inicial <- conteos_por_grupo(Adolescentes)
conteo_post_duplicados <- conteos_por_grupo(Adolescentes_limpia)
conteo_duplicados <- conteo_inicial - conteo_post_duplicados
conteo_multiples_antes <- conteos_por_grupo(multiples_antes)
conteo_multiples_dedup <- conteos_por_grupo(multiples_dedup)
conteo_consolidados <- conteo_multiples_antes - conteo_multiples_dedup
conteo_final <- conteos_por_grupo(Adolescentes_por_madre)
conteo_neonatal <- conteos_por_grupo(Adolescentes_neonatal)

reconciliacion_final_por_grupo <- bind_rows(
  tibble(etapa = "Registros iniciales", !!!as.list(conteo_inicial)),
  tibble(etapa = "Duplicados exactos eliminados", !!!as.list(conteo_duplicados)),
  tibble(etapa = "Registros después de duplicados exactos", !!!as.list(conteo_post_duplicados)),
  tibble(etapa = "Registros consolidados mediante linkage", !!!as.list(conteo_consolidados)),
  tibble(etapa = "Eventos obstétricos maternos finales", !!!as.list(conteo_final)),
  tibble(etapa = "Nacimientos únicos finales", !!!as.list(conteo_neonatal))
) %>%
  rename(`10–14` = `10-14`, `15–19` = `15-19`) %>%
  mutate(
    archivo_denominadores_neonatales = if_else(
      etapa == "Nacimientos únicos finales",
      "output/reconciliation/denominadores_neonatales_por_grupo.csv",
      NA_character_
    )
  )

# Denominadores por variable neonatal en la muestra neonatal única
denominadores_neonatales <- map_dfr(variables_neonatales, function(var) {
  tibble(
    variable = var,
    denominador = sum(!is.na(Adolescentes_neonatal[[var]]))
  )
})

denominadores_neonatales_por_grupo <- map_dfr(variables_neonatales, function(var) {
  Adolescentes_neonatal %>%
    group_by(grupo_edad) %>%
    summarise(variable = var, denominador = sum(!is.na(.data[[var]])), .groups = "drop")
})

# Sensibilidad del linkage a umbrales alternativos plausibles. El umbral
# principal de 3 semanas tolera pequeñas diferencias de medición o digitación
# entre registros de hermanos, pero separa discrepancias incompatibles con una
# misma gestación. Se comparan 2 y 4 semanas sin modificar el análisis principal.
sensibilidad_linkage <- map_dfr(c(2L, 3L, 4L), function(umbral) {
  multiples_umbral <- multiples_antes %>%
    group_by(across(all_of(vars_llave_madre))) %>%
    mutate(subgrupo_gestacional = asignar_cluster_gestacional(
      `Edad gestaciol RN`, umbral_semanas = umbral
    )) %>%
    ungroup() %>%
    distinct(across(all_of(c(vars_llave_madre, "subgrupo_gestacional"))), .keep_all = TRUE)
  tibble(
    umbral_semanas = umbral,
    registros_consolidados = nrow(multiples_antes) - nrow(multiples_umbral),
    eventos_finales = nrow(Adolescentes_limpia) - (nrow(multiples_antes) - nrow(multiples_umbral)),
    eventos_multiples_retenidos = nrow(multiples_umbral)
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
write_csv(denominadores_neonatales_por_grupo, "output/reconciliation/denominadores_neonatales_por_grupo.csv")
write_csv(sensibilidad_linkage, "output/reconciliation/sensibilidad_linkage.csv")
write_csv(
  reconciliacion_final_por_grupo,
  "output/reconciliation/reconciliacion_final_por_grupo.csv"
)

saveRDS(list(
  reconciliation = reconciliation,
  conteo_etario_final = conteo_etario_final,
  conteo_neonatal_etario = conteo_neonatal_etario,
  denominadores_neonatales = denominadores_neonatales,
  denominadores_neonatales_por_grupo = denominadores_neonatales_por_grupo,
  sensibilidad_linkage = sensibilidad_linkage
), "output/reconciliation/auditoria_gestaciones_multiples.rds")

cat("Auditoría completada. Archivos guardados en output/reconciliation/\n")
