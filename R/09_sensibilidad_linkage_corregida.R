#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

archivo <- "Adolescentes.csv"
salida <- "output/reconciliation/sensibilidad_linkage_CORREGIDA.csv"
archivo_log <- "output/logs/AUDITORIA_EJECUTADO.txt"
if (!file.exists(archivo)) stop("Falta ", archivo)
dir.create(dirname(salida), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(archivo_log), recursive = TRUE, showWarnings = FALSE)

datos <- read.csv(
  archivo, fileEncoding = "UTF-8", check.names = FALSE,
  stringsAsFactors = FALSE
)
names(datos) <- trimws(names(datos))
names(datos) <- gsub("[[:space:]]+", " ", names(datos))
datos_sin_duplicados <- datos %>% distinct()

if (nrow(datos) != 7202L || nrow(datos_sin_duplicados) != 7187L) {
  stop("No se reprodujo la transición 7.202 → 7.187.")
}

llave <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO", "Numero gestas previas",
  "Numero de Partos previos", "Cesáreas previas CODIGO",
  "Embarazo planeado CODIGO", "ANTICONCEPTIVO CODIGO",
  "Número Consultas prenatales", "TIPO DE PARTO", "CESAREA"
)

cluster_umbral <- function(x, umbral) {
  n <- length(x)
  if (n == 0) return(integer())
  if (n == 1 || all(is.na(x))) return(rep(1L, n))
  orden <- order(x, na.last = TRUE)
  xs <- x[orden]
  cs <- integer(n)
  cs[1] <- 1L
  grupo <- 1L
  for (i in seq.int(2, n)) {
    if (!is.na(xs[i]) && !is.na(xs[i - 1]) &&
        xs[i] - xs[i - 1] >= umbral) grupo <- grupo + 1L
    cs[i] <- grupo
  }
  resultado <- integer(n)
  resultado[orden] <- cs
  resultado
}

construir <- function(tipo = c("sin_linkage", "exacta", "umbral"), umbral = NA) {
  tipo <- match.arg(tipo)
  if (tipo == "sin_linkage") {
    final <- datos_sin_duplicados
  } else {
    multiples <- datos_sin_duplicados %>%
      filter(`Embarazo múltiple CODIGO` == 1) %>%
      group_by(across(all_of(llave)))
    if (tipo == "exacta") {
      multiples <- multiples %>%
        mutate(.cluster = if_else(
          is.na(`Edad gestaciol RN`), "NA",
          as.character(`Edad gestaciol RN`)
        ))
    } else {
      multiples <- multiples %>%
        mutate(.cluster = cluster_umbral(`Edad gestaciol RN`, umbral))
    }
    multiples <- multiples %>%
      ungroup() %>%
      distinct(across(all_of(c(llave, ".cluster"))), .keep_all = TRUE) %>%
      select(-.cluster)
    final <- bind_rows(
      datos_sin_duplicados %>%
        filter(`Embarazo múltiple CODIGO` != 1 | is.na(`Embarazo múltiple CODIGO`)),
      multiples
    )
  }
  final %>%
    filter(!is.na(`Edad materna`), `Edad materna` >= 10, `Edad materna` <= 19)
}

resumir <- function(nombre, final) {
  eventos <- nrow(final)
  multiples <- sum(final$`Embarazo múltiple CODIGO` == 1, na.rm = TRUE)
  tibble(
    escenario = nombre,
    eventos_maternos_finales = eventos,
    registros_consolidados = nrow(datos_sin_duplicados) - eventos,
    embarazos_multiples = multiples,
    nacimientos_unicos = eventos - multiples
  )
}

resultados <- bind_rows(
  resumir("A_llave_exacta", construir("exacta")),
  resumir("B_llave_1_semana", construir("umbral", 1)),
  resumir("C_llave_2_semanas", construir("umbral", 2)),
  resumir("D_llave_3_semanas_PRINCIPAL", construir("umbral", 3))
)

principal <- resultados %>% filter(escenario == "D_llave_3_semanas_PRINCIPAL")
stopifnot(
  principal$eventos_maternos_finales == 7035L,
  principal$registros_consolidados == 152L,
  principal$embarazos_multiples == 245L,
  principal$nacimientos_unicos == 6790L
)

write_csv(resultados, salida)

lineas_escenarios <- apply(resultados, 1, function(x) {
  paste0(
    "- ", x[["escenario"]],
    ": eventos_maternos_finales=", x[["eventos_maternos_finales"]],
    "; registros_consolidados=", x[["registros_consolidados"]],
    "; embarazos_multiples=", x[["embarazos_multiples"]],
    "; nacimientos_unicos=", x[["nacimientos_unicos"]]
  )
})
lineas_log <- c(
  "AUDITORÍA DE SENSIBILIDAD DE LINKAGE — EJECUTADO",
  paste0("Timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "Escenarios verificados:",
  lineas_escenarios,
  "",
  "Archivos generados:",
  paste0("- ", normalizePath(salida, mustWork = TRUE)),
  paste0("- ", file.path(normalizePath(getwd()), archivo_log)),
  paste0("- ", normalizePath("resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx", mustWork = TRUE)),
  paste0("- ", normalizePath("resultados_RBSMI_DEFINITIVO_CORREGIDO.rds", mustWork = TRUE))
)
writeLines(lineas_log, archivo_log, useBytes = TRUE)

print(resultados, n = Inf)
cat("CSV guardado:", salida, "\n")
cat("LOG guardado:", archivo_log, "\n")
