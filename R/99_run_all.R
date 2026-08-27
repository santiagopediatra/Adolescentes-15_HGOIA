#!/usr/bin/env Rscript

# Orquestador del análisis validado. Debe ejecutarse desde cualquier ubicación;
# fija como directorio de trabajo la raíz que contiene este archivo.

locate_project_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]), mustWork = TRUE)
    return(dirname(dirname(script_path)))
  }
  if (file.exists(file.path(getwd(), "R", "99_run_all.R"))) {
    return(normalizePath(getwd(), mustWork = TRUE))
  }
  stop("No se pudo localizar la raíz. Ejecute Rscript R/99_run_all.R o source() desde la raíz.")
}

project_root <- locate_project_root()
old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)

source(file.path("R", "00_config.R"), local = FALSE)
source(file.path("R", "requirements_packages.R"), local = FALSE)

dir.create(file.path(RUTA_OUTPUT, "logs"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(RUTA_OUTPUT, "main"), recursive = TRUE, showWarnings = FALSE)

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
log_file <- file.path(RUTA_OUTPUT, "logs", paste0("run_all_", timestamp, ".log"))

log_line <- function(...) {
  line <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), " | ", paste0(..., collapse = ""))
  cat(line, "\n")
  cat(line, "\n", file = log_file, append = TRUE)
}

required_files <- c(
  RUTA_BASE_FUENTE,
  "ANALISIS_ADOLESCENTES_CORREGIDO_v3.R",
  file.path("R", "03_auditoria_gestaciones_multiples.R"),
  file.path("R", "01_generate_data_dictionary.R"),
  file.path("R", "04_punto6_atencion_prenatal.R"),
  file.path("R", "05_punto7_consultas_prenatales.R"),
  file.path("R", "06_punto8_diagnosticos_priors.R"),
  file.path("R", "07_punto9_heterogeneidad_temporal.R"),
  file.path("R", "08_punto4_sensibilidad_rezago_escolar.R"),
  file.path("R", "09_sensibilidad_linkage_corregida.R"),
  file.path("R", "10_sensibilidad_priors_rezago_edad5.R"),
  "Figura1_marco_seleccion_EN.R",
  "Figura2_flujograma_STROBE.R",
  "Figura3_distribucion_anual_EN.R"
)

validation_files <- setdiff(required_files, RUTA_BASE_FUENTE)
validate_only <- identical(tolower(Sys.getenv("REPRO_VALIDATE_ONLY", "false")), "true")
files_to_check <- if (validate_only) validation_files else required_files
missing_files <- files_to_check[!file.exists(files_to_check)]
if (length(missing_files)) {
  stop("Faltan archivos requeridos: ", paste(missing_files, collapse = ", "))
}
if (length(missing_required_packages)) {
  stop(
    "Faltan paquetes de R: ", paste(missing_required_packages, collapse = ", "),
    ". Consulte R/requirements_packages.R; el pipeline no instala paquetes automáticamente."
  )
}

log_line("Inicio del pipeline")
log_line("Raíz: ", project_root)
log_line("R: ", R.version.string)
log_line("Semillas: ", paste(names(SEMILLAS_ANALISIS), SEMILLAS_ANALISIS, sep = "=", collapse = "; "))
log_line("SHA-256 de la base se registra mediante la herramienta del sistema durante la validación documental.")

if (validate_only) {
  scripts <- validation_files[grepl("\\.R$", validation_files)]
  parse_errors <- character()
  for (script in scripts) {
    tryCatch(parse(file = script), error = function(e) {
      parse_errors <<- c(parse_errors, paste(script, conditionMessage(e), sep = ": "))
    })
  }
  if (length(parse_errors)) stop(paste(parse_errors, collapse = "\n"))
  log_line("VALIDACIÓN ESTRUCTURAL completada; no se recalcularon modelos ni salidas.")
}

if (!validate_only) {
  run_script <- function(path) {
  log_line("INICIO: ", path)
  source(path, local = new.env(parent = globalenv()), echo = FALSE, chdir = FALSE)
  log_line("FIN: ", path)
  }

  run_script(file.path("R", "01_generate_data_dictionary.R"))
  run_script("ANALISIS_ADOLESCENTES_CORREGIDO_v3.R")

  for (artifact in c(RUTA_RESULTADOS_XLSX, RUTA_RESULTADOS_RDS)) {
    if (!file.exists(artifact)) stop("El pipeline principal no produjo ", artifact)
    ok <- file.copy(artifact, file.path(RUTA_OUTPUT, "main", basename(artifact)), overwrite = TRUE)
    if (!ok) stop("No se pudo copiar el resultado principal a output/main/: ", artifact)
  }

  run_script(file.path("R", "03_auditoria_gestaciones_multiples.R"))
  run_script(file.path("R", "09_sensibilidad_linkage_corregida.R"))
  run_script(file.path("R", "04_punto6_atencion_prenatal.R"))
  run_script(file.path("R", "05_punto7_consultas_prenatales.R"))
  run_script(file.path("R", "06_punto8_diagnosticos_priors.R"))
  run_script(file.path("R", "10_sensibilidad_priors_rezago_edad5.R"))
  run_script(file.path("R", "07_punto9_heterogeneidad_temporal.R"))
  run_script(file.path("R", "08_punto4_sensibilidad_rezago_escolar.R"))
  run_script("Figura1_marco_seleccion_EN.R")
  run_script("Figura2_flujograma_STROBE.R")
  run_script("Figura3_distribucion_anual_EN.R")

  log_line("Pipeline finalizado. Revise output/ y compare con los artefactos validados.")
}
