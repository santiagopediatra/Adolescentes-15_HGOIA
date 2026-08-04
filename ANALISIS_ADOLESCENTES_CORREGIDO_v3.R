############################################################
# PIPELINE DEFINITIVO — RBSMI, REVISIÓN MAYOR
# Estudio: adolescentes de 10–14 vs 15–19 años
#

############################################################
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
  library(janitor)
  library(brms)
  library(posterior)
  library(BayesFactor)
  library(openxlsx)
})
set.seed(1234)
options(mc.cores = 4)
############################################################

############################################################
TOPE_ANIOS_ESCOLARIDAD <- 12
############################################################
# 0. COMPROBACIONES PREVIAS
############################################################
############################################################
# CARGA AUTOMÁTICA (agregada para correr sin RStudio, vía Rscript/nohup).
# Adolescentes.csv es UTF-8, separado por comas (confirmado con
# `file` y `head -1` sobre el archivo real). Se usa check.names=FALSE
# para que R NO reemplace los espacios de los nombres de columna por
# puntos (si lo hiciera, romperia cada referencia con backticks del
# resto del script, que usa nombres tal como aparecen en el CSV).
# Además, el CSV real trae espacios sobrantes en algunos encabezados
# (" ETNIA MINORITARIA ", " ANTICONCEPTIVO CODIGO",
# "CODIGO Apgar 1 minuto <7 ") que no coinciden con los nombres
# exactos usados en required_vars/vars_llave_madre más abajo; se
# recortan y colapsan espacios múltiples, preservando el resto del
# nombre (mayúsculas, tildes, contenido) intacto.
############################################################
if (!exists("Adolescentes")) {
  ruta_csv <- "Adolescentes.csv"
  if (!file.exists(ruta_csv)) {
    stop(
      "No existe el objeto 'Adolescentes' en el entorno y tampoco se ",
      "encontró '", ruta_csv, "' en el directorio de trabajo (",
      getwd(), "). Cargue la base cruda primero."
    )
  }
  Adolescentes <- read.csv(
    ruta_csv,
    fileEncoding = "UTF-8",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  names(Adolescentes) <- trimws(names(Adolescentes))
  names(Adolescentes) <- gsub("[[:space:]]+", " ", names(Adolescentes))
  cat("Adolescentes cargado desde", ruta_csv, "-", nrow(Adolescentes), "filas,",
      ncol(Adolescentes), "columnas.\n")
}
required_vars <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO", "ETNIA MINORITARIA",
  "Numero gestas previas", "Numero de Partos previos",
  "Cesáreas previas CODIGO", "Embarazo planeado CODIGO",
  "ANTICONCEPTIVO CODIGO", "Número Consultas prenatales",
  "TIPO DE PARTO", "CESAREA", "Embarazo múltiple CODIGO",
  "Edad gestaciol RN", "Estudios CODIGO", "Gestas previas CODIGO",
  "Infección urinaria", "Sufrimiento fetal",
  "Preeclampsia actual", "Eclampsia actual", "HTA inducida actual",
  "PREMATURO CODIGO", "CODIGO Apgar 1 minuto <7",
  "CODIGO Apgar 5to. < 7", "RCIU", "MACROSÓMICO",
  "BEBE Ictericia", "RN vivo CODIGO",
  "Lactancia exclusiva SI NO", "Peso al nacer GRAMOS"
)
missing_vars <- setdiff(required_vars, names(Adolescentes))
if (length(missing_vars) > 0) {
  stop(
    "Faltan variables requeridas en la base: ",
    paste(missing_vars, collapse = ", ")
  )
}
############################################################
# A. DEPURACIÓN Y UNIDAD DE ANÁLISIS
############################################################
Adolescentes_limpia <- Adolescentes %>% distinct()
cat("=== A. DEPURACIÓN ===\n")
cat("n tras eliminar filas completamente duplicadas:",
    nrow(Adolescentes_limpia), "\n")
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
multiples_antes <- Adolescentes_limpia %>%
  filter(`Embarazo múltiple CODIGO` == 1)
multiples_dedup <- multiples_antes %>%
  group_by(across(all_of(vars_llave_madre))) %>%
  mutate(
    subgrupo_gestacional =
      asignar_cluster_gestacional(`Edad gestaciol RN`, umbral_semanas = 3)
  ) %>%
  ungroup() %>%
  distinct(
    across(all_of(c(vars_llave_madre, "subgrupo_gestacional"))),
    .keep_all = TRUE
  )
Adolescentes_por_madre <- bind_rows(
  Adolescentes_limpia %>%
    filter(
      `Embarazo múltiple CODIGO` != 1 |
        is.na(`Embarazo múltiple CODIGO`)
    ),
  multiples_dedup
) %>%
  filter(
    !is.na(`Edad materna`),
    `Edad materna` >= 10,
    `Edad materna` <= 19
  )
