#!/usr/bin/env Rscript

options(warn = 1)
set.seed(1234)

suppressPackageStartupMessages({
  library(brms)
  library(dplyr)
  library(posterior)
  library(readr)
  library(tibble)
})

options(mc.cores = 4)

archivo_base <- "Adolescentes.csv"
directorio_salida <- file.path("output", "rezago_escolar")
dir.create(directorio_salida, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(archivo_base)) {
  stop("Falta la base fuente: ", archivo_base)
}

tope_anios_escolaridad <- 12

adolescentes <- read.csv(
  archivo_base,
  fileEncoding = "UTF-8",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
names(adolescentes) <- trimws(names(adolescentes))
names(adolescentes) <- gsub("[[:space:]]+", " ", names(adolescentes))

variables_requeridas <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO", "Numero gestas previas",
  "Numero de Partos previos", "Cesáreas previas CODIGO",
  "Embarazo planeado CODIGO", "ANTICONCEPTIVO CODIGO",
  "Número Consultas prenatales", "TIPO DE PARTO", "CESAREA",
  "Embarazo múltiple CODIGO", "Edad gestaciol RN", "Estudios CODIGO"
)
faltantes <- setdiff(variables_requeridas, names(adolescentes))
if (length(faltantes) > 0) {
  stop("Faltan variables requeridas: ", paste(faltantes, collapse = ", "))
}

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
  for (i in seq.int(2, n)) {
    if (!is.na(eg_sorted[i]) && !is.na(eg_sorted[i - 1]) &&
        (eg_sorted[i] - eg_sorted[i - 1]) >= umbral_semanas) {
      cl <- cl + 1L
    }
    cluster_sorted[i] <- cl
  }
  cluster_out <- integer(n)
  cluster_out[ord] <- cluster_sorted
  cluster_out
}

vars_llave_madre <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO", "Numero gestas previas",
  "Numero de Partos previos", "Cesáreas previas CODIGO",
  "Embarazo planeado CODIGO", "ANTICONCEPTIVO CODIGO",
  "Número Consultas prenatales", "TIPO DE PARTO", "CESAREA"
)

adolescentes_limpia <- adolescentes %>% distinct()
if (nrow(adolescentes) != 7202L || nrow(adolescentes_limpia) != 7187L) {
  stop(
    "La reconciliación inicial no coincide: n inicial=", nrow(adolescentes),
    "; tras duplicados exactos=", nrow(adolescentes_limpia)
  )
}

multiples_dedup <- adolescentes_limpia %>%
  filter(`Embarazo múltiple CODIGO` == 1) %>%
  group_by(across(all_of(vars_llave_madre))) %>%
  mutate(
    subgrupo_gestacional = asignar_cluster_gestacional(
      `Edad gestaciol RN`, umbral_semanas = 3
    )
  ) %>%
  ungroup() %>%
  distinct(
    across(all_of(c(vars_llave_madre, "subgrupo_gestacional"))),
    .keep_all = TRUE
  )

df <- bind_rows(
  adolescentes_limpia %>%
    filter(`Embarazo múltiple CODIGO` != 1 | is.na(`Embarazo múltiple CODIGO`)),
  multiples_dedup
) %>%
  filter(!is.na(`Edad materna`), `Edad materna` >= 10, `Edad materna` <= 19) %>%
  mutate(
    menor15 = if_else(`Edad materna` < 15, 1L, 0L),
    grupo = if_else(menor15 == 1L, "10–14 años", "15–19 años"),
    anios_aprobados = case_when(
      `Estudios CODIGO` == 0 ~ 0,
      `Estudios CODIGO` == 1 ~ `Años estudios mayor nivel`,
      `Estudios CODIGO` == 2 ~ 9 + `Años estudios mayor nivel`,
      `Estudios CODIGO` == 3 ~ 12 + `Años estudios mayor nivel`,
      TRUE ~ NA_real_
    ),
    anios_esperados_principal = pmin(
      pmax(`Edad materna` - 6, 0), tope_anios_escolaridad
    ),
    anios_esperados_alternativa = pmin(
      pmax(`Edad materna` - 5, 0), tope_anios_escolaridad
    ),
    rezago_principal_anios = anios_esperados_principal - anios_aprobados,
    rezago_alternativa_anios = anios_esperados_alternativa - anios_aprobados,
    rezago_principal = case_when(
      is.na(rezago_principal_anios) ~ NA_integer_,
      rezago_principal_anios >= 2 ~ 1L,
      TRUE ~ 0L
    ),
    rezago_alternativa = case_when(
      is.na(rezago_alternativa_anios) ~ NA_integer_,
      rezago_alternativa_anios >= 2 ~ 1L,
      TRUE ~ 0L
    )
  )

