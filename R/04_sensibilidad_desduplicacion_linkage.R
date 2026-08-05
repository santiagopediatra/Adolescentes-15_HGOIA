#!/usr/bin/env Rscript
options(warn = 2)

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(stringr)
  library(purrr)
})

root <- function(...) { file.path(getwd(), ...) }

output_dir <- root("output", "desduplicacion")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}

ruta_csv <- root("Adolescentes.csv")
problemas_importacion <- tibble(issue = character(), detail = character())

check_file <- function(path) {
  if (!file.exists(path)) {
    problemas_importacion <<- bind_rows(problemas_importacion, tibble(
      issue = "missing_file",
      detail = paste0("Archivo faltante: ", path)
    ))
    stop("No se encontró el archivo: ", path)
  }
}

check_file(ruta_csv)

read_data <- function(path) {
  raw <- tryCatch(
    read_csv(path,
      locale = locale(encoding = "UTF-8"),
      show_col_types = FALSE,
      na = c("", "NA"),
      col_types = cols(.default = col_character())
    ),
    error = function(e) {
      problemas_importacion <<- bind_rows(problemas_importacion, tibble(
        issue = "read_error",
        detail = paste0("Error al leer CSV: ", e$message)
      ))
      stop(e)
    }
  )
  problems_df <- problems(raw)
  if (nrow(problems_df) > 0) {
    problemas_importacion <<- bind_rows(problemas_importacion, problems_df %>%
      transmute(issue = "parse_problem", detail = paste0("fila ", row, ", col ", col, ", expected ", expected, ", actual ", actual)))
  }
  names(raw) <- trimws(names(raw))
  names(raw) <- gsub("[[:space:]]+", " ", names(raw))
  raw
}

Adolescentes <- read_data(ruta_csv)

required_columns <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO", "Numero gestas previas",
  "Numero de Partos previos", "Cesáreas previas CODIGO",
  "Embarazo planeado CODIGO", "ANTICONCEPTIVO CODIGO",
  "Número Consultas prenatales", "TIPO DE PARTO", "CESAREA",
  "Embarazo múltiple CODIGO", "Edad gestaciol RN"
)

numeric_cols <- c(
  "Año", "Edad materna", "Numero gestas previas",
  "Numero de Partos previos", "Cesáreas previas CODIGO",
  "Embarazo planeado CODIGO", "ANTICONCEPTIVO CODIGO",
  "Número Consultas prenatales", "CESAREA",
  "Embarazo múltiple CODIGO", "Edad gestaciol RN"
)

Adolescentes <- Adolescentes %>%
  mutate(across(all_of(numeric_cols), ~ suppressWarnings(as.numeric(.))))
missing_columns <- setdiff(required_columns, names(Adolescentes))
if (length(missing_columns) > 0) {
  problemas_importacion <- bind_rows(problemas_importacion, tibble(
    issue = "missing_columns",
    detail = paste0("Faltan columnas requeridas: ", paste(missing_columns, collapse = ", "))
  ))
  write_csv(problemas_importacion, file.path(output_dir, "problemas_importacion.csv"))
  stop("Faltan columnas requeridas: ", paste(missing_columns, collapse = ", "))
}

pid_columns <- names(Adolescentes)[str_detect(toupper(names(Adolescentes)), "NOMBRE|CEDULA|C.E.D.U.L.A|DNI|IDENT|HISTORIA|APELLIDO|PASAPORTE")]
if (length(pid_columns) > 0) {
  problemas_importacion <- bind_rows(problemas_importacion, tibble(
    issue = "possible_pid_columns",
    detail = paste0("Columnas con posible información identificadora personal: ", paste(pid_columns, collapse = ", "))
  ))
}

if (nrow(problemas_importacion) > 0) {
  write_csv(problemas_importacion, file.path(output_dir, "problemas_importacion.csv"))
} else {
  write_csv(tibble(issue = "ok", detail = "Importación satisfactoria"), file.path(output_dir, "problemas_importacion.csv"))
}

sanitize_text <- function(x) {
  if (is.character(x)) {
    x <- str_replace_all(x, "[\r\n]+", " ")
    x <- str_squish(x)
  }
  x
}

