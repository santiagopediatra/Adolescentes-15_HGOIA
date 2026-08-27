#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(brms)
  library(posterior)
})

set.seed(1234)
options(mc.cores = 4)

dir.create("output/prenatal", recursive = TRUE, showWarnings = FALSE)

archivo_base <- "Adolescentes.csv"
archivo_resultados <- "resultados_RBSMI_DEFINITIVO_CORREGIDO.rds"
stopifnot(file.exists(archivo_base), file.exists(archivo_resultados))

# Reproduce la depuración materna que usa el análisis principal.
datos_crudos <- read.csv(
  archivo_base,
  fileEncoding = "UTF-8",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
names(datos_crudos) <- trimws(names(datos_crudos))
names(datos_crudos) <- gsub("[[:space:]]+", " ", names(datos_crudos))

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

datos_limpios <- datos_crudos %>% distinct()
datos_multiples <- datos_limpios %>%
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
  datos_limpios %>%
    filter(`Embarazo múltiple CODIGO` != 1 |
             is.na(`Embarazo múltiple CODIGO`)),
  datos_multiples
) %>%
  filter(!is.na(`Edad materna`), `Edad materna` >= 10, `Edad materna` <= 19) %>%
  mutate(
    menor15 = if_else(`Edad materna` < 15, 1L, 0L),
    grupo_edad = factor(
      if_else(menor15 == 1L, "10–14 años", "15–19 años"),
      levels = c("15–19 años", "10–14 años")
    ),
    # Regla operacional exacta encontrada en el pipeline vigente.
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
      levels = c("Sin controles", "Inadecuado", "Intermedio", "Adecuado"),
      ordered = TRUE
    ),
    adecuacion_adecuada_bin = if_else(
      is.na(adecuacion_controles),
      NA_integer_,
      as.integer(adecuacion_controles == "Adecuado")
    )
  )

objetos <- readRDS(archivo_resultados)
stopifnot(nrow(df) == nrow(objetos$df), nrow(df) == 7035)

# Comprobación fuerte: la recreación debe coincidir fila a fila con las
# variables prenatales guardadas por el pipeline que produjo las tablas.
vars_verificacion <- c(
  "menor15", "controles_esperados", "proporcion_controles",
  "adecuacion_controles", "adecuacion_adecuada_bin"
)
for (v in vars_verificacion) {
  stopifnot(isTRUE(all.equal(df[[v]], objetos$df[[v]], check.attributes = FALSE)))
}

regla <- tibble(
  intervalo_edad_gestacional = c(
    "<20 semanas", "20–<26 semanas", "26–<30 semanas",
    "30–<34 semanas", "34–<36 semanas", "36–<38 semanas",
    "38–<40 semanas", "≥40 semanas"
  ),
  limite_inferior_semanas = c(NA, 20, 26, 30, 34, 36, 38, 40),
  limite_superior_exclusivo_semanas = c(20, 26, 30, 34, 36, 38, 40, NA),
  contactos_esperados = 1:8,
  fundamento = paste(
    "Operacionalización del esquema OMS de ocho contactos usada en el",
    "pipeline vigente; hitos acumulativos: <20, 20, 26, 30, 34, 36, 38 y 40 semanas"
  )
)
write.csv(regla, "output/prenatal/regla_contactos_esperados.csv", row.names = FALSE)

categorias <- df %>%
  filter(!is.na(adecuacion_controles)) %>%
  count(grupo_edad, adecuacion_controles, name = "n") %>%
  group_by(grupo_edad) %>%
  mutate(n_valido = sum(n), porcentaje = 100 * n / n_valido) %>%
  ungroup() %>%
  rename(categoria = adecuacion_controles)
write.csv(
  categorias,
  "output/prenatal/adecuacion_categorias_por_grupo.csv",
  row.names = FALSE
)

resumen_parametro <- function(fit, parametro) {
  draws <- as_draws_array(fit)
  summ <- summarise_draws(
    draws[, , parametro, drop = FALSE],
    mean = mean,
    median = median,
    sd = sd,
    ICr95_inferior = ~ quantile(.x, 0.025),
    ICr95_superior = ~ quantile(.x, 0.975),
    rhat = rhat,
    ess_bulk = ess_bulk,
    ess_tail = ess_tail
  )
  as_tibble(summ) %>%
    rename(
      ICr95_inferior = `2.5%`,
      ICr95_superior = `97.5%`
    )
}

calcular_ebfmi_por_cadena <- function(fit) {
  brms::nuts_params(fit) %>%
    filter(Parameter == "energy__") %>%
    arrange(Chain, Iteration) %>%
    group_by(Chain) %>%
    summarise(
      E_BFMI = mean(diff(Value)^2, na.rm = TRUE) / var(Value, na.rm = TRUE),
      .groups = "drop"
    )
}