cat("n final por madre/parto:", nrow(Adolescentes_por_madre), "\n")
cat(
  "10–14 años:",
  sum(Adolescentes_por_madre$`Edad materna` < 15, na.rm = TRUE),
  "| 15–19 años:",
  sum(Adolescentes_por_madre$`Edad materna` >= 15, na.rm = TRUE),
  "\n\n"
)
############################################################
# B. VARIABLES DERIVADAS
############################################################
df <- Adolescentes_por_madre %>%
  mutate(
    menor15 = if_else(`Edad materna` < 15, 1L, 0L),
    grupo_edad = factor(
      if_else(menor15 == 1, "10–14 años", "15–19 años"),
      levels = c("15–19 años", "10–14 años")
    ),
    # Escolaridad acumulada.
    # Mantener esta regla solo si la codificación institucional fue verificada.
    anios_escolaridad_total = case_when(
      `Estudios CODIGO` == 0 ~ 0,
      `Estudios CODIGO` == 1 ~ `Años estudios mayor nivel`,
      `Estudios CODIGO` == 2 ~ 9 + `Años estudios mayor nivel`,
      `Estudios CODIGO` == 3 ~ 12 + `Años estudios mayor nivel`,
      TRUE ~ NA_real_
    ),
    anios_escolaridad_esperados = pmin(
      pmax(`Edad materna` - 6, 0),
      TOPE_ANIOS_ESCOLARIDAD
    ),
    rezago_escolar_anios =
      anios_escolaridad_esperados - anios_escolaridad_total,
    categoria_rezago_escolar = case_when(
      is.na(rezago_escolar_anios) ~ NA_character_,
      rezago_escolar_anios <= 1 ~ "Ausente",
      rezago_escolar_anios >= 2 ~ "Presente"
    ),
    categoria_rezago_escolar = factor(
      categoria_rezago_escolar,
      levels = c(
        "Ausente",
        "Presente"
      ),
      ordered = TRUE
    ),
    rezago_escolar_bin = case_when(
      is.na(categoria_rezago_escolar) ~ NA_integer_,
      categoria_rezago_escolar == "Ausente" ~ 0L,
      TRUE ~ 1L
    ),
    # Adecuación del control prenatal según edad gestacional alcanzada.
    # Esta clasificación es operacional y debe describirse como tal.
    controles_esperados = case_when(
      is.na(`Edad gestaciol RN`) ~ NA_real_,
      `Edad gestaciol RN` < 20 ~ 1,
      `Edad gestaciol RN` < 26 ~ 2,
      `Edad gestaciol RN` < 30 ~ 3,
      `Edad gestaciol RN` < 34 ~ 4,
      `Edad gestaciol RN` < 36 ~ 5,
      `Edad gestaciol RN` < 38 ~ 6,
      `Edad gestaciol RN` < 40 ~ 7,
      TRUE ~ 8
    ),
    proporcion_controles =
      `Número Consultas prenatales` / controles_esperados,
    adecuacion_controles = case_when(
      is.na(proporcion_controles) ~ NA_character_,
      `Número Consultas prenatales` == 0 ~ "Sin controles",
      proporcion_controles < 0.50 ~ "Inadecuado",
      proporcion_controles < 0.80 ~ "Intermedio",
      TRUE ~ "Adecuado"
    ),
    adecuacion_controles = factor(
      adecuacion_controles,
      levels = c(
        "Sin controles",
        "Inadecuado",
        "Intermedio",
        "Adecuado"
      ),
      ordered = TRUE
    ),
    adecuacion_adecuada_bin = case_when(
      is.na(adecuacion_controles) ~ NA_integer_,
      adecuacion_controles == "Adecuado" ~ 1L,
      TRUE ~ 0L
    ),
    # Variables maternas binarias
    pareja_estable = as.integer(`PAREJA ESTABLE CODIGO`),
    escolaridad_baja = if_else(
      `Estudios CODIGO` %in% c(0, 1), 1L, 0L,
      missing = NA_integer_
    ),
    etnia_minoritaria = as.integer(`ETNIA MINORITARIA`),
    gestas_previas = as.integer(`Gestas previas CODIGO`),
    embarazo_multiple = as.integer(`Embarazo múltiple CODIGO`),
    embarazo_planeado = as.integer(`Embarazo planeado CODIGO`),
    falla_anticonceptivo = as.integer(`ANTICONCEPTIVO CODIGO`),
    infeccion_urinaria = as.integer(`Infección urinaria`),
    sufrimiento_fetal = as.integer(`Sufrimiento fetal`),
    trastorno_hipertensivo = case_when(
      `Preeclampsia actual` == 1 |
        `Eclampsia actual` == 1 |
        `HTA inducida actual` == 1 ~ 1L,
      `Preeclampsia actual` == 0 &
        `Eclampsia actual` == 0 &
        `HTA inducida actual` == 0 ~ 0L,
      TRUE ~ NA_integer_
    ),
    parto_vaginal = case_when(
      str_to_lower(str_trim(`TIPO DE PARTO`)) == "vaginal" ~ 1L,
      str_to_lower(str_trim(`TIPO DE PARTO`)) %in%
        c("cesárea", "cesarea") ~ 0L,
      TRUE ~ NA_integer_
    ),
    # Variables neonatales: solo descriptivas
    prematuro = as.integer(`PREMATURO CODIGO`),
    apgar1_bajo = as.integer(`CODIGO Apgar 1 minuto <7`),
    apgar5_bajo = as.integer(`CODIGO Apgar 5to. < 7`),
    peg = as.integer(RCIU),
    macrosomico = as.integer(MACROSÓMICO),
    ictericia_neonatal = as.integer(`BEBE Ictericia`),
    rn_vivo = case_when(
      as.character(`RN vivo CODIGO`) == "1" ~ 1L,
      as.character(`RN vivo CODIGO`) == "0" ~ 0L,
      TRUE ~ NA_integer_
    ),
    lactancia_exclusiva = case_when(
      str_to_lower(str_trim(`Lactancia exclusiva SI NO`)) %in%
        c("si", "sí") ~ 1L,
      str_to_lower(str_trim(`Lactancia exclusiva SI NO`)) == "no" ~ 0L,
      TRUE ~ NA_integer_
    ),
    subperiodo = case_when(
      Año >= 2009 & Año <= 2014 ~ "2009–2014",
      Año >= 2015 & Año <= 2019 ~ "2015–2019",
      Año >= 2020 & Año <= 2024 ~ "2020–2024",
      TRUE ~ NA_character_
    ),
    subperiodo = factor(
      subperiodo,
      levels = c("2009–2014", "2015–2019", "2020–2024")
    )
  )

# La muestra analítica final para variables neonatales se restringe
# a nacimientos únicos. Esto mantiene la unidad de análisis materna
# en `df` (7035 eventos) y la muestra neonatal única en `df_neonatal`.
#
# Esta submuestra excluye explícitamente los registros con
# `embarazo_multiple == 1`, conservando sólo los partos únicos para
# los indicadores neonatales descriptivos.

df_neonatal <- df %>%
  filter(
    embarazo_multiple != 1 |
      is.na(embarazo_multiple)
  )

cat("n final por madre/parto:", nrow(df), "\n")
cat("gestaciones múltiples en la muestra materna:",
    sum(df$embarazo_multiple == 1, na.rm = TRUE), "\n")
cat("n nacimientos únicos para descripción neonatal:", nrow(df_neonatal), "\n")
cat("n nacimientos únicos por grupo etario:\n")
print(df_neonatal %>% count(grupo_edad))