assign_cluster_gestacional <- function(eg_vals, umbral_semanas = 3) {
  n <- length(eg_vals)
  if (n == 0) return(integer(0))
  if (n == 1) return(1L)
  if (all(is.na(eg_vals))) return(rep(1L, n))
  ord <- order(eg_vals, na.last = TRUE)
  eg_sorted <- eg_vals[ord]
  cluster_sorted <- integer(n)
  cluster_sorted[1] <- 1L
  cl <- 1L
  for (i in seq.int(2, n)) {
    if (
      !is.na(eg_sorted[i]) &&
      !is.na(eg_sorted[i - 1]) &&
      (eg_sorted[i] - eg_sorted[i - 1]) >= umbral_semanas
    ) {
      cl <- cl + 1L
    }
    cluster_sorted[i] <- cl
  }
  cluster_out <- integer(n)
  cluster_out[ord] <- cluster_sorted
  cluster_out
}

assign_cluster_exact <- function(eg_vals) {
  if (length(eg_vals) == 0) return(character(0))
  as.character(eg_vals)
}

mother_key_vars <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO",
  "Numero gestas previas", "Numero de Partos previos",
  "Cesáreas previas CODIGO", "Embarazo planeado CODIGO",
  "ANTICONCEPTIVO CODIGO", "Número Consultas prenatales",
  "TIPO DE PARTO", "CESAREA"
)

Adolescentes_limpia <- Adolescentes %>% distinct()

n_raw <- nrow(Adolescentes)
n_after_exact <- nrow(Adolescentes_limpia)
change_exact <- n_raw - n_after_exact
if (change_exact != 15) {
  problemas_importacion <- bind_rows(problemas_importacion, tibble(
    issue = "duplicate_count_mismatch",
    detail = paste0("Se esperaba 15 duplicados exactos pero se encontraron ", change_exact)
  ))
  write_csv(problemas_importacion, file.path(output_dir, "problemas_importacion.csv"))
  stop("Se esperaba 15 duplicados exactos pero se encontraron ", change_exact)
}

if (!all(c("Edad materna", "Año") %in% names(Adolescentes_limpia))) {
  stop("No se encontraron columnas clave necesarias para el análisis de edad materna o año.")
}