diagnosticos_globales <- function(fit, max_treedepth) {
  np <- brms::nuts_params(fit)
  todos <- summarise_draws(
    as_draws_array(fit),
    rhat = rhat,
    ess_bulk = ess_bulk,
    ess_tail = ess_tail
  )
  tibble(
    Rhat_max = max(todos$rhat, na.rm = TRUE),
    ESS_bulk_min = min(todos$ess_bulk, na.rm = TRUE),
    ESS_tail_min = min(todos$ess_tail, na.rm = TRUE),
    divergencias = sum(np$Parameter == "divergent__" & np$Value == 1),
    max_treedepth_configurado = max_treedepth,
    treedepth_observado_max = max(np$Value[np$Parameter == "treedepth__"]),
    transiciones_en_max_treedepth = sum(
      np$Parameter == "treedepth__" & np$Value >= max_treedepth
    ),
    E_BFMI_min = min(calcular_ebfmi_por_cadena(fit)$E_BFMI)
  )
}

# Análisis principal binario: se extrae del ajuste Bernoulli-logit vigente.
fit_bin <- objetos$modelos_principales$adecuacion_adecuada_bin
stopifnot(inherits(fit_bin, "brmsfit"))
draws_bin <- as_draws_df(fit_bin)
p_ref <- plogis(draws_bin$b_Intercept)
p_exp <- plogis(draws_bin$b_Intercept + draws_bin$b_menor15)
rp <- p_exp / p_ref
dp <- p_exp - p_ref
diag_bin <- diagnosticos_globales(fit_bin, 15)
modelo_bin <- tibble(
  analisis = "Control prenatal adecuado: sí/no",
  definicion_evento = "Adecuado = proporción observados/esperados ≥80%",
  grupo_comparacion = "10–14 vs 15–19 años",
  familia_enlace = "Bernoulli-logit",
  n = sum(!is.na(df$adecuacion_adecuada_bin)),
  eventos = sum(df$adecuacion_adecuada_bin == 1, na.rm = TRUE),
  RP = median(rp),
  RP_ICr95_inferior = unname(quantile(rp, 0.025)),
  RP_ICr95_superior = unname(quantile(rp, 0.975)),
  DP = median(dp),
  DP_ICr95_inferior = unname(quantile(dp, 0.025)),
  DP_ICr95_superior = unname(quantile(dp, 0.975)),
  pd = max(mean(rp > 1), mean(rp < 1))
) %>% bind_cols(diag_bin)
write.csv(
  modelo_bin,
  "output/prenatal/modelo_adecuacion_binaria.csv",
  row.names = FALSE
)

# Análisis secundario ordinal y thresholds completos.
fit_ord <- objetos$fit_adecuacion_ordinal
stopifnot(inherits(fit_ord, "brmsfit"))
coef_ord <- resumen_parametro(fit_ord, "b_menor15")
or_ord_draws <- exp(as_draws_df(fit_ord)$b_menor15)
diag_ord <- diagnosticos_globales(fit_ord, 15)
modelo_ord <- tibble(
  analisis = "Adecuación ordinal del control prenatal",
  niveles = "Sin controles < Inadecuado < Intermedio < Adecuado",
  grupo_comparacion = "10–14 vs 15–19 años",
  familia_enlace = "cumulative-logit; thresholds flexibles",
  n = sum(!is.na(df$adecuacion_controles)),
  coeficiente_log_odds = coef_ord$median,
  coeficiente_ICr95_inferior = coef_ord$ICr95_inferior,
  coeficiente_ICr95_superior = coef_ord$ICr95_superior,
  OR_acumulativa = median(or_ord_draws),
  OR_ICr95_inferior = unname(quantile(or_ord_draws, 0.025)),
  OR_ICr95_superior = unname(quantile(or_ord_draws, 0.975)),
  Rhat_coeficiente = coef_ord$rhat,
  ESS_bulk_coeficiente = coef_ord$ess_bulk,
  ESS_tail_coeficiente = coef_ord$ess_tail
) %>% bind_cols(diag_ord)
write.csv(
  modelo_ord,
  "output/prenatal/modelo_adecuacion_ordinal.csv",
  row.names = FALSE
)

nombres_thresholds <- variables(fit_ord)[grepl("^b_Intercept\\[", variables(fit_ord))]
stopifnot(length(nombres_thresholds) == 3)
thresholds <- bind_rows(lapply(nombres_thresholds, function(p) {
  resumen_parametro(fit_ord, p) %>%
    transmute(
      parametro = variable,
      threshold = sub("^b_Intercept\\[([0-9]+)\\]$", "\\1", variable),
      media = mean,
      mediana = median,
      DE = sd,
      ICr95_inferior,
      ICr95_superior,
      Rhat = rhat,
      ESS_bulk = ess_bulk,
      ESS_tail = ess_tail
    )
}))
write.csv(
  thresholds,
  "output/prenatal/thresholds_adecuacion_ordinal.csv",
  row.names = FALSE
)