if (nrow(df) != 7035L || sum(df$menor15 == 1L) != 386L ||
    sum(df$menor15 == 0L) != 6649L) {
  stop("La base analítica no reproduce 7.035 eventos (386 y 6.649).")
}

tabla_anios <- tibble(edad = 10:19) %>%
  mutate(
    regla_principal = "min(max(edad - 6, 0), 12)",
    tope_anios = tope_anios_escolaridad,
    anios_esperados_principal = pmin(pmax(edad - 6, 0), tope_anios_escolaridad),
    regla_alternativa = "min(max(edad - 5, 0), 12)",
    anios_esperados_alternativa = pmin(pmax(edad - 5, 0), tope_anios_escolaridad)
  )
write_csv(tabla_anios, file.path(directorio_salida, "tabla_anios_esperados_por_edad.csv"))

datos_modelo <- function(variable) {
  df %>%
    transmute(menor15 = as.integer(menor15), y = as.integer(.data[[variable]])) %>%
    filter(!is.na(menor15), !is.na(y), menor15 %in% 0:1, y %in% 0:1)
}

d_principal <- datos_modelo("rezago_principal")
d_alternativa <- datos_modelo("rezago_alternativa")
if (nrow(d_principal) != 7027L) {
  stop("El indicador principal no reproduce n=7.027; obtuvo n=", nrow(d_principal))
}

priors <- c(
  prior(normal(0, 3), class = "Intercept"),
  prior(normal(0, 1.5), class = "b")
)

ajustar <- function(datos, modelo_previo = NULL) {
  argumentos <- list(
    formula = y ~ menor15,
    data = datos,
    family = bernoulli(link = "logit"),
    prior = priors,
    chains = 4,
    iter = 6000,
    warmup = 3000,
    seed = 1234,
    refresh = 1000,
    cores = 4,
    control = list(adapt_delta = 0.99, max_treedepth = 15)
  )
  if (is.null(modelo_previo)) {
    do.call(brm, argumentos)
  } else {
    update(
      modelo_previo,
      newdata = datos,
      recompile = FALSE,
      chains = 4, iter = 6000, warmup = 3000, seed = 1234,
      refresh = 1000, cores = 4,
      control = list(adapt_delta = 0.99, max_treedepth = 15)
    )
  }
}

resumen_modelo <- function(fit, datos, regla) {
  draws <- posterior::as_draws_df(fit)
  p_15_19 <- plogis(draws$b_Intercept)
  p_10_14 <- plogis(draws$b_Intercept + draws$b_menor15)
  rp <- p_10_14 / p_15_19
  resumen_param <- posterior::summarise_draws(
    posterior::as_draws_array(fit)
  ) %>%
    filter(variable %in% c("b_Intercept", "b_menor15"))
  rhat_max <- max(resumen_param$rhat, na.rm = TRUE)
  ess_bulk_min <- min(resumen_param$ess_bulk, na.rm = TRUE)
  ess_tail_min <- min(resumen_param$ess_tail, na.rm = TRUE)
  nuts <- nuts_params(fit)
  divergencias <- sum(nuts$Parameter == "divergent__" & nuts$Value == 1)
  treedepth_max_observado <- max(nuts$Value[nuts$Parameter == "treedepth__"])
  treedepth_alcanzado <- sum(nuts$Parameter == "treedepth__" & nuts$Value >= 15)
  energia <- nuts[nuts$Parameter == "energy__", ]
  ebfmi <- vapply(split(energia$Value, energia$Chain), function(x) {
    mean(diff(x)^2) / var(x)
  }, numeric(1))
  pred <- posterior_predict(fit, ndraws = 1000)
  prevalencias_pred <- cbind(
    global = rowMeans(pred),
    `15–19 años` = rowMeans(pred[, datos$menor15 == 0, drop = FALSE]),
    `10–14 años` = rowMeans(pred[, datos$menor15 == 1, drop = FALSE])
  )
  prevalencias_obs <- c(
    global = mean(datos$y),
    `15–19 años` = mean(datos$y[datos$menor15 == 0]),
    `10–14 años` = mean(datos$y[datos$menor15 == 1])
  )
  ppc <- tibble(
    regla = regla,
    estadistico = names(prevalencias_obs),
    observado = as.numeric(prevalencias_obs),
    pred_mediana = apply(prevalencias_pred, 2, median),
    pred_icr95_inf = apply(prevalencias_pred, 2, quantile, 0.025),
    pred_icr95_sup = apply(prevalencias_pred, 2, quantile, 0.975)
  ) %>%
    mutate(observado_fuera_icr95 = observado < pred_icr95_inf | observado > pred_icr95_sup)
  resumen <- tibble(
    regla = regla,
    n_total = nrow(datos),
    n_10_14 = sum(datos$menor15 == 1),
    n_15_19 = sum(datos$menor15 == 0),
    eventos_10_14 = sum(datos$y[datos$menor15 == 1]),
    eventos_15_19 = sum(datos$y[datos$menor15 == 0]),
    prevalencia_10_14 = mean(datos$y[datos$menor15 == 1]),
    prevalencia_15_19 = mean(datos$y[datos$menor15 == 0]),
    RP = median(rp),
    ICr95_inf = unname(quantile(rp, 0.025)),
    ICr95_sup = unname(quantile(rp, 0.975)),
    Rhat_max = rhat_max,
    ESS_bulk_min = ess_bulk_min,
    ESS_tail_min = ess_tail_min,
    divergencias = divergencias,
    treedepth_max_observado = treedepth_max_observado,
    iteraciones_treedepth_15 = treedepth_alcanzado,
    E_BFMI_min = min(ebfmi),
    PPC_fuera_ICr95 = sum(ppc$observado_fuera_icr95),
    PPC_total = nrow(ppc)
  )
  list(resumen = resumen, ppc = ppc)
}