make_scenario <- function(df, name, threshold = NULL, exact_match = FALSE) {
  multiples <- df %>% filter(`Embarazo múltiple CODIGO` == 1)
  not_multiples <- df %>% filter(`Embarazo múltiple CODIGO` != 1 | is.na(`Embarazo múltiple CODIGO`))

  multiples <- multiples %>% mutate(.row_order = row_number())

  if (name == "A_exact_duplicates") {
    consolidated_multiples <- multiples %>% mutate(
      group_key = str_c(!!!syms(mother_key_vars), sep = "|"),
      cluster_id = "no_linkage"
    )
    final_multiples <- multiples
  } else if (exact_match) {
    consolidated_multiples <- multiples %>% mutate(
      group_key = str_c(!!!syms(mother_key_vars), sep = "|"),
      cluster_id = if_else(is.na(`Edad gestaciol RN`), "NA", as.character(`Edad gestaciol RN`))
    )
    final_multiples <- consolidated_multiples %>%
      arrange(.row_order) %>%
      distinct(across(all_of(c(mother_key_vars, "cluster_id"))), .keep_all = TRUE)
  } else {
    consolidated_multiples <- multiples %>%
      group_by(across(all_of(mother_key_vars))) %>%
      mutate(
        cluster_id = assign_cluster_gestacional(`Edad gestaciol RN`, umbral_semanas = threshold)
      ) %>%
      ungroup() %>%
      mutate(
        group_key = str_c(!!!syms(mother_key_vars), sep = "|"),
        cluster_id = as.character(cluster_id)
      )
    final_multiples <- consolidated_multiples %>%
      arrange(.row_order) %>%
      distinct(across(all_of(c(mother_key_vars, "cluster_id"))), .keep_all = TRUE)
  }

  final_df <- bind_rows(not_multiples, final_multiples) %>% select(-.row_order)
  final_df <- final_df %>% mutate(
    grupo_edad = case_when(
      is.na(`Edad materna`) ~ NA_character_, 
      `Edad materna` < 15 ~ "10-14",
      TRUE ~ "15-19"
    )
  )

  multiples_grouping <- if (name == "A_exact_duplicates") {
    multiples %>%
      group_by(across(all_of(mother_key_vars))) %>%
      summarize(
        size = n(),
        any_na_eg = any(is.na(`Edad gestaciol RN`)),
        eg_min = suppressWarnings(min(as.numeric(`Edad gestaciol RN`), na.rm = TRUE)),
        eg_max = suppressWarnings(max(as.numeric(`Edad gestaciol RN`), na.rm = TRUE)),
        eg_values = list(unique(`Edad gestaciol RN`)),
        .groups = "drop"
      ) %>%
      mutate(cluster_id = "no_linkage")
  } else if (exact_match) {
    consolidated_multiples %>%
      group_by(across(all_of(c(mother_key_vars, "cluster_id")))) %>%
      summarize(
        size = n(),
        any_na_eg = any(is.na(`Edad gestaciol RN`)),
        eg_min = suppressWarnings(min(as.numeric(`Edad gestaciol RN`), na.rm = TRUE)),
        eg_max = suppressWarnings(max(as.numeric(`Edad gestaciol RN`), na.rm = TRUE)),
        eg_values = list(unique(`Edad gestaciol RN`)),
        .groups = "drop"
      )
  } else {
    consolidated_multiples %>%
      group_by(across(all_of(c(mother_key_vars, "cluster_id")))) %>%
      summarize(
        size = n(),
        any_na_eg = any(is.na(`Edad gestaciol RN`)),
        eg_min = suppressWarnings(min(as.numeric(`Edad gestaciol RN`), na.rm = TRUE)),
        eg_max = suppressWarnings(max(as.numeric(`Edad gestaciol RN`), na.rm = TRUE)),
        eg_values = list(unique(`Edad gestaciol RN`)),
        .groups = "drop"
      )
  }

  multiples_grouping <- multiples_grouping %>%
    mutate(
      n_unique_eg = map_int(eg_values, ~ sum(!is.na(.x))),
      eg_min = ifelse(is.finite(eg_min), eg_min, NA_real_),
      eg_max = ifelse(is.finite(eg_max), eg_max, NA_real_),
      eg_range = ifelse(is.na(eg_min) | is.na(eg_max), NA_real_, eg_max - eg_min),
      eg_labels = map_chr(eg_values, function(v) {
        v <- sort(unique(v))
        if (all(is.na(v))) return("NA")
        paste0(v, collapse = ",")
      })
    )

  list(
  scenario = name,
  threshold = threshold,
  exact_match = exact_match,
  final_df = final_df,
  multiples_grouping = multiples_grouping,
  summary = tibble(
      escenario = name,
      registros_iniciales = n_after_exact,
      duplicados_exactos = change_exact,
      registros_despues_duplicados = n_after_exact,
      registros_consolidados = n_after_exact - nrow(final_df),
      eventos_finales = nrow(final_df),
      eventos_multiples = sum(final_df$`Embarazo múltiple CODIGO` == 1, na.rm = TRUE),
      eventos_unicos = sum(final_df$`Embarazo múltiple CODIGO` != 1 | is.na(final_df$`Embarazo múltiple CODIGO`), na.rm = TRUE),
      agrupamientos_totales = nrow(multiples_grouping),
      agrupamientos_1 = sum(multiples_grouping$size == 1),
      agrupamientos_2 = sum(multiples_grouping$size == 2),
      agrupamientos_3 = sum(multiples_grouping$size == 3),
      agrupamientos_4mas = sum(multiples_grouping$size >= 4),
      max_registros_por_agrupamiento = ifelse(nrow(multiples_grouping) == 0, 0, max(multiples_grouping$size, na.rm = TRUE)),
       agrupamientos_afectados = sum(multiples_grouping$size > 1),
      grupos_10_14 = sum(final_df$grupo_edad == "10-14", na.rm = TRUE),
      grupos_15_19 = sum(final_df$grupo_edad == "15-19", na.rm = TRUE)
    )
  )
}