diag_cadenas <- calcular_ebfmi_por_cadena(fit_ord) %>%
  mutate(tipo = "por_cadena") %>%
  rename(cadena = Chain, valor = E_BFMI) %>%
  mutate(metrica = "E_BFMI") %>%
  select(tipo, metrica, cadena, valor)
diag_largo <- diag_ord %>%
  pivot_longer(everything(), names_to = "metrica", values_to = "valor") %>%
  mutate(tipo = "global", cadena = NA_integer_) %>%
  select(tipo, metrica, cadena, valor) %>%
  bind_rows(diag_cadenas)
write.csv(
  diag_largo,
  "output/prenatal/diagnosticos_adecuacion_ordinal.csv",
  row.names = FALSE
)

# Evaluación empírica del supuesto de odds proporcionales mediante tres
# modelos Bernoulli-logit acumulativos, con la misma orientación que el
# coeficiente común ordinal: 1 = pertenecer a categorías superiores.
datos_ord <- df %>%
  filter(!is.na(menor15), !is.na(adecuacion_controles)) %>%
  transmute(menor15, categoria_num = as.integer(adecuacion_controles))

cortes <- tibble(
  corte_num = 1:3,
  punto_corte = c(
    "Sin controles vs categorías superiores",
    "Sin controles + inadecuado vs intermedio + adecuado",
    "Sin controles + inadecuado + intermedio vs adecuado"
  )
)

ajustar_corte <- function(k, etiqueta, plantilla) {
  d <- datos_ord %>% transmute(menor15, y = as.integer(categoria_num > k))
  fit <- update(
    plantilla,
    formula = y ~ menor15,
    newdata = d,
    recompile = FALSE,
    chains = 4,
    iter = 6000,
    warmup = 3000,
    seed = 1234,
    refresh = 0,
    cores = 4,
    control = list(adapt_delta = 0.995, max_treedepth = 15)
  )
  s <- resumen_parametro(fit, "b_menor15")
  or_draws <- exp(as_draws_df(fit)$b_menor15)
  dfit <- diagnosticos_globales(fit, 15)
  tibble(
    punto_corte = etiqueta,
    n = nrow(d),
    eventos_categoria_superior = sum(d$y),
    coeficiente_log_odds = s$median,
    coeficiente_ICr95_inferior = s$ICr95_inferior,
    coeficiente_ICr95_superior = s$ICr95_superior,
    OR = median(or_draws),
    ICr95_inferior = unname(quantile(or_draws, 0.025)),
    ICr95_superior = unname(quantile(or_draws, 0.975)),
    OR_ordinal_comun = median(or_ord_draws),
    diferencia_OR_menos_OR_ordinal = median(or_draws) - median(or_ord_draws),
    razon_OR_sobre_OR_ordinal = median(or_draws) / median(or_ord_draws),
    ICr_corte_solapa_ICr_ordinal =
      unname(quantile(or_draws, 0.025)) <= quantile(or_ord_draws, 0.975) &&
      unname(quantile(or_draws, 0.975)) >= quantile(or_ord_draws, 0.025),
    Rhat_coeficiente = s$rhat,
    ESS_bulk_coeficiente = s$ess_bulk,
    ESS_tail_coeficiente = s$ess_tail
  ) %>% bind_cols(dfit)
}

sensibilidad <- bind_rows(lapply(seq_len(nrow(cortes)), function(i) {
  ajustar_corte(cortes$corte_num[i], cortes$punto_corte[i], fit_bin)
}))
write.csv(
  sensibilidad,
  "output/prenatal/odds_proporcionales_sensibilidad.csv",
  row.names = FALSE
)

fmt <- function(x, d = 3) formatC(x, digits = d, format = "f")
compatibilidad <- if (
  all(sensibilidad$ICr_corte_solapa_ICr_ordinal) &&
  max(abs(sensibilidad$diferencia_OR_menos_OR_ordinal)) < 0.20
) {
  paste(
    "Los tres OR acumulativos tienen magnitud cercana al OR común y sus",
    "intervalos se solapan con el ICr del modelo ordinal; los datos son",
    "compatibles con el supuesto de odds proporcionales."
  )
} else {
  paste(
    "Los OR acumulativos muestran heterogeneidad relevante de magnitud o",
    "incertidumbre respecto del OR común; el supuesto de odds proporcionales",
    "no queda claramente respaldado y debe describirse con cautela."
  )
}