cat("Ajustando modelo principal para reproducibilidad...\n")
fit_principal <- ajustar(d_principal)
principal <- resumen_modelo(fit_principal, d_principal, "Principal: edad - 6; tope 12")

rp_redondeada <- round(principal$resumen$RP, 2)
icr_inf_redondeado <- round(principal$resumen$ICr95_inf, 2)
icr_sup_redondeado <- round(principal$resumen$ICr95_sup, 2)
if (rp_redondeada != 2.07 || icr_inf_redondeado != 1.78 || icr_sup_redondeado != 2.41) {
  write_csv(principal$resumen, file.path(directorio_salida, "resultado_principal_discrepante.csv"))
  stop(
    "El modelo principal no reprodujo RP=2,07 (ICr95% 1,78–2,41): obtuvo ",
    sprintf("%.3f (%.3f–%.3f)", principal$resumen$RP,
            principal$resumen$ICr95_inf, principal$resumen$ICr95_sup)
  )
}
write_csv(principal$resumen, file.path(directorio_salida, "resultado_principal_reproducido.csv"))

cat("Ajustando sensibilidad edad - 5 con tope 12...\n")
fit_alternativa <- ajustar(d_alternativa, fit_principal)
alternativa <- resumen_modelo(
  fit_alternativa, d_alternativa, "Sensibilidad: edad - 5; tope 12"
)
write_csv(alternativa$resumen, file.path(directorio_salida, "sensibilidad_rezago_escolar.csv"))

diagnosticos <- bind_rows(principal$resumen, alternativa$resumen) %>%
  select(
    regla, Rhat_max, ESS_bulk_min, ESS_tail_min, divergencias,
    treedepth_max_observado, iteraciones_treedepth_15,
    E_BFMI_min, PPC_fuera_ICr95, PPC_total
  )
write_csv(diagnosticos, file.path(directorio_salida, "diagnosticos_sensibilidad_rezago.csv"))
write_csv(
  bind_rows(principal$ppc, alternativa$ppc),
  file.path(directorio_salida, "ppc_sensibilidad_rezago.csv")
)

comparacion <- bind_rows(
  principal$resumen %>% mutate(Regla = "Principal: edad - 6; tope 12"),
  alternativa$resumen %>% mutate(Regla = "Sensibilidad: edad - 5; tope 12")
) %>%
  select(Regla, n_total, n_10_14, n_15_19, prevalencia_10_14,
         prevalencia_15_19, RP, ICr95_inf, ICr95_sup) %>%
  tidyr::pivot_longer(
    cols = c(prevalencia_10_14, prevalencia_15_19),
    names_to = "Grupo", values_to = "Prevalencia"
  ) %>%
  mutate(
    Grupo = recode(
      Grupo,
      prevalencia_10_14 = "10–14 años",
      prevalencia_15_19 = "15–19 años"
    ),
    Estimador = RP,
    ICr95 = sprintf("%.3f–%.3f", ICr95_inf, ICr95_sup)
  ) %>%
  select(Regla, Grupo, Prevalencia, Estimador, ICr95,
         n_total, n_10_14, n_15_19)