scenarios <- list(
  make_scenario(Adolescentes_limpia, "A_exact_duplicates", threshold = NULL, exact_match = FALSE),
  make_scenario(Adolescentes_limpia, "B_llave_exacta", threshold = NULL, exact_match = TRUE),
  make_scenario(Adolescentes_limpia, "C_1_semana", threshold = 1, exact_match = FALSE),
  make_scenario(Adolescentes_limpia, "D_2_semanas", threshold = 2, exact_match = FALSE),
  make_scenario(Adolescentes_limpia, "E_3_semanas", threshold = 3, exact_match = FALSE)
)

summaries <- purrr::map_dfr(
  scenarios,
  function(x) {
  out <- x$summary

    if (!is.data.frame(out)) {
      stop("La salida 'summary' de un escenario no es un data.frame.")
    }

    out
  }
)
summaries <- summaries |>
  dplyr::mutate(
    eventos_finales =
      registros_despues_duplicados - registros_consolidados,

    agrupamientos_totales =
      agrupamientos_1 +
      agrupamientos_2 +
      agrupamientos_3 +
      agrupamientos_4mas
  )
required_summary_cols <- c(
  "escenario",
  "eventos_finales",
  "eventos_multiples",
  "eventos_unicos",
  "grupos_10_14",
  "grupos_15_19"
)

missing_summary_cols <- setdiff(
  required_summary_cols,
  names(summaries)
)

if (length(missing_summary_cols) > 0L) {
  stop(
    "Faltan columnas en summaries: ",
    paste(missing_summary_cols, collapse = ", "),
    ". Columnas disponibles: ",
    paste(names(summaries), collapse = ", ")
  )
}
message(
  "Valores encontrados en escenario: ",
  paste(unique(summaries$escenario), collapse = " | ")
)

print(
  summaries |>
    dplyr::select(
      escenario,
      registros_despues_duplicados,
      registros_consolidados,
      eventos_finales
    )
)

main_summary <- summaries |>
  dplyr::filter(escenario == "E_3_semanas")

if (nrow(main_summary) != 1L) {
  stop(
    "El escenario E_3_semanas debe aparecer exactamente una vez; aparece ",
    nrow(main_summary),
    " veces."
  )
}

summaries <- summaries %>%
  mutate(
    diff_eventos_finales = abs(eventos_finales - main_summary$eventos_finales),
    diff_eventos_multiples = abs(eventos_multiples - main_summary$eventos_multiples),
    diff_eventos_unicos = abs(eventos_unicos - main_summary$eventos_unicos),
    diff_10_14 = abs(grupos_10_14 - main_summary$grupos_10_14),
    diff_15_19 = abs(grupos_15_19 - main_summary$grupos_15_19)
  )

write_csv(summaries, file.path(output_dir, "resumen_escenarios.csv"))

agg_distribution <- bind_rows(map(scenarios, function(s) {
 s$multiples_grouping %>%
    mutate(escenario = s$scenario) %>%
    group_by(escenario, size) %>%
    summarize(
      n_agrupamientos = n(),
      registros_involucrados = sum(size),
      .groups = "drop"
    ) %>%
    ungroup()
})) %>%
  group_by(escenario) %>%
  mutate(
    porcentaje_agrupamientos = n_agrupamientos / sum(n_agrupamientos) * 100,
    porcentaje_registros = registros_involucrados / sum(registros_involucrados) * 100
  ) %>%
  ungroup()

write_csv(agg_distribution, file.path(output_dir, "distribucion_tamano_agrupamientos.csv"))

plot <- ggplot(agg_distribution, aes(x = factor(size), y = porcentaje_agrupamientos, fill = escenario)) +
  geom_col(position = position_dodge(width = 0.75)) +
  labs(
    title = "Distribución del tamaño de agrupamientos de embarazos múltiples",
    x = "Tamaño del agrupamiento (n registros)",
    y = "Porcentaje de agrupamientos",
    fill = "Escenario"
  ) +
  theme_minimal()

ggsave(filename = file.path(output_dir, "figura_distribucion_agrupamientos.png"), plot = plot, width = 10, height = 6, dpi = 300)


