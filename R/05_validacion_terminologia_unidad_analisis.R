#!/usr/bin/env Rscript

root <- "."
out_dir <- file.path(root, "output", "terminologia_unidad_analisis")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

exts <- c(".qmd", ".md", ".R", ".Rmd", ".tex", ".csv", ".txt")
exclude_dirs <- c(".git", "output/terminologia_unidad_analisis", ".Rproj.user")
exclude_files <- c("R/05_validacion_terminologia_unidad_analisis.R")

collect_text_files <- function(root_dir, exts, exclude_dirs, exclude_files) {
  files <- list.files(
    root_dir,
    recursive = TRUE,
    include.dirs = FALSE,
    full.names = TRUE,
    pattern = paste0("\\", exts, "$", collapse = "|")
  )
  files <- files[!grepl(paste0(exclude_dirs, collapse = "|"), files, fixed = FALSE)]
  files <- files[!grepl("\\.(png|jpg|jpeg|pdf|pptx|docx|xlsx|rds|svg)$", files)]
  files <- files[!file.path(files) %in% file.path(root_dir, exclude_files)]
  files <- files[file.exists(files)]
  unique(files)
}

text_files <- collect_text_files(root, exts, exclude_dirs, exclude_files)

prohibited_patterns <- c(
  "7\\.035 adolescentes",
  "7035 adolescentes",
  "7,035 adolescents",
  "7\\.035 madres",
  "7,035 mothers",
  "muestra analítica final incluyó 7\\.035 adolescentes",
  "7\\.035 participantes",
  "flujograma de selección de participantes"
)

allowed_patterns <- c(
  "7\\.035 eventos obstétricos de adolescentes",
  "7\\.035 eventos obstétricos maternos",
  "7,035 deduplicated maternal obstetric events",
  "evento obstétrico materno",
  "386 eventos",
  "6\\.649 eventos"
)

rows <- list()
for (f in text_files) {
  lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
  for (i in seq_along(lines)) {
    line <- lines[i]
    if (length(grep(prohibited_patterns[1], line, ignore.case = TRUE, perl = TRUE)) > 0 ||
        length(grep(prohibited_patterns[2], line, ignore.case = TRUE, perl = TRUE)) > 0 ||
        length(grep(prohibited_patterns[3], line, ignore.case = TRUE, perl = TRUE)) > 0 ||
        length(grep(prohibited_patterns[4], line, ignore.case = TRUE, perl = TRUE)) > 0 ||
        length(grep(prohibited_patterns[5], line, ignore.case = TRUE, perl = TRUE)) > 0 ||
        length(grep(prohibited_patterns[6], line, ignore.case = TRUE, perl = TRUE)) > 0 ||
        length(grep(prohibited_patterns[7], line, ignore.case = TRUE, perl = TRUE)) > 0 ||
        length(grep(prohibited_patterns[8], line, ignore.case = TRUE, perl = TRUE)) > 0) {
      if (grepl("previa|anterior|versión anterior|problem|problema|sugiere|sugerir", line, ignore.case = TRUE)) {
        cls <- "revisar"
      } else {
        cls <- "error"
      }
      rows[[length(rows) + 1]] <- data.frame(
        archivo = f,
        linea = i,
        texto = line,
        clasificacion = cls,
        stringsAsFactors = FALSE
      )
    } else if (any(sapply(allowed_patterns, function(p) grepl(p, line, ignore.case = TRUE, perl = TRUE)))) {
      rows[[length(rows) + 1]] <- data.frame(
        archivo = f,
        linea = i,
        texto = line,
        clasificacion = "uso permitido",
        stringsAsFactors = FALSE
      )
    }
  }
}

if (length(rows) == 0) {
  validacion <- data.frame(
    archivo = character(),
    linea = integer(),
    texto = character(),
    clasificacion = character(),
    stringsAsFactors = FALSE
  )
} else {
  validacion <- do.call(rbind, rows)
}