variables_modelos <- c(
  "pareja_estable",
  "escolaridad_baja",
  "etnia_minoritaria",
  "gestas_previas",
  "embarazo_multiple",
  "embarazo_planeado",
  "falla_anticonceptivo",
  "infeccion_urinaria",
  "sufrimiento_fetal",
  "trastorno_hipertensivo",
  "parto_vaginal",
  "rezago_escolar_bin",
  "adecuacion_adecuada_bin"
)
variables_neonatales <- c(
  "prematuro",
  "apgar1_bajo",
  "apgar5_bajo",
  "peg",
  "macrosomico",
  "ictericia_neonatal",
  "rn_vivo",
  "lactancia_exclusiva"
)
############################################################
# C. FUNCIONES DESCRIPTIVAS
############################################################
tabla_binaria <- function(data, var) {
  data %>%
    filter(!is.na(menor15), !is.na(.data[[var]])) %>%
    group_by(grupo_edad) %>%
    summarise(
      n_valido = n(),
      n_evento = sum(.data[[var]] == 1, na.rm = TRUE),
      porcentaje = 100 * n_evento / n_valido,
      .groups = "drop"
    ) %>%
    mutate(variable = var) %>%
    pivot_wider(
      id_cols = variable,
      names_from = grupo_edad,
      values_from = c(n_valido, n_evento, porcentaje),
      names_sep = "__"
    )
}
tabla_continua <- function(data, var) {
  data %>%
    filter(!is.na(menor15), !is.na(.data[[var]])) %>%
    group_by(grupo_edad) %>%
    summarise(
      n_valido = n(),
      mediana = median(.data[[var]], na.rm = TRUE),
      q1 = quantile(.data[[var]], 0.25, na.rm = TRUE),
      q3 = quantile(.data[[var]], 0.75, na.rm = TRUE),
      media = mean(.data[[var]], na.rm = TRUE),
      de = sd(.data[[var]], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(variable = var) %>%
    pivot_wider(
      id_cols = variable,
      names_from = grupo_edad,
      values_from = c(n_valido, mediana, q1, q3, media, de),
      names_sep = "__"
    )
}
tabla_categorica <- function(data, var) {
  data %>%
    filter(!is.na(menor15), !is.na(.data[[var]])) %>%
    count(grupo_edad, categoria = .data[[var]], name = "n_evento") %>%
    group_by(grupo_edad) %>%
    mutate(
      n_valido = sum(n_evento),
      porcentaje = 100 * n_evento / n_valido
    ) %>%
    ungroup() %>%
    mutate(variable = var) %>%
    select(variable, categoria, grupo_edad, n_valido, n_evento, porcentaje) %>%
    pivot_wider(
      id_cols = c(variable, categoria),
      names_from = grupo_edad,
      values_from = c(n_valido, n_evento, porcentaje),
      names_sep = "__"
    )
}
calcular_bf_tabla <- function(data, var) {
  d <- data %>%
    select(menor15, all_of(var)) %>%
    filter(!is.na(menor15), !is.na(.data[[var]]))
  tab <- table(d$menor15, d[[var]])
  if (nrow(tab) < 2 || ncol(tab) < 2) {
    return(tibble(variable = var, BF10 = NA_real_))
  }
  bf <- tryCatch(
    BayesFactor::contingencyTableBF(
      tab,
      sampleType = "indepMulti",
      fixedMargin = "cols"
    ),
    error = function(e) NULL
  )
  bf_val <- tryCatch(
    exp(bf@bayesFactor$bf[1]),
    error = function(e) NA_real_
  )
  tibble(variable = var, BF10 = bf_val)
}
############################################################
# D. DIAGNÓSTICOS BAYESIANOS CORRECTOS
############################################################
calcular_ebfmi <- function(fit) {
  np <- brms::nuts_params(fit)
  energy <- np %>%
    filter(Parameter == "energy__") %>%
    arrange(Chain, Iteration)
  if (nrow(energy) == 0) return(NA_real_)
  ebfmi_chain <- energy %>%
    group_by(Chain) %>%
    summarise(
      ebfmi = mean(diff(Value)^2, na.rm = TRUE) /
        var(Value, na.rm = TRUE),
      .groups = "drop"
    )
  min(ebfmi_chain$ebfmi, na.rm = TRUE)
}
# FIX: la versión original intentaba leer
# fit$fit@sim$control$max_treedepth para saber contra qué umbral comparar
# el treedepth observado. Ese campo no existe ahí (vive en
# fit$fit@stan_args[[i]]$control$max_treedepth); la expresión original
# evaluaba a NULL sin error, y "if (is.na(NULL))" revienta con
# "argument is of length zero" en la primera llamada. Se reemplaza por
# un parámetro explícito: cada llamador ya sabe qué max_treedepth usó
# al invocar brm(), así que se lo pasa directamente — sin introspección
# frágil del objeto stanfit.
extraer_diagnosticos <- function(fit, max_treedepth = 15) {
  # FIX: summarise_draws() nombra cada columna de salida a partir de la
  # expresión deparseada del argumento cuando no se nombra explícitamente.
  # posterior::rhat (con el prefijo del paquete) generaba una columna
  # llamada literalmente "posterior::rhat", NO "rhat" -- summ$rhat
  # devolvía NULL (con warning "Unknown or uninitialised column"),
  # max(NULL, na.rm=TRUE) = -Inf, y is.finite(-Inf) = FALSE marcaba
  # TODOS los modelos como "Revisar diagnósticos" sin excepción, sin
  # que hubiera ningún problema real de convergencia. Fix: nombrar los
  # argumentos explícitamente para fijar el nombre de columna.
  summ <- posterior::summarise_draws(
    posterior::as_draws_array(fit),
    rhat = posterior::rhat,
    ess_bulk = posterior::ess_bulk,
    ess_tail = posterior::ess_tail
  )
  np <- brms::nuts_params(fit)
  tibble(
    Rhat_max = max(summ$rhat, na.rm = TRUE),
    ESS_bulk_min = min(summ$ess_bulk, na.rm = TRUE),
    ESS_tail_min = min(summ$ess_tail, na.rm = TRUE),
    E_BFMI_min = calcular_ebfmi(fit),
    divergencias = sum(
      np$Parameter == "divergent__" & np$Value == 1,
      na.rm = TRUE
    ),
    treedepth_max_excedido = sum(
      np$Parameter == "treedepth__" & np$Value >= max_treedepth,
      na.rm = TRUE
    )
  )
}
diagnostico_aceptable <- function(diag) {
  is.finite(diag$Rhat_max) &&
    diag$Rhat_max <= 1.01 &&
    is.finite(diag$ESS_bulk_min) &&
    diag$ESS_bulk_min >= 400 &&
    is.finite(diag$ESS_tail_min) &&
    diag$ESS_tail_min >= 400 &&
    is.finite(diag$E_BFMI_min) &&
    diag$E_BFMI_min >= 0.30 &&
    diag$divergencias == 0 &&
    (
      is.na(diag$treedepth_max_excedido) ||
        diag$treedepth_max_excedido == 0
    )
}
############################################################
# E. MODELOS BINARIOS:
# BERNOULLI-LOGIT + RP MARGINAL ESTANDARIZADA
############################################################
ajustar_pr_marginal <- function(
    data,
    outcome,
    iter = 6000,
    warmup = 3000,
    chains = 4,
    adapt_delta = 0.99,
    max_treedepth = 15,
    template_fit = NULL
) {
  d <- data %>%
    select(menor15, all_of(outcome)) %>%
    filter(!is.na(menor15), !is.na(.data[[outcome]])) %>%
    transmute(
      menor15 = as.integer(menor15),
      y = as.integer(.data[[outcome]])
    ) %>%
    filter(
      menor15 %in% c(0L, 1L),
      y %in% c(0L, 1L)
    )
  n_eventos <- sum(d$y == 1)
  n_no_eventos <- sum(d$y == 0)
  if (
    nrow(d) < 50 ||
    n_eventos < 5 ||
    n_no_eventos < 5 ||
    length(unique(d$menor15)) < 2
  ) {
    return(list(
      modelo = NULL,
      resumen = tibble(
        variable = outcome,
        n = nrow(d),
        eventos = n_eventos,
        RP = NA_real_,
        ICr95_Low = NA_real_,
        ICr95_Up = NA_real_,
        diferencia_prevalencia = NA_real_,
        DP_Low = NA_real_,
        DP_Up = NA_real_,
        pd = NA_real_,
        Rhat_max = NA_real_,
        ESS_bulk_min = NA_real_,
        ESS_tail_min = NA_real_,
        E_BFMI_min = NA_real_,
        divergencias = NA_integer_,
        treedepth_max_excedido = NA_integer_,
        metodo = "Bernoulli-logit con estandarización posterior",
        nota = "Eventos o variación insuficientes"
      )
    ))
  }
  # SEGUNDO FIX (después de que corriste el primero): las 13 variables
  # principales + las 39 de sensibilidad por subperíodo comparten
  # EXACTAMENTE la misma fórmula (y ~ menor15) y familia (bernoulli-logit),
  # pero como el prior del Intercept llevaba un número distinto por
  # variable (round(qlogis(p0),4)), brms generaba un .stan ligeramente
  # distinto cada vez -> recompilación completa en las 52 llamadas. Eso es
  # ~45-60s de g++/make por variable, en un loop apretado, y es la causa
  # más probable de que la sesión terminara sin conexiones válidas
  # ("conexión inválida" hasta en sink()). Solución: un prior FIJO, no
  # dependiente de los datos (normal(0,3) en el Intercept -- weakly
  # informative estándar en escala logit, cubre sin problema el rango de
  # prevalencias de este estudio, de ~3,6% a ~56%, log-odds entre -3,3 y
  # 0,24). Esto vuelve el modelo Stan IDÉNTICO en las 52 llamadas
  # bernoulli-logit, permitiendo compilar UNA sola vez y reutilizar el
  # binario ya compilado vía update(..., recompile = FALSE) para el resto
  # -- de 52 compilaciones a 1.
  p0 <- mean(d$y[d$menor15 == 0])
  p0 <- min(max(p0, 0.001), 0.999)
  fit <- tryCatch(
    if (is.null(template_fit)) {
      brm(
        y ~ menor15,
        data = d,
        family = bernoulli(link = "logit"),
        prior = c(
          prior(normal(0, 3), class = "Intercept"),
          prior(normal(0, 1.5), class = "b")
        ),
        chains = chains,
        iter = iter,
        warmup = warmup,
        seed = 1234,
        refresh = 0,
        cores = 4,
        control = list(
          adapt_delta = adapt_delta,
          max_treedepth = max_treedepth
        )
      )
    } else {
      update(
        template_fit,
        newdata = d,
        recompile = FALSE,
        chains = chains,
        iter = iter,
        warmup = warmup,
        seed = 1234,
        refresh = 0,
        cores = 4,
        control = list(
          adapt_delta = adapt_delta,
          max_treedepth = max_treedepth
        )
      )
    },
    error = function(e) {
      message("ERROR en ", outcome, ": ", e$message)
      NULL
    }
  )
  if (is.null(fit)) {
    return(list(
      modelo = NULL,
      resumen = tibble(
        variable = outcome,
        n = nrow(d),
        eventos = n_eventos,
        RP = NA_real_,
        ICr95_Low = NA_real_,
        ICr95_Up = NA_real_,
        diferencia_prevalencia = NA_real_,
        DP_Low = NA_real_,
        DP_Up = NA_real_,
        pd = NA_real_,
        Rhat_max = NA_real_,
        ESS_bulk_min = NA_real_,
        ESS_tail_min = NA_real_,
        E_BFMI_min = NA_real_,
        divergencias = NA_integer_,
        treedepth_max_excedido = NA_integer_,
        metodo = "Bernoulli-logit con estandarización posterior",
        nota = "Error durante el ajuste"
      )
    ))
  }
  draws <- posterior::as_draws_df(fit)
  p_ref <- plogis(draws$b_Intercept)
  p_exp <- plogis(draws$b_Intercept + draws$b_menor15)
  rp_draws <- p_exp / p_ref
  dp_draws <- p_exp - p_ref
  # FIX: se pasa max_treedepth explícitamente (ver nota en Sección D).
  diag <- extraer_diagnosticos(fit, max_treedepth = max_treedepth)
  resumen <- tibble(
    variable = outcome,
    n = nrow(d),
    eventos = n_eventos,
    RP = median(rp_draws),
    ICr95_Low = unname(quantile(rp_draws, 0.025)),
    ICr95_Up = unname(quantile(rp_draws, 0.975)),
    diferencia_prevalencia = median(dp_draws),
    DP_Low = unname(quantile(dp_draws, 0.025)),
    DP_Up = unname(quantile(dp_draws, 0.975)),
    pd = max(
      mean(rp_draws > 1),
      mean(rp_draws < 1)
    ),
    Rhat_max = diag$Rhat_max,
    ESS_bulk_min = diag$ESS_bulk_min,
    ESS_tail_min = diag$ESS_tail_min,
    E_BFMI_min = diag$E_BFMI_min,
    divergencias = diag$divergencias,
    treedepth_max_excedido = diag$treedepth_max_excedido,
    metodo = "Bernoulli-logit con estandarización posterior",
    nota = if_else(
      diagnostico_aceptable(diag),
      "Diagnósticos adecuados",
      "Revisar diagnósticos"
    )
  )
  list(modelo = fit, resumen = resumen)
}
############################################################
# F. TABLAS DESCRIPTIVAS COMPLETAS
############################################################
tabla1_binaria_materna <- map_dfr(
  variables_modelos,
  ~ tabla_binaria(df, .x)
)
tabla1_binaria_neonatal <- map_dfr(
  variables_neonatales,
  ~ tabla_binaria(df_neonatal, .x)
)
tabla1_bf_materna <- map_dfr(
  variables_modelos,
  ~ calcular_bf_tabla(df, .x)
)
tabla1_bf_neonatal <- map_dfr(
  variables_neonatales,
  ~ calcular_bf_tabla(df_neonatal, .x)
)
tabla1_final <- bind_rows(tabla1_binaria_materna, tabla1_binaria_neonatal) %>%
  left_join(bind_rows(tabla1_bf_materna, tabla1_bf_neonatal), by = "variable")
tabla1_continua <- bind_rows(
  tabla_continua(df, "Número Consultas prenatales") %>%
    mutate(variable = "consultas_prenatales"),
  tabla_continua(df_neonatal, "Peso al nacer GRAMOS") %>%
    mutate(variable = "peso_nacimiento_g"),
  tabla_continua(df_neonatal, "Edad gestaciol RN") %>%
    mutate(variable = "edad_gestacional_semanas")
)
# Categorías descriptivas solicitadas por el editor
tabla_rezago_categorias <- tabla_categorica(
  df,
  "categoria_rezago_escolar"
)
tabla_adecuacion_cpn_categorias <- tabla_categorica(
  df,
  "adecuacion_controles"
)
cat("=== F. DESCRIPTIVOS COMPLETOS ===\n")
print(tabla1_final, n = Inf)
print(tabla1_continua, n = Inf)
print(tabla_rezago_categorias, n = Inf)
print(tabla_adecuacion_cpn_categorias, n = Inf)
# CHECKPOINT F: guarda los descriptivos antes de entrar a la fase pesada
# (modelos Stan). Si el proceso muere más adelante (p. ej. por memoria),
# este archivo permite retomar sin recalcular los descriptivos.
saveRDS(
  list(
    tabla1_final = tabla1_final,
    tabla1_continua = tabla1_continua,
    tabla_rezago_categorias = tabla_rezago_categorias,
    tabla_adecuacion_cpn_categorias = tabla_adecuacion_cpn_categorias
  ),
  "checkpoint_F_descriptivos.rds"
)
cat("Checkpoint F guardado en:", file.path(getwd(), "checkpoint_F_descriptivos.rds"), "\n")
############################################################
# G. MODELOS PRINCIPALES
############################################################
cat("\n=== G. MODELOS PRINCIPALES ===\n")
resultados_principales <- list()
modelos_principales <- list()
# fit_plantilla: el primer modelo que compile con éxito se reutiliza (vía
# update(), sin recompilar) para el resto de las 13 variables Y para las
# 39 de sensibilidad por subperíodo en la Sección K. Ver nota en
# ajustar_pr_marginal() sobre por qué esto era necesario.
fit_plantilla <- NULL
for (v in variables_modelos) {
  t0 <- Sys.time()
  res <- ajustar_pr_marginal(
    data = df,
    outcome = v,
    iter = 6000,
    warmup = 3000,
    chains = 4,
    template_fit = fit_plantilla
  )
  if (is.null(fit_plantilla) && !is.null(res$modelo)) {
    fit_plantilla <- res$modelo
  }
  modelos_principales[[v]] <- res$modelo
  resultados_principales[[v]] <- res$resumen
  cat(
    v,
    "|",
    round(difftime(Sys.time(), t0, units = "mins"), 1),
    "min |",
    res$resumen$nota,
    "\n"
  )
  # CHECKPOINT incremental: guarda el progreso parcial de la Sección G
  # después de CADA variable, no solo al final del bucle. Si el proceso
  # muere en la variable 9 de 13, este archivo ya tiene las 8 anteriores
  # -- no hay que recompilar/remuestrear nada de lo ya hecho.
  saveRDS(
    list(
      resultados_principales = resultados_principales,
      variables_completadas = names(resultados_principales)
    ),
    "checkpoint_G_modelos_principales.rds"
  )
  # Libera memoria del ajuste anterior antes de pasar al siguiente modelo.
  # No cambia ningún resultado ya calculado (res$resumen ya quedó guardado
  # arriba); solo evita que objetos stanfit de modelos previos se acumulen
  # en memoria mientras el bucle avanza.
  rm(res)
  gc(verbose = FALSE)
}
tabla2 <- bind_rows(resultados_principales) %>%
  mutate(
    across(
      c(
        RP,
        ICr95_Low,
        ICr95_Up,
        diferencia_prevalencia,
        DP_Low,
        DP_Up
      ),
      ~ round(.x, 3)
    ),
    pd = round(pd, 4),
    Rhat_max = round(Rhat_max, 4),
    ESS_bulk_min = round(ESS_bulk_min, 0),
    ESS_tail_min = round(ESS_tail_min, 0),
    E_BFMI_min = round(E_BFMI_min, 3)
  )
cat("\n========== TABLA 2: RP MARGINALES ==========\n")
print(tabla2, n = Inf)
############################################################
# H. ESCOLARIDAD: TABLA COMPARATIVA (indicador crudo vs. ajustado)
# NOTA: el modelo ordinal cumulative-logit que existía aquí se eliminó en
# esta revisión. Con categoria_rezago_escolar reducida a 2 niveles
# (Ausente/Presente, ver justificación en el encabezado del script), un
# modelo cumulative-logit es matemáticamente equivalente a una logística
# binaria simple: ya no aporta un gradiente de severidad real, solo
# duplicaría con otra métrica (OR) la RP que ya se estima para
# rezago_escolar_bin dentro del bucle de la Sección G (variables_modelos)
# y que queda registrada en tabla2. No tiene sentido reportar OR y RP
# para el mismo contraste binario en dos tablas distintas.
############################################################
tabla_comparativa_escolaridad <- tabla2 %>%
  filter(
    variable %in%
      c("escolaridad_baja", "rezago_escolar_bin")
  ) %>%
  select(
    variable,
    n,
    eventos,
    RP,
    ICr95_Low,
    ICr95_Up,
    diferencia_prevalencia,
    DP_Low,
    DP_Up,
    pd,
    nota
  ) %>%
  mutate(
    variable = recode(
      variable,
      escolaridad_baja =
        "Nivel educativo ninguna/primaria (indicador crudo)",
      rezago_escolar_bin =
        "Rezago escolar ajustado por edad (\u22652 a\u00f1os de diferencia)"
    )
  )
############################################################
# I. ADECUACIÓN DEL CONTROL PRENATAL:
# MODELO ORDINAL Y MODELO BINARIO
############################################################
# Libera memoria acumulada de la Sección G antes de este modelo ordinal
# de 4 categorías (más pesado que los binarios del bucle anterior). Este
# fue el punto exacto donde el proceso murió sin error en la corrida
# previa -- probable presión de memoria del sistema, no del modelo en sí.
gc(verbose = FALSE)
df_adecuacion_ord <- df %>%
  filter(
    !is.na(menor15),
    !is.na(adecuacion_controles)
  ) %>%
  mutate(menor15 = as.integer(menor15))
fit_adecuacion_ordinal <- tryCatch(
  brm(
    adecuacion_controles ~ menor15,
    data = df_adecuacion_ord,
    family = cumulative(link = "logit", threshold = "flexible"),
    prior = c(
      prior(normal(0, 1.5), class = "b")
    ),
    chains = 4,
    iter = 6000,
    warmup = 3000,
    seed = 1234,
    refresh = 0,
    cores = 4,
    control = list(
      adapt_delta = 0.995,
      max_treedepth = 15
    )
  ),
  error = function(e) {
    message("ERROR modelo ordinal de adecuación prenatal: ", e$message)
    NULL
  }
)
if (is.null(fit_adecuacion_ordinal)) {
  tabla_adecuacion_ordinal <- tibble(
    variable = "Adecuación ordinal del control prenatal",
    n = nrow(df_adecuacion_ord),
    OR = NA_real_,
    ICr95_Low = NA_real_,
    ICr95_Up = NA_real_,
    pd = NA_real_,
    Rhat_max = NA_real_,
    ESS_bulk_min = NA_real_,
    ESS_tail_min = NA_real_,
    E_BFMI_min = NA_real_,
    divergencias = NA_integer_,
    treedepth_max_excedido = NA_integer_,
    nota = "No fue posible ajustar el modelo"
  )
} else {
  draws_cpn_ord <- posterior::as_draws_df(fit_adecuacion_ordinal)
  or_cpn_draws <- exp(draws_cpn_ord$b_menor15)
  # FIX: max_treedepth explícito.
  diag_cpn_ord <- extraer_diagnosticos(fit_adecuacion_ordinal, max_treedepth = 15)
  tabla_adecuacion_ordinal <- tibble(
    variable = "Adecuación ordinal del control prenatal",
    n = nrow(df_adecuacion_ord),
    OR = median(or_cpn_draws),
    ICr95_Low = unname(quantile(or_cpn_draws, 0.025)),
    ICr95_Up = unname(quantile(or_cpn_draws, 0.975)),
    pd = max(
      mean(or_cpn_draws > 1),
      mean(or_cpn_draws < 1)
    ),
    Rhat_max = diag_cpn_ord$Rhat_max,
    ESS_bulk_min = diag_cpn_ord$ESS_bulk_min,
    ESS_tail_min = diag_cpn_ord$ESS_tail_min,
    E_BFMI_min = diag_cpn_ord$E_BFMI_min,
    divergencias = diag_cpn_ord$divergencias,
    treedepth_max_excedido = diag_cpn_ord$treedepth_max_excedido,
    nota = if_else(
      diagnostico_aceptable(diag_cpn_ord),
      "Diagnósticos adecuados",
      "Revisar diagnósticos"
    )
  ) %>%
    mutate(
      across(
        c(OR, ICr95_Low, ICr95_Up),
        ~ round(.x, 3)
      ),
      pd = round(pd, 4),
      Rhat_max = round(Rhat_max, 4),
      ESS_bulk_min = round(ESS_bulk_min, 0),
      ESS_tail_min = round(ESS_tail_min, 0),
      E_BFMI_min = round(E_BFMI_min, 3)
    )
}
# CHECKPOINT I: este es el punto exacto donde murió la corrida anterior.
# Guardarlo aquí asegura que, si vuelve a fallar más adelante, ya no haga
# falta recompilar/remuestrear este modelo ordinal.
saveRDS(
  list(
    tabla_comparativa_escolaridad = tabla_comparativa_escolaridad,
    tabla_adecuacion_ordinal = tabla_adecuacion_ordinal
  ),
  "checkpoint_I_adecuacion_ordinal.rds"
)
cat("Checkpoint I guardado en:", file.path(getwd(), "checkpoint_I_adecuacion_ordinal.rds"), "\n")
rm(list = intersect(
  c("draws_cpn_ord", "or_cpn_draws", "diag_cpn_ord"),
  ls()
))
gc(verbose = FALSE)
############################################################
# J. NÚMERO DE CONSULTAS PRENATALES:
# CRUDO Y AJUSTADO POR EDAD GESTACIONAL
############################################################
df_cpn <- df %>%
  filter(
    !is.na(menor15),
    !is.na(`Número Consultas prenatales`),
    !is.na(`Edad gestaciol RN`)
  ) %>%
  transmute(
    menor15 = as.integer(menor15),
    consultas_prenatales =
      as.numeric(`Número Consultas prenatales`),
    edad_gestacional_rn =
      as.numeric(`Edad gestaciol RN`)
  )
fit_cpn_crudo <- brm(
  consultas_prenatales ~ menor15,
  data = df_cpn,
  family = gaussian(),
  prior = c(
    prior(normal(5, 3), class = "Intercept"),
    prior(normal(0, 1.5), class = "b"),
    prior(exponential(1), class = "sigma")
  ),
  chains = 4,
  iter = 4000,
  warmup = 2000,
  seed = 1234,
  refresh = 0,
  cores = 4,
  control = list(
    adapt_delta = 0.95,
    max_treedepth = 12
  )
)
fit_cpn_ajustado <- brm(
  consultas_prenatales ~ menor15 + edad_gestacional_rn,
  data = df_cpn,
  family = gaussian(),
  prior = c(
    prior(normal(5, 3), class = "Intercept"),
    prior(normal(0, 1.5), class = "b"),
    prior(normal(0, 0.5), class = "b",
          coef = "edad_gestacional_rn"),
    prior(exponential(1), class = "sigma")
  ),
  chains = 4,
  iter = 4000,
  warmup = 2000,
  seed = 1234,
  refresh = 0,
  cores = 4,
  control = list(
    adapt_delta = 0.95,
    max_treedepth = 12
  )
)
# FIX: la función original no recibía max_treedepth y dependía de la
# introspección rota de extraer_diagnosticos(). Ahora se le pasa el
# valor real usado en los brm() de arriba (max_treedepth = 12).
extraer_diferencia_cpn <- function(fit, etiqueta, n_obs, max_treedepth = 12) {
  draws <- posterior::as_draws_df(fit)
  d <- draws$b_menor15
  diag <- extraer_diagnosticos(fit, max_treedepth = max_treedepth)
  tibble(
    modelo = etiqueta,
    n = n_obs,
    diferencia_media = median(d),
    ICr95_Low = unname(quantile(d, 0.025)),
    ICr95_Up = unname(quantile(d, 0.975)),
    pd = max(mean(d > 0), mean(d < 0)),
    Rhat_max = diag$Rhat_max,
    ESS_bulk_min = diag$ESS_bulk_min,
    ESS_tail_min = diag$ESS_tail_min,
    E_BFMI_min = diag$E_BFMI_min,
    divergencias = diag$divergencias,
    treedepth_max_excedido =
      diag$treedepth_max_excedido,
    nota = if_else(
      diagnostico_aceptable(diag),
      "Diagnósticos adecuados",
      "Revisar diagnósticos"
    )
  )
}
tabla_cpn <- bind_rows(
  extraer_diferencia_cpn(
    fit_cpn_crudo,
    "No ajustado",
    nrow(df_cpn)
  ),
  extraer_diferencia_cpn(
    fit_cpn_ajustado,
    "Ajustado por edad gestacional al parto",
    nrow(df_cpn)
  )
) %>%
  mutate(
    across(
      c(diferencia_media, ICr95_Low, ICr95_Up),
      ~ round(.x, 3)
    ),
    pd = round(pd, 4),
    Rhat_max = round(Rhat_max, 4),
    ESS_bulk_min = round(ESS_bulk_min, 0),
    ESS_tail_min = round(ESS_tail_min, 0),
    E_BFMI_min = round(E_BFMI_min, 3)
  )
# CHECKPOINT J
saveRDS(tabla_cpn, "checkpoint_J_tabla_cpn.rds")
cat("Checkpoint J guardado en:", file.path(getwd(), "checkpoint_J_tabla_cpn.rds"), "\n")
# NOTA: fit_cpn_crudo y fit_cpn_ajustado NO se liberan aquí -- el bloque
# final de exportación (Sección O) los necesita intactos para el RDS
# definitivo. Solo se libera memoria de objetos intermedios desechables.
gc(verbose = FALSE)
############################################################
# K. SENSIBILIDAD POR SUBPERÍODOS
############################################################
cat("\n=== K. SENSIBILIDAD POR SUBPERÍODOS ===\n")
print(table(df$subperiodo, df$grupo_edad, useNA = "ifany"))
# Reescrito de map_dfr anidado a bucles for explícitos: la lógica y los
# valores calculados por ajustar_pr_marginal() son IDÉNTICOS al original
# (misma función, mismos argumentos, mismo orden de iteración). El único
# cambio es que ahora, después de CADA una de las 39 combinaciones
# subperíodo × variable, se guarda un checkpoint y se libera memoria. Con
# map_dfr no había forma de insertar esto sin cambiar la estructura del
# código a un bucle explícito.
resultados_sensibilidad <- list()
for (periodo_actual in levels(df$subperiodo)) {
  sub <- df %>% filter(subperiodo == periodo_actual)
  for (v in variables_modelos) {
    clave <- paste(periodo_actual, v, sep = "__")
    res_sens <- ajustar_pr_marginal(
      data = sub,
      outcome = v,
      iter = 6000,
      warmup = 3000,
      chains = 4,
      adapt_delta = 0.995,
      max_treedepth = 15,
      template_fit = fit_plantilla
    )$resumen %>%
      mutate(subperiodo = periodo_actual)
    resultados_sensibilidad[[clave]] <- res_sens
    cat(
      periodo_actual, "|", v, "|",
      res_sens$nota, "\n"
    )
    # CHECKPOINT incremental K: uno de los 39. Si el proceso muere en la
    # combinación 25 de 39, las primeras 24 ya quedaron en disco.
    saveRDS(
      resultados_sensibilidad,
      "checkpoint_K_sensibilidad.rds"
    )
    rm(res_sens)
    gc(verbose = FALSE)
  }
}
sensibilidad <- bind_rows(resultados_sensibilidad) %>%
  relocate(subperiodo, .before = variable) %>%
  mutate(
    across(
      c(
        RP,
        ICr95_Low,
        ICr95_Up,
        diferencia_prevalencia,
        DP_Low,
        DP_Up
      ),
      ~ round(.x, 3)
    ),
    pd = round(pd, 4),
    Rhat_max = round(Rhat_max, 4),
    ESS_bulk_min = round(ESS_bulk_min, 0),
    ESS_tail_min = round(ESS_tail_min, 0),
    E_BFMI_min = round(E_BFMI_min, 3)
  )
cat("\n========== SENSIBILIDAD COMPLETA ==========\n")
print(sensibilidad, n = Inf)
############################################################
# L. DATOS FALTANTES
############################################################
vars_faltantes <- unique(c(
  variables_modelos,
  variables_neonatales,
  "categoria_rezago_escolar",
  "adecuacion_controles",
  "Número Consultas prenatales",
  "Edad gestaciol RN",
  "Peso al nacer GRAMOS"
))
tabla_faltantes <- tibble(variable = vars_faltantes) %>%
  mutate(
    n_total = nrow(df),
    n_faltante = map_int(
      variable,
      ~ sum(is.na(df[[.x]]))
    ),
    pct_faltante =
      100 * n_faltante / n_total
  ) %>%
  arrange(desc(pct_faltante)) %>%
  mutate(pct_faltante = round(pct_faltante, 2))
############################################################
# M. RECONCILIACIÓN BF10 Y RP
# Mantener solo como análisis suplementario.
############################################################
bf_modelos <- map_dfr(
  variables_modelos,
  ~ calcular_bf_tabla(df, .x)
)
reconciliacion <- tabla2 %>%
  select(
    variable,
    RP,
    ICr95_Low,
    ICr95_Up,
    pd
  ) %>%
  left_join(bf_modelos, by = "variable") %>%
  mutate(
    lectura_BF10 = case_when(
      is.na(BF10) ~ NA_character_,
      BF10 < 1 / 3 ~ "Evidencia a favor de H0",
      BF10 < 1 ~ "Evidencia débil a favor de H0",
      BF10 < 3 ~ "Evidencia inconclusa",
      BF10 < 10 ~ "Evidencia moderada a favor de diferencia",
      TRUE ~ "Evidencia fuerte a favor de diferencia"
    ),
    lectura_RP = case_when(
      is.na(ICr95_Low) | is.na(ICr95_Up) ~ NA_character_,
      ICr95_Low > 1 | ICr95_Up < 1 ~
        "ICr95% excluye 1",
      TRUE ~
        "ICr95% incluye 1"
    ),
    discrepante = case_when(
      is.na(BF10) | is.na(ICr95_Low) | is.na(ICr95_Up) ~ NA,
      BF10 < 1 & (ICr95_Low > 1 | ICr95_Up < 1) ~ TRUE,
      BF10 >= 3 & !(ICr95_Low > 1 | ICr95_Up < 1) ~ TRUE,
      TRUE ~ FALSE
    )
  )
############################################################
# N. TABLA RESUMEN DE COMPLETITUD
############################################################
tabla_completitud <- tibble(
  componente = c(
    "Modelos principales",
    "Rezago escolar binario",
    "Categorías descriptivas de rezago (2 niveles: Ausente/Presente)",
    "Adecuación del control prenatal descriptiva",
    "Adecuación del control prenatal ordinal",
    "Sensibilidad 2009–2014",
    "Sensibilidad 2015–2019",
    "Sensibilidad 2020–2024",
    "ESS_bulk y ESS_tail",
    "E-BFMI"
  ),
  criterio = c(
    all(tabla2$nota == "Diagnósticos adecuados"),
    any(tabla2$variable == "rezago_escolar_bin" &
          tabla2$nota == "Diagnósticos adecuados"),
    nrow(tabla_rezago_categorias) == 2,
    nrow(tabla_adecuacion_cpn_categorias) == 4,
    !is.na(tabla_adecuacion_ordinal$OR) &
      tabla_adecuacion_ordinal$nota == "Diagnósticos adecuados",
    all(
      sensibilidad$nota[
        sensibilidad$subperiodo == "2009–2014"
      ] == "Diagnósticos adecuados"
    ),
    all(
      sensibilidad$nota[
        sensibilidad$subperiodo == "2015–2019"
      ] == "Diagnósticos adecuados"
    ),
    all(
      sensibilidad$nota[
        sensibilidad$subperiodo == "2020–2024"
      ] == "Diagnósticos adecuados"
    ),
    all(
      is.finite(tabla2$ESS_bulk_min) &
        is.finite(tabla2$ESS_tail_min)
    ),
    all(!is.na(tabla2$E_BFMI_min))
  ),
  estado = if_else(criterio, "Completo", "Revisar")
)
############################################################
# O. EXPORTACIÓN
############################################################
wb <- createWorkbook()
addWorksheet(wb, "Tabla1_binaria")
writeData(wb, "Tabla1_binaria", tabla1_final)
addWorksheet(wb, "Tabla1_continua")
writeData(wb, "Tabla1_continua", tabla1_continua)
addWorksheet(wb, "Rezago_categorias")
writeData(wb, "Rezago_categorias", tabla_rezago_categorias)
addWorksheet(wb, "Adecuacion_CPN_categorias")
writeData(
  wb,
  "Adecuacion_CPN_categorias",
  tabla_adecuacion_cpn_categorias
)
addWorksheet(wb, "Tabla2_RP_marginal")
writeData(wb, "Tabla2_RP_marginal", tabla2)
addWorksheet(wb, "Comparativa_escolaridad")
writeData(
  wb,
  "Comparativa_escolaridad",
  tabla_comparativa_escolaridad
)
addWorksheet(wb, "Adecuacion_CPN_ordinal")
writeData(
  wb,
  "Adecuacion_CPN_ordinal",
  tabla_adecuacion_ordinal
)
addWorksheet(wb, "CPN_crudo_ajustado")
writeData(wb, "CPN_crudo_ajustado", tabla_cpn)
addWorksheet(wb, "Sensibilidad_subperiodo")
writeData(
  wb,
  "Sensibilidad_subperiodo",
  sensibilidad
)
addWorksheet(wb, "Faltantes")
writeData(wb, "Faltantes", tabla_faltantes)
addWorksheet(wb, "Reconciliacion_BF_RP")
writeData(
  wb,
  "Reconciliacion_BF_RP",
  reconciliacion
)
addWorksheet(wb, "Completitud")
writeData(wb, "Completitud", tabla_completitud)
saveWorkbook(
  wb,
  "resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx",
  overwrite = TRUE
)
saveRDS(
  list(
    df = df,
    tabla1_final = tabla1_final,
    tabla1_continua = tabla1_continua,
    tabla_rezago_categorias = tabla_rezago_categorias,
    tabla_adecuacion_cpn_categorias =
      tabla_adecuacion_cpn_categorias,
    tabla2 = tabla2,
    tabla_comparativa_escolaridad =
      tabla_comparativa_escolaridad,
    tabla_adecuacion_ordinal =
      tabla_adecuacion_ordinal,
    tabla_cpn = tabla_cpn,
    sensibilidad = sensibilidad,
    tabla_faltantes = tabla_faltantes,
    reconciliacion = reconciliacion,
    tabla_completitud = tabla_completitud,
    modelos_principales = modelos_principales,
    fit_adecuacion_ordinal = fit_adecuacion_ordinal,
    fit_cpn_crudo = fit_cpn_crudo,
    fit_cpn_ajustado = fit_cpn_ajustado
  ),
  "resultados_RBSMI_DEFINITIVO_CORREGIDO.rds"
)
cat("\n============================================================\n")
cat("PIPELINE FINALIZADO\n")
cat("Archivos generados:\n")
cat("- resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx\n")
cat("- resultados_RBSMI_DEFINITIVO_CORREGIDO.rds\n\n")
print(tabla_completitud)
cat("============================================================\n")