# Agrupamientos afectados por umbral para escenarios B-E
affected_by_threshold <- bind_rows(map(scenarios[-1], function(s) {
  mg <- s$multiples_grouping
  tibble(
    escenario = s$scenario,
    umbral = if (isTRUE(s$exact_match)) {
  0L
} else if (is.null(s$threshold)) {
  NA_integer_
} else {
  as.integer(s$threshold)
},
    agrupamientos_afectados = sum(mg$size > 1),
    registros_consolidadas = nrow(Adolescentes_limpia %>% filter(`Embarazo múltiple CODIGO` == 1)) - sum(mg$size)
  )
}))
write_csv(affected_by_threshold, file.path(output_dir, "agrupamientos_afectados_por_umbral.csv"))

# Comparación entre escenarios a nivel de asignación de filas múltiples
# Se construye una llave interna robusta a valores faltantes para evitar que
# str_c() convierta todo el identificador en NA cuando una de las 13 variables
# de la llave está ausente.
rows_after_exact <- Adolescentes_limpia %>%
  mutate(
    .original_row = row_number(),
    .mother_key = purrr::pmap_chr(
      across(all_of(mother_key_vars)),
      ~ paste(
        ifelse(is.na(c(...)), "<NA>", as.character(c(...))),
        collapse = "|"
      )
    )
  )

scenario_assignments <- map_dfr(scenarios, function(s) {
  df <- rows_after_exact %>%
    filter(`Embarazo múltiple CODIGO` == 1)

  if (s$scenario == "A_exact_duplicates") {
    df <- df %>%
      mutate(group_id = .mother_key)

  } else if (s$exact_match) {
    df <- df %>%
      mutate(
        group_id = str_c(
          .mother_key,
          dplyr::coalesce(as.character(`Edad gestaciol RN`), "<NA>"),
          sep = "||"
        )
      )

  } else {
    df <- df %>%
      group_by(across(all_of(mother_key_vars))) %>%
      mutate(
        cluster = assign_cluster_gestacional(
          `Edad gestaciol RN`,
          umbral_semanas = s$threshold
        )
      ) %>%
      ungroup() %>%
      mutate(
        group_id = str_c(.mother_key, cluster, sep = "||")
      )
  }

  df %>%
    select(.original_row, group_id) %>%
    mutate(scenario = s$scenario)
})

comparisons <- map_dfr(scenarios[-1], function(s) {
  base <- scenario_assignments %>% filter(scenario == "E_3_semanas") %>% select(.original_row, group_id_e = group_id)
  comp <- scenario_assignments %>% filter(scenario == s$scenario) %>% select(.original_row, group_id_s = group_id)
  joined <- left_join(base, comp, by = ".original_row")
  events_changed <- sum(joined$group_id_e != joined$group_id_s, na.rm = TRUE)
  groups_e <- joined %>% group_by(group_id_e) %>% summarize(n_s = n_distinct(group_id_s), .groups = "drop")
  groups_s <- joined %>% group_by(group_id_s) %>% summarize(n_e = n_distinct(group_id_e), .groups = "drop")
  tibble(
    escenario = s$scenario,
    filas_con_asignacion_distinta = events_changed,
    agrupamientos_e_split = sum(groups_e$n_s > 1),
    agrupamientos_s_fusion = sum(groups_s$n_e > 1)
  )
})
write_csv(comparisons, file.path(output_dir, "comparacion_entre_escenarios.csv"))

scenario_assignments_e <- scenario_assignments %>%
  filter(scenario == "E_3_semanas") %>%
  select(.original_row, group_id_e = group_id)

scenario_assignments <- scenario_assignments %>%
  left_join(scenario_assignments_e, by = ".original_row")

scenario_status <- scenario_assignments %>%
  filter(scenario %in% c("B_llave_exacta", "C_1_semana", "D_2_semanas", "E_3_semanas")) %>%
  group_by(group_id_e, scenario) %>%
  summarize(distinct_group_ids = n_distinct(group_id), .groups = "drop") %>%
  mutate(
    status = if_else(distinct_group_ids == 1L, "agrupado", "no agrupado"),
    label = case_when(
      scenario == "B_llave_exacta" ~ "llave_exacta",
      scenario == "C_1_semana" ~ "1_semana",
      scenario == "D_2_semanas" ~ "2_semanas",
      scenario == "E_3_semanas" ~ "3_semanas",
      TRUE ~ scenario
    )
  ) %>%
  select(group_id_e, label, status) %>%
  pivot_wider(names_from = label, values_from = status)