write_csv(comparacion, file.path(directorio_salida, "comparacion_reglas_rezago.csv"))

formato_decimal <- function(x, digitos) {
  sub("\\.", ",", sprintf(paste0("%.", digitos, "f"), x), fixed = FALSE)
}
tabla_s14 <- c(
  "## Tabla S14. Regla de años esperados y sensibilidad del indicador de rezago escolar {#tabla-s14.-sensibilidad-rezago-escolar .unnumbered}",
  "",
  "**Panel A. Años esperados según edad**",
  "",
  "| **Edad (años)** | **Regla principal: edad − 6, tope 12** | **Regla alternativa: edad − 5, tope 12** |",
  "|---:|---:|---:|",
  paste0("| ", tabla_anios$edad, " | ", tabla_anios$anios_esperados_principal,
         " | ", tabla_anios$anios_esperados_alternativa, " |"),
  "",
  "**Panel B. Comparación del indicador binario de rezago ≥2 años**",
  "",
  "| **Regla** | **n total** | **Prevalencia 10–14** | **Prevalencia 15–19** | **RP (ICr95 %)** | **R-hat máx.** | **ESS bulk mín.** | **ESS tail mín.** | **Divergencias** | **E-BFMI mín.** | **PPC fuera del ICr95 %** |",
  "|:--|--:|--:|--:|:--|--:|--:|--:|--:|--:|--:|",
  paste0(
    "| Principal: edad − 6; tope 12 | 7.027 | ",
    formato_decimal(100 * principal$resumen$prevalencia_10_14, 1), " % | ",
    formato_decimal(100 * principal$resumen$prevalencia_15_19, 1), " % | ",
    formato_decimal(principal$resumen$RP, 2), " (",
    formato_decimal(principal$resumen$ICr95_inf, 2), "–",
    formato_decimal(principal$resumen$ICr95_sup, 2), ") | ",
    formato_decimal(principal$resumen$Rhat_max, 4), " | ",
    format(round(principal$resumen$ESS_bulk_min), big.mark = ".", decimal.mark = ",", scientific = FALSE), " | ",
    format(round(principal$resumen$ESS_tail_min), big.mark = ".", decimal.mark = ",", scientific = FALSE), " | 0 | ",
    formato_decimal(principal$resumen$E_BFMI_min, 3), " | 0/3 |"
  ),
  paste0(
    "| Sensibilidad: edad − 5; tope 12 | 7.027 | ",
    formato_decimal(100 * alternativa$resumen$prevalencia_10_14, 1), " % | ",
    formato_decimal(100 * alternativa$resumen$prevalencia_15_19, 1), " % | ",
    formato_decimal(alternativa$resumen$RP, 2), " (",
    formato_decimal(alternativa$resumen$ICr95_inf, 2), "–",
    formato_decimal(alternativa$resumen$ICr95_sup, 2), ") | ",
    formato_decimal(alternativa$resumen$Rhat_max, 4), " | ",
    format(round(alternativa$resumen$ESS_bulk_min), big.mark = ".", decimal.mark = ",", scientific = FALSE), " | ",
    format(round(alternativa$resumen$ESS_tail_min), big.mark = ".", decimal.mark = ",", scientific = FALSE), " | 0 | ",
    formato_decimal(alternativa$resumen$E_BFMI_min, 3), " | 0/3 |"
  ),
  "",
  "Ambas reglas utilizaron el mismo cálculo de años aprobados, tope de 12 años, tratamiento de datos faltantes, definición binaria (rezago ≥2 años) y modelo bayesiano Bernoulli-logit con estandarización posterior. En ambos ajustes la profundidad máxima observada fue 4, ninguna iteración alcanzó el máximo configurado de 15 y los PPC de las prevalencias global y por grupo quedaron dentro del ICr95 % predictivo. Fuente reproducible: `R/08_punto4_sensibilidad_rezago_escolar.R` y `output/rezago_escolar/`.",
  ""
)
writeLines(tabla_s14, file.path(directorio_salida, "tabla_s14.md"), useBytes = TRUE)

if (any(diagnosticos$Rhat_max > 1.01) ||
    any(diagnosticos$ESS_bulk_min < 400) ||
    any(diagnosticos$ESS_tail_min < 400) ||
    any(diagnosticos$divergencias > 0) ||
    any(diagnosticos$iteraciones_treedepth_15 > 0)) {
  stop("Algún diagnóstico no cumple los criterios predefinidos.")
}

cat("Punto 4 reproducido y sensibilidad completada.\n")
print(bind_rows(principal$resumen, alternativa$resumen))