lineas_sens <- apply(sensibilidad, 1, function(z) {
  paste0(
    "- ", z[["punto_corte"]], ": OR ", fmt(as.numeric(z[["OR"]])),
    " (ICr95% ", fmt(as.numeric(z[["ICr95_inferior"]])), "–",
    fmt(as.numeric(z[["ICr95_superior"]])), "); diferencia frente al OR común ",
    fmt(as.numeric(z[["diferencia_OR_menos_OR_ordinal"]])), "."
  )
})

resumen_md <- c(
  "# Resumen reproducible del punto editorial 6",
  "",
  "## Regla operacional",
  "",
  paste(
    "La variable observada es `Número Consultas prenatales` y la edad",
    "gestacional es `Edad gestaciol RN`. Los contactos esperados son 1, 2,",
    "3, 4, 5, 6, 7 y 8 para <20, 20–<26, 26–<30, 30–<34, 34–<36,",
    "36–<38, 38–<40 y ≥40 semanas, respectivamente. Sin controles = 0;",
    "inadecuado = >0 y <50%; intermedio = 50–<80%; adecuado = ≥80%."
  ),
  "",
  "## Jerarquía analítica",
  "",
  paste(
    "El análisis principal es `Control prenatal adecuado: sí/no`, porque",
    "mantiene el estimando RP y la diferencia de prevalencias usado para las",
    "demás características binarias de la Tabla 2. La adecuación ordinal es",
    "secundaria y aporta información sobre el gradiente completo de cuatro categorías."
  ),
  "",
  "## Resultado binario principal",
  "",
  paste0(
    "RP ", fmt(modelo_bin$RP), " (ICr95% ", fmt(modelo_bin$RP_ICr95_inferior),
    "–", fmt(modelo_bin$RP_ICr95_superior), "); DP ", fmt(modelo_bin$DP),
    " (ICr95% ", fmt(modelo_bin$DP_ICr95_inferior), "–",
    fmt(modelo_bin$DP_ICr95_superior), ")."
  ),
  "",
  "## Resultado ordinal secundario",
  "",
  paste0(
    "Coeficiente ", fmt(modelo_ord$coeficiente_log_odds), " (ICr95% ",
    fmt(modelo_ord$coeficiente_ICr95_inferior), "–",
    fmt(modelo_ord$coeficiente_ICr95_superior), "); OR acumulativa ",
    fmt(modelo_ord$OR_acumulativa), " (ICr95% ",
    fmt(modelo_ord$OR_ICr95_inferior), "–", fmt(modelo_ord$OR_ICr95_superior), ")."
  ),
  "",
  "## Thresholds",
  "",
  paste0(
    "- ", thresholds$threshold, ": ", fmt(thresholds$mediana),
    " (ICr95% ", fmt(thresholds$ICr95_inferior), "–",
    fmt(thresholds$ICr95_superior), ")."
  ),
  "",
  "## Evaluación de odds proporcionales",
  "",
  lineas_sens,
  "",
  compatibilidad,
  "",
  "## Comparación documental pendiente",
  "",
  paste(
    "Deberán actualizarse Métodos, Resultados y la jerarquía descrita en el",
    "resumen; Tabla 1, la línea y nota de Tabla 2; Tabla S1; Tabla S3;",
    "Discusión y Carta de Respuesta. No se modificó ninguno de esos archivos."
  ),
  "",
  "## Inconsistencias detectadas",
  "",
  paste(
    "La nota actual de Tabla 2 describe incorrectamente el evento binario",
    "como si comparara una variable ordinal frente a tres categorías; el código",
    "real modela adecuado (≥80%) frente a no adecuado. Métodos y resumen",
    "presentan actualmente la adecuación ordinal como principal, contrario a la",
    "jerarquía solicitada. La regla por edad gestacional existe en el código,",
    "pero no está expuesta en el manuscrito."
  )
)
writeLines(resumen_md, "output/prenatal/resumen_punto6.md", useBytes = TRUE)

esperados <- file.path(
  "output/prenatal",
  c(
    "regla_contactos_esperados.csv",
    "adecuacion_categorias_por_grupo.csv",
    "modelo_adecuacion_binaria.csv",
    "modelo_adecuacion_ordinal.csv",
    "thresholds_adecuacion_ordinal.csv",
    "diagnosticos_adecuacion_ordinal.csv",
    "odds_proporcionales_sensibilidad.csv",
    "resumen_punto6.md"
  )
)
stopifnot(all(file.exists(esperados)), all(file.info(esperados)$size > 0))
cat("PUNTO 6 COMPLETADO\n")
cat("Archivos generados:", length(esperados), "\n")
cat("n materno verificado:", nrow(df), "\n")