main_multiples <- scenarios[[5]]$multiples_grouping %>%
  mutate(
    .mother_key = purrr::pmap_chr(
      across(all_of(mother_key_vars)),
      ~ paste(
        ifelse(is.na(c(...)), "<NA>", as.character(c(...))),
        collapse = "|"
      )
    ),
    group_id_e = str_c(.mother_key, cluster_id, sep = "||"),
    año = as.integer(Año),
    grupo_etario = case_when(
      is.na(`Edad materna`) ~ NA_character_,
      `Edad materna` >= 10 & `Edad materna` <= 14 ~ "10-14",
      `Edad materna` >= 15 & `Edad materna` <= 19 ~ "15-19",
      TRUE ~ NA_character_
    ),
    ambiguous = (size > 2) |
      (n_unique_eg > 1) |
      any_na_eg |
      (eg_range %in% c(1, 2, 3, 4))
  )

ambiguous_clusters <- main_multiples %>% filter(ambiguous)

if (nrow(ambiguous_clusters) == 0) {
  ambiguous_report <- tibble(
    id = integer(),
    tamaño = integer(),
    año = integer(),
    grupo_etario = character(),
    edades_gestacionales_observadas = character(),
    mínimo = double(),
    máximo = double(),
    rango = double(),
    variables_discordantes = character(),
    llave_exacta = character(),
    `1_semana` = character(),
    `2_semanas` = character(),
    `3_semanas` = character(),
    motivo_ambiguedad = character(),
    decision_principal = character()
  )
} else {
  ambiguous_report <- ambiguous_clusters %>%
    left_join(scenario_status, by = "group_id_e") %>%
    transmute(
      id = row_number(),
      tamaño = size,
      año = as.integer(Año),
      grupo_etario = case_when(
        is.na(`Edad materna`) ~ NA_character_,
        `Edad materna` >= 10 & `Edad materna` <= 14 ~ "10-14",
        `Edad materna` >= 15 & `Edad materna` <= 19 ~ "15-19",
        TRUE ~ NA_character_
      ),
      edades_gestacionales_observadas = eg_labels,
      mínimo = eg_min,
      máximo = eg_max,
      rango = eg_range,
      variables_discordantes = "edad gestacional o más de dos registros",
      llave_exacta = dplyr::coalesce(llave_exacta, "no evaluable"),
      `1_semana` = dplyr::coalesce(`1_semana`, "no evaluable"),
      `2_semanas` = dplyr::coalesce(`2_semanas`, "no evaluable"),
      `3_semanas` = dplyr::coalesce(`3_semanas`, "no evaluable"),
      motivo_ambiguedad = "tamaño >2 o edades gestacionales discordantes o rango cercano al umbral",
      decision_principal = "Se consolidó según 3 semanas"
    )
}

write_csv(ambiguous_report, file.path(output_dir, "agrupamientos_ambiguos_anonimizados.csv"))

# Reconcilicación entre 152 y 245
main_df <- scenarios[[5]]$final_df
main_multiples_final <- main_df %>% filter(`Embarazo múltiple CODIGO` == 1)
original_multiples <- Adolescentes_limpia %>% filter(`Embarazo múltiple CODIGO` == 1)

multiple_clusters <- main_df %>%
  filter(`Embarazo múltiple CODIGO` == 1) %>%
  mutate(cluster = str_c(!!!syms(mother_key_vars), as.character(`Edad gestaciol RN`), sep = "||"))

original_multiple_clusters <- original_multiples %>%
  mutate(cluster = str_c(!!!syms(mother_key_vars), as.character(`Edad gestaciol RN`), sep = "||"))