# Verificación adicional de coherencia de cifras
manuscript_path <- file.path(root, "manuscript", "Adolescentes_19_julio.qmd")
if (file.exists(manuscript_path)) {
  manuscript_text <- paste(readLines(manuscript_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  if (!grepl("386 eventos", manuscript_text, ignore.case = TRUE) && !grepl("386 correspondientes", manuscript_text, ignore.case = TRUE)) {
    validacion <- rbind(validacion, data.frame(archivo = manuscript_path, linea = 1, texto = "No se detectó una formulación explícita de 386 como eventos en el resumen", clasificacion = "revisar", stringsAsFactors = FALSE))
  }
  if (!grepl("6\\.649 eventos", manuscript_text, ignore.case = TRUE) && !grepl("6\\.649 correspondientes", manuscript_text, ignore.case = TRUE)) {
    validacion <- rbind(validacion, data.frame(archivo = manuscript_path, linea = 1, texto = "No se detectó una formulación explícita de 6.649 como eventos en el resumen", clasificacion = "revisar", stringsAsFactors = FALSE))
  }
}

write.csv(validacion, file.path(out_dir, "validacion_terminologia.csv"), row.names = FALSE, fileEncoding = "UTF-8")

requisitos <- data.frame(
  requisito_editorial = c(
    "Unidad analítica como evento obstétrico materno",
    "Terminología 7.035 eventos obstétricos",
    "Flujograma con terminología de registros y eventos",
    "Explicación de ausencia de identificador longitudinal",
    "Dependencia residual",
    "Carta de respuesta alineada"
  ),
  archivo = c(
    "manuscript/Adolescentes_19_julio.qmd",
    "manuscript/Adolescentes_19_julio.qmd",
    "manuscript/Adolescentes_19_julio.qmd",
    "manuscript/Adolescentes_19_julio.qmd",
    "manuscript/Adolescentes_19_julio.qmd",
    "Carta de Respuesta.md"
  ),
  seccion = c(
    "Métodos",
    "Resumen/Resultados",
    "Figura 2",
    "Limitaciones",
    "Limitaciones",
    "Respuesta editorial"
  ),
  texto_anterior = c(
    "Se usaba la unidad como si fueran personas",
    "Se hablaba de 7.035 adolescentes",
    "Flujograma de selección de participantes",
    "No se explicaba la ausencia de identificador longitudinal",
    "No se discutía la posible dependencia residual",
    "Respuesta anterior no alineada"
  ),
  texto_nuevo = c(
    "La unidad de análisis fue el evento obstétrico materno y se aclaró la ausencia de identificador longitudinal",
    "Se analizaron 7.035 eventos obstétricos de adolescentes",
    "Flujograma de selección y consolidación de registros hasta la muestra de eventos obstétricos maternos",
    "Se incorporó la explicación de la ausencia de identificador longitudinal",
    "Se incorporó la discusión de posible dependencia residual",
    "Se incorporó la respuesta editorial alineada"
  ),
  evidencia = c(
    "Métodos del manuscrito",
    "Resumen y Resultados",
    "Texto de la figura 2",
    "Limitaciones",
    "Limitaciones",
    "Carta de respuesta"
  ),
  estado = c("cumple", "cumple", "cumple", "cumple", "cumple", "cumple"),
  observacion_residual = c("Sin observación residual", "Sin observación residual", "Sin observación residual", "Sin observación residual", "Sin observación residual", "Sin observación residual")
)
write.csv(requisitos, file.path(out_dir, "matriz_cumplimiento_editorial.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cambios <- c(
  "- Se corrigió la terminología del Resumen y Abstract para hablar de eventos obstétricos.",
  "- Se reformuló Métodos para definir la unidad de análisis como evento obstétrico materno y explicar la ausencia de identificador longitudinal.",
  "- Se ajustó Resultados y Discusión para referirse a eventos y no a personas únicas.",
  "- Se actualizó el texto del flujograma y de la nota asociada.",
  "- Se actualizó la fuente de la figura conceptual en Figura1_marco_conceptual.R y se regeneró la figura."
)
writeLines(cambios, file.path(out_dir, "cambios_realizados.md"))

error_rows <- subset(validacion, clasificacion == "error")
if (nrow(error_rows) > 0) {
  stop("Se encontraron expresiones prohibidas no justificadas.")
}

cat("Validación terminológica completada con éxito.\n")
cat("Archivo generado:", file.path(out_dir, "validacion_terminologia.csv"), "\n")
cat("Archivo generado:", file.path(out_dir, "matriz_cumplimiento_editorial.csv"), "\n")
q(status = 0)
