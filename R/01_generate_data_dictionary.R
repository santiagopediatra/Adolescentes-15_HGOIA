#!/usr/bin/env Rscript

# Genera un borrador descriptivo sin modificar la base fuente.
source(file.path("R", "00_config.R"))
if (!file.exists(RUTA_BASE_FUENTE)) stop("Falta ", RUTA_BASE_FUENTE)

datos <- read.csv(
  RUTA_BASE_FUENTE, fileEncoding = "UTF-8", check.names = FALSE,
  stringsAsFactors = FALSE
)
names(datos) <- gsub("[[:space:]]+", " ", trimws(names(datos)))

tipo_simple <- function(x) {
  if (is.integer(x)) return("entero")
  if (is.numeric(x)) return("numérico")
  if (is.logical(x)) return("lógico")
  "texto/categórico"
}

valores_breves <- function(x) {
  z <- unique(x[!is.na(x)])
  if (length(z) == 0) return("sin valores no faltantes")
  if (is.numeric(x)) {
    return(paste0("rango observado: ", min(x, na.rm = TRUE), "–", max(x, na.rm = TRUE)))
  }
  if (length(z) <= 10 && all(nchar(z) <= 40)) return(paste(sort(z), collapse = " | "))
  "REVISION_MANUAL: categorías o texto libre no enumerados"
}

unidad_conocida <- c(
  "Edad materna" = "años",
  "Años estudios mayor nivel" = "años",
  "Número Consultas prenatales" = "consultas",
  "Edad gestaciol RN" = "semanas",
  "Edad gestaciol RN - días" = "días",
  "Peso al nacer GRAMOS" = "gramos"
)

diccionario <- data.frame(
  variable = names(datos),
  etiqueta = names(datos),
  tipo = vapply(datos, tipo_simple, character(1)),
  `valores/categorías` = vapply(datos, valores_breves, character(1)),
  unidad = unname(ifelse(names(datos) %in% names(unidad_conocida), unidad_conocida[names(datos)], "REVISION_MANUAL")),
  origen = "Base SIP disponible: Adolescentes.csv",
  transformación = "Ninguna en la base fuente; limpieza de espacios solo en encabezados",
  notas = "REVISION_MANUAL: confirmar etiqueta, codificación, unidad y valores faltantes con metadatos institucionales",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

dir.create("data", recursive = TRUE, showWarnings = FALSE)
write.csv(
  diccionario, file.path("data", "DICCIONARIO_DATOS.csv"),
  row.names = FALSE, fileEncoding = "UTF-8", na = ""
)

cat("Diccionario borrador generado con", nrow(diccionario), "variables.\n")