reconciliation <- tibble(
  elemento = c(
    "registros_iniciales",
    "duplicados_exactos",
    "registros_despues_duplicados",
    "filas_multiples_originales",
    "filas_multiples_finales",
    "filas_consolidadas_por_multiples",
    "eventos_multiples_finales",
    "eventos_unicos_finales",
    "registros_finales",
    "identity_7202_15_152",
    "identity_245_6790"
  ),
  valor = c(
    n_raw,
    change_exact,
    n_after_exact,
    nrow(original_multiples),
    nrow(main_multiples_final),
    nrow(original_multiples) - nrow(main_multiples_final),
    nrow(main_multiples_final),
    sum(main_df$`Embarazo múltiple CODIGO` != 1 | is.na(main_df$`Embarazo múltiple CODIGO`), na.rm = TRUE),
    nrow(main_df),
    n_raw - change_exact - (nrow(original_multiples) - nrow(main_multiples_final)),
    nrow(main_multiples_final) + sum(main_df$`Embarazo múltiple CODIGO` != 1 | is.na(main_df$`Embarazo múltiple CODIGO`), na.rm = TRUE)
  ),
  nota = c(
    "Registros crudos iniciales",
    "Duplicados exactos eliminados",
    "Registros después de duplicados exactos",
    "Filas con código de embarazo múltiple en la base limpia",
    "Filas finales con código de embarazo múltiple en escenario principal",
    "Filas múltiples consolidadas por linkage",
    "Eventos obstétricos finales clasificados como múltiples",
    "Eventos obstétricos finales clasificados como únicos",
    "Eventos obstétricos finales totales",
    "Identidad aritmética: 7202 - 15 - 152 = 7035",
    "Identidad aritmética: 245 + 6790 = 7035"
  )
)
write_csv(reconciliation, file.path(output_dir, "transicion_152_245.csv"))

conteos_etario <- main_df %>%
  count(grupo_edad, name = "conteo") %>%
  complete(grupo_edad = c("10-14", "15-19"), fill = list(conteo = 0))
write_csv(conteos_etario, file.path(output_dir, "conteos_por_grupo_etario.csv"))

informe_lines <- c(
  "# Informe de auditoría de desduplicación y linkage",
  "",
  paste0("Fecha de ejecución: ", Sys.Date()),
  "",
  "## Validaciones automáticas",
  paste0("- Registros iniciales en Adolescentes.csv: ", n_raw),
  paste0("- Duplicados exactos eliminados: ", change_exact),
  paste0("- Registros después de duplicados exactos: ", n_after_exact),
  paste0("- Filas consolidadas en escenario principal (3 semanas): ", main_summary$registros_consolidados),
  paste0("- Eventos obstétricos finales en escenario principal: ", main_summary$eventos_finales),
  paste0("- Eventos múltiples en escenario principal: ", main_summary$eventos_multiples),
  paste0("- Eventos únicos en escenario principal: ", main_summary$eventos_unicos),
  paste0("- Conteo 10-14 años en escenario principal: ", main_summary$grupos_10_14),
  paste0("- Conteo 15-19 años en escenario principal: ", main_summary$grupos_15_19),
  "",
  "## Resultados principales por escenario",
  "",
  paste(capture.output(print(summaries)), collapse = "\n"),
  "",
  "## Distribución del tamaño de agrupamientos",
  "",
  paste(capture.output(print(agg_distribution)), collapse = "\n"),
  "",
  "## Agrupamientos ambiguos identificados",
  paste0("- Clusters ambiguos en escenario principal: ", nrow(ambiguous_report)),
  "",
  "## Reconciliación entre 152 y 245",
  paste(capture.output(print(reconciliation)), collapse = "\n"),
  "",
  "## Limitaciones detectadas",
  "",
  "- El umbral de tres semanas se aplica solo dentro de las filas con `Embarazo múltiple CODIGO == 1`.",
  "- El agrupamiento original usa diferencias de edad gestacional ordenadas y no compara todos los pares entre sí.",
  "- Los valores de edad gestacional faltantes se agrupan con el registro anterior cuando existen registros no faltantes en la misma llave.",
  "- La consolidación conserva la primera fila encontrada dentro de cada cluster, lo que puede retener información de un recién nacido de manera arbitraria cuando hay múltiples registros con la misma llave y cluster."
)
writeLines(informe_lines, file.path(output_dir, "informe_auditoria_desduplicacion.md"))

message("Script ejecutado correctamente. Archivos guardados en ", output_dir)
