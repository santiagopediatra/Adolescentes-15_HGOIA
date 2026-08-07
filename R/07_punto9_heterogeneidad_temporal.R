#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(brms)
  library(posterior)
  library(loo)
})

set.seed(1909)
options(mc.cores = 4)

salida <- "output/heterogeneidad_temporal"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
archivos <- c(
  "interacciones_periodo.csv", "estimaciones_por_periodo.csv",
  "comparacion_modelos_interaccion.csv", "resumen_punto9.md"
)

objetos <- readRDS("resultados_RBSMI_DEFINITIVO_CORREGIDO.rds")
df <- objetos$df
stopifnot(nrow(df) == 7035, all(c("Año", "menor15") %in% names(df)))

niveles_periodo <- c("p2009_2014", "p2015_2019", "p2020_jun2024")
etiquetas_periodo <- c(
  p2009_2014 = "2009–2014", p2015_2019 = "2015–2019",
  p2020_jun2024 = "2020–junio 2024"
)
df <- df %>%
  mutate(
    periodo = case_when(
      Año %in% 2009:2014 ~ "p2009_2014",
      Año %in% 2015:2019 ~ "p2015_2019",
      Año %in% 2020:2024 ~ "p2020_jun2024",
      TRUE ~ NA_character_
    ),
    periodo = factor(periodo, levels = niveles_periodo)
  )
stopifnot(!anyNA(df$periodo), min(df$Año) == 2009, max(df$Año) == 2024)

# Variables obligatorias del punto editorial 9.
variables_binarias <- c(
  pareja_estable = "Pareja estable",
  etnia_minoritaria = "Etnia minoritaria",
  adecuacion_adecuada_bin = "Control prenatal adecuado: sí/no"
)
stopifnot(all(names(variables_binarias) %in% names(df)))

priors_bin <- c(
  prior(normal(0, 3), class = "Intercept"),
  prior(normal(0, 1.5), class = "b")
)
priors_ord <- prior(normal(0, 1.5), class = "b")
args_mcmc <- list(
  chains = 4, iter = 5000, warmup = 2500, cores = 4, refresh = 200,
  control = list(adapt_delta = .99, max_treedepth = 15)
)

ajustar <- function(formula, data, family, prior, seed) {
  do.call(brm, c(
    list(formula = formula, data = data, family = family, prior = prior,
         seed = seed), args_mcmc
  ))
}

ebfmi_min <- function(fit) {
  nuts_params(fit) %>%
    filter(Parameter == "energy__") %>%
    arrange(Chain, Iteration) %>%
    group_by(Chain) %>%
    summarise(E_BFMI = mean(diff(Value)^2) / var(Value), .groups = "drop") %>%
    summarise(valor = min(E_BFMI)) %>% pull(valor)
}

diagnostico <- function(fit) {
  pars <- variables(fit)
  pars <- pars[grepl("^b_", pars)]
  sm <- summarise_draws(
    as_draws_matrix(fit, variable = pars),
    rhat = rhat, ess_bulk = ess_bulk, ess_tail = ess_tail
  )
  np <- nuts_params(fit)
  mt <- fit$fit@stan_args[[1]]$control$max_treedepth
  c(
    Rhat_max = max(sm$rhat, na.rm = TRUE),
    ESS_bulk_min = min(sm$ess_bulk, na.rm = TRUE),
    ESS_tail_min = min(sm$ess_tail, na.rm = TRUE),
    divergencias = sum(np$Parameter == "divergent__" & np$Value == 1),
    treedepth_configurado = mt,
    treedepth_observado_max = max(np$Value[np$Parameter == "treedepth__"]),
    iteraciones_en_max_treedepth = sum(
      np$Parameter == "treedepth__" & np$Value >= mt
    ),
    E_BFMI_min = ebfmi_min(fit)
  )
}

resumen_vector <- function(x) {
  c(
    estimacion = median(x),
    ICr95_inferior = unname(quantile(x, .025)),
    ICr95_superior = unname(quantile(x, .975))
  )
}

fila_interaccion <- function(fit, variable, etiqueta, familia) {
  dr <- as_draws_df(fit)
  pars <- names(dr)[grepl("^b_menor15:periodo", names(dr))]
  bind_rows(lapply(pars, function(p) {
    x <- dr[[p]]
    periodo_codigo <- sub("^b_menor15:periodo", "", p)
    sm <- resumen_vector(x)
    ex <- resumen_vector(exp(x))
    tibble(
      variable = variable, resultado = etiqueta, familia = familia,
      parametro = p, periodo_contrastado = etiquetas_periodo[[periodo_codigo]],
      periodo_referencia = "2009–2014", estimacion_logit = sm["estimacion"],
      ICr95_logit_inferior = sm["ICr95_inferior"],
      ICr95_logit_superior = sm["ICr95_superior"],
      razon_de_OR = ex["estimacion"],
      ICr95_razon_OR_inferior = ex["ICr95_inferior"],
      ICr95_razon_OR_superior = ex["ICr95_superior"]
    )
  }))
}

estimaciones_binarias <- function(fit, variable, etiqueta) {
  bind_rows(lapply(niveles_periodo, function(p) {
    nd <- data.frame(
      menor15 = c(0L, 1L),
      periodo = factor(rep(p, 2), levels = niveles_periodo)
    )
    ep <- posterior_epred(fit, newdata = nd, re_formula = NA)
    p_ref <- ep[, 1]
    p_menor <- ep[, 2]
    dp <- p_menor - p_ref
    rp <- p_menor / p_ref
    a <- resumen_vector(p_ref); b <- resumen_vector(p_menor)
    d <- resumen_vector(dp); r <- resumen_vector(rp)
    tibble(
      variable = variable, resultado = etiqueta,
      analisis = "Binario principal", periodo = etiquetas_periodo[[p]],
      prevalencia_15_19 = a["estimacion"],
      ICr95_prev_15_19_inferior = a["ICr95_inferior"],
      ICr95_prev_15_19_superior = a["ICr95_superior"],
      prevalencia_10_14 = b["estimacion"],
      ICr95_prev_10_14_inferior = b["ICr95_inferior"],
      ICr95_prev_10_14_superior = b["ICr95_superior"],
      diferencia_absoluta = d["estimacion"],
      ICr95_DP_inferior = d["ICr95_inferior"],
      ICr95_DP_superior = d["ICr95_superior"],
      estimando_relativo = "Razón de prevalencias marginal",
      estimacion_relativa = r["estimacion"],
      ICr95_relativa_inferior = r["ICr95_inferior"],
      ICr95_relativa_superior = r["ICr95_superior"],
      direccion = if_else(d["estimacion"] < 0,
                          "menor en 10–14", "mayor en 10–14")
    )
  }))
}

estimaciones_ordinales <- function(fit) {
  dr <- as_draws_df(fit)
  bind_rows(lapply(niveles_periodo, function(p) {
    contraste <- dr$b_menor15
    if (p != niveles_periodo[1]) {
      contraste <- contraste + dr[[paste0("b_menor15:periodo", p)]]
    }
    or <- resumen_vector(exp(contraste))
    tibble(
      variable = "adecuacion_controles",
      resultado = "Adecuación ordinal del control prenatal",
      analisis = "Ordinal secundario", periodo = etiquetas_periodo[[p]],
      prevalencia_15_19 = NA_real_, ICr95_prev_15_19_inferior = NA_real_,
      ICr95_prev_15_19_superior = NA_real_, prevalencia_10_14 = NA_real_,
      ICr95_prev_10_14_inferior = NA_real_,
      ICr95_prev_10_14_superior = NA_real_, diferencia_absoluta = NA_real_,
      ICr95_DP_inferior = NA_real_, ICr95_DP_superior = NA_real_,
      estimando_relativo = "OR común cumulative-logit",
      estimacion_relativa = or["estimacion"],
      ICr95_relativa_inferior = or["ICr95_inferior"],
      ICr95_relativa_superior = or["ICr95_superior"],
      direccion = if_else(or["estimacion"] < 1,
        "menores odds de categoría más adecuada en 10–14",
        "mayores odds de categoría más adecuada en 10–14")
    )
  }))
}

comparar <- function(fit_add, fit_int, variable, etiqueta, familia) {
  la <- loo(fit_add, cores = 1)
  li <- loo(fit_int, cores = 1)
  di <- li$pointwise[, "elpd_loo"] - la$pointwise[, "elpd_loo"]
  delta <- sum(di)
  se_delta <- sqrt(length(di) * var(di))
  da <- diagnostico(fit_add); diags_int <- diagnostico(fit_int)
  evidencia <- case_when(
    delta > 2 * se_delta ~ "mejora predictiva clara con interacción",
    delta > 0 ~ "ventaja predictiva pequeña o incierta con interacción",
    TRUE ~ "sin mejora predictiva con interacción"
  )
  tibble(
    variable = variable, resultado = etiqueta, familia = familia,
    n = nobs(fit_int), ELPD_additivo = la$estimates["elpd_loo", "Estimate"],
    SE_ELPD_additivo = la$estimates["elpd_loo", "SE"],
    ELPD_interaccion = li$estimates["elpd_loo", "Estimate"],
    SE_ELPD_interaccion = li$estimates["elpd_loo", "SE"],
    delta_ELPD_interaccion_vs_additivo = delta, SE_delta_ELPD = se_delta,
    interpretacion_predictiva = evidencia,
    Pareto_k_mayor_07_additivo = sum(pareto_k_values(la) > .7),
    Pareto_k_mayor_07_interaccion = sum(pareto_k_values(li) > .7),
    Rhat_max_additivo = da["Rhat_max"],
    ESS_bulk_min_additivo = da["ESS_bulk_min"],
    ESS_tail_min_additivo = da["ESS_tail_min"],
    divergencias_additivo = da["divergencias"],
    treedepth_configurado_additivo = da["treedepth_configurado"],
    treedepth_observado_max_additivo = da["treedepth_observado_max"],
    iteraciones_en_max_treedepth_additivo = da["iteraciones_en_max_treedepth"],
    E_BFMI_min_additivo = da["E_BFMI_min"],
    Rhat_max_interaccion = diags_int["Rhat_max"],
    ESS_bulk_min_interaccion = diags_int["ESS_bulk_min"],
    ESS_tail_min_interaccion = diags_int["ESS_tail_min"],
    divergencias_interaccion = diags_int["divergencias"],
    treedepth_configurado_interaccion = diags_int["treedepth_configurado"],
    treedepth_observado_max_interaccion = diags_int["treedepth_observado_max"],
    iteraciones_en_max_treedepth_interaccion =
      diags_int["iteraciones_en_max_treedepth"],
    E_BFMI_min_interaccion = diags_int["E_BFMI_min"]
  )
}

fits <- list()
interacciones <- list()
estimaciones <- list()
comparaciones <- list()

for (i in seq_along(variables_binarias)) {
  variable <- names(variables_binarias)[i]
  etiqueta <- unname(variables_binarias[i])
  d <- df %>%
    transmute(y = .data[[variable]], menor15, periodo) %>%
    filter(complete.cases(.))
  stopifnot(all(d$y %in% 0:1))
  fit_add <- ajustar(
    y ~ menor15 + periodo, d, bernoulli("logit"), priors_bin, 1909 + i
  )
  fit_int <- update(
    fit_add, formula = y ~ menor15 * periodo, recompile = FALSE,
    seed = 2009 + i, refresh = 200
  )
  fits[[paste0(variable, "_add")]] <- fit_add
  fits[[paste0(variable, "_int")]] <- fit_int
  interacciones[[variable]] <- fila_interaccion(
    fit_int, variable, etiqueta, "Bernoulli-logit"
  )
  estimaciones[[variable]] <- estimaciones_binarias(fit_int, variable, etiqueta)
  comparaciones[[variable]] <- comparar(
    fit_add, fit_int, variable, etiqueta, "Bernoulli-logit"
  )
  rm(d); gc(FALSE)
}

# Adecuación ordinal como análisis secundario; el binario anterior permanece como
# análisis principal. Se usan las cuatro categorías ya definidas en el estudio.
stopifnot("adecuacion_controles" %in% names(df))
d_ord <- df %>%
  transmute(adecuacion_controles, menor15, periodo) %>%
  filter(complete.cases(.)) %>%
  mutate(adecuacion_controles = ordered(
    adecuacion_controles,
    levels = c("Sin controles", "Inadecuado", "Intermedio", "Adecuado")
  ))
stopifnot(nlevels(d_ord$adecuacion_controles) == 4)
fit_ord_add <- ajustar(
  adecuacion_controles ~ menor15 + periodo, d_ord,
  cumulative("logit", threshold = "flexible"), priors_ord, 2109
)
fit_ord_int <- update(
  fit_ord_add, formula = adecuacion_controles ~ menor15 * periodo,
  recompile = FALSE, seed = 2110, refresh = 200
)
fits$adecuacion_ordinal_add <- fit_ord_add
fits$adecuacion_ordinal_int <- fit_ord_int
interacciones$adecuacion_ordinal <- fila_interaccion(
  fit_ord_int, "adecuacion_controles",
  "Adecuación ordinal del control prenatal", "Ordinal cumulative-logit"
)
estimaciones$adecuacion_ordinal <- estimaciones_ordinales(fit_ord_int)
comparaciones$adecuacion_ordinal <- comparar(
  fit_ord_add, fit_ord_int, "adecuacion_controles",
  "Adecuación ordinal del control prenatal", "Ordinal cumulative-logit"
)

tabla_interacciones <- bind_rows(interacciones)
tabla_estimaciones <- bind_rows(estimaciones)
tabla_comparaciones <- bind_rows(comparaciones)

# Las condiciones diagnósticas exigidas se validan antes de escribir resultados.
stopifnot(
  max(tabla_comparaciones$Rhat_max_additivo) <= 1.01,
  max(tabla_comparaciones$Rhat_max_interaccion) <= 1.01,
  min(tabla_comparaciones$ESS_bulk_min_additivo) >= 400,
  min(tabla_comparaciones$ESS_bulk_min_interaccion) >= 400,
  min(tabla_comparaciones$ESS_tail_min_additivo) >= 400,
  min(tabla_comparaciones$ESS_tail_min_interaccion) >= 400,
  sum(tabla_comparaciones$divergencias_additivo) == 0,
  sum(tabla_comparaciones$divergencias_interaccion) == 0,
  sum(tabla_comparaciones$iteraciones_en_max_treedepth_additivo) == 0,
  sum(tabla_comparaciones$iteraciones_en_max_treedepth_interaccion) == 0,
  min(tabla_comparaciones$E_BFMI_min_additivo) > .3,
  min(tabla_comparaciones$E_BFMI_min_interaccion) > .3
)

write.csv(tabla_interacciones, file.path(salida, archivos[1]), row.names = FALSE)
write.csv(tabla_estimaciones, file.path(salida, archivos[2]), row.names = FALSE)
write.csv(tabla_comparaciones, file.path(salida, archivos[3]), row.names = FALSE)

fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, decimal.mark = ",")
lineas_estimacion <- function(variable_objetivo) {
  tabla_estimaciones %>%
    filter(.data$variable == .env$variable_objetivo,
           analisis == "Binario principal") %>%
    transmute(texto = paste0(
      "  - ", periodo, ": prevalencia predicha 10–14 = ",
      fmt(prevalencia_10_14), " (ICr95% ", fmt(ICr95_prev_10_14_inferior),
      " a ", fmt(ICr95_prev_10_14_superior), "); 15–19 = ",
      fmt(prevalencia_15_19), " (", fmt(ICr95_prev_15_19_inferior), " a ",
      fmt(ICr95_prev_15_19_superior), "); DP = ", fmt(diferencia_absoluta),
      " (", fmt(ICr95_DP_inferior), " a ", fmt(ICr95_DP_superior),
      "); RP = ", fmt(estimacion_relativa), " (", fmt(ICr95_relativa_inferior),
      " a ", fmt(ICr95_relativa_superior), ")."
    )) %>% pull(texto)
}
linea_loo <- function(variable_objetivo) {
  z <- tabla_comparaciones %>%
    filter(.data$variable == .env$variable_objetivo)
  paste0(
    "  - Comparación LOO: ΔELPD interacción vs aditivo = ",
    fmt(z$delta_ELPD_interaccion_vs_additivo), " (EE ", fmt(z$SE_delta_ELPD),
    "); ", z$interpretacion_predictiva, "."
  )
}

dg <- tibble(
  Rhat = c(tabla_comparaciones$Rhat_max_additivo,
           tabla_comparaciones$Rhat_max_interaccion),
  bulk = c(tabla_comparaciones$ESS_bulk_min_additivo,
           tabla_comparaciones$ESS_bulk_min_interaccion),
  tail = c(tabla_comparaciones$ESS_tail_min_additivo,
           tabla_comparaciones$ESS_tail_min_interaccion),
  div = c(tabla_comparaciones$divergencias_additivo,
          tabla_comparaciones$divergencias_interaccion),
  td = c(tabla_comparaciones$iteraciones_en_max_treedepth_additivo,
         tabla_comparaciones$iteraciones_en_max_treedepth_interaccion),
  ebfmi = c(tabla_comparaciones$E_BFMI_min_additivo,
            tabla_comparaciones$E_BFMI_min_interaccion)
)

resumen <- c(
  "# Punto editorial 9: heterogeneidad temporal",
  "",
  paste0("Se evaluaron ", nrow(tabla_comparaciones) * 2,
         " modelos bayesianos (aditivo e interacción para cuatro análisis). ",
         "El período final es 2020–junio 2024; 2024 contiene únicamente enero–junio."),
  "",
  "## Pareja estable",
  lineas_estimacion("pareja_estable"), linea_loo("pareja_estable"),
  "La dirección estimada cambia en el período reciente; su magnitud e incertidumbre se interpretan mediante las RP y DP marginales anteriores, no como un rasgo uniforme de todo el estudio.",
  "",
  "## Etnia minoritaria",
  lineas_estimacion("etnia_minoritaria"), linea_loo("etnia_minoritaria"),
  "La estimación del período reciente permite separar atenuación de magnitud e incertidumbre; la comparación LOO evalúa si esa variación mejora la predicción global.",
  "",
  "## Control prenatal adecuado: sí/no (principal)",
  lineas_estimacion("adecuacion_adecuada_bin"),
  linea_loo("adecuacion_adecuada_bin"),
  "La proximidad al valor nulo en 2020–junio 2024 impide describir la menor adecuación como una característica temporalmente uniforme.",
  "",
  "## Adecuación ordinal del control prenatal (secundario)",
  paste0("  - ", tabla_estimaciones %>%
    filter(variable == "adecuacion_controles") %>%
    transmute(x = paste0(periodo, ": OR común = ", fmt(estimacion_relativa),
      " (ICr95% ", fmt(ICr95_relativa_inferior), " a ",
      fmt(ICr95_relativa_superior), ").")) %>% pull(x)),
  linea_loo("adecuacion_controles"),
  "",
  "## Diagnósticos",
  paste0(
    "R-hat máximo = ", fmt(max(dg$Rhat), 4),
    "; ESS bulk mínimo = ", fmt(min(dg$bulk), 0),
    "; ESS tail mínimo = ", fmt(min(dg$tail), 0),
    "; divergencias = ", sum(dg$div),
    "; iteraciones en treedepth máximo = ", sum(dg$td),
    "; E-BFMI mínimo = ", fmt(min(dg$ebfmi), 3), "."
  ),
  "",
  "## Alcance interpretativo",
  "El hallazgo evaluado es heterogeneidad temporal observada. Cambios en prácticas de registro, cobertura o calidad del SIP, prácticas institucionales, acceso o atención prenatal, composición poblacional y la pandemia de COVID-19 son explicaciones plausibles cuando coinciden temporalmente, pero el estudio no permite identificar cuál mecanismo explica los cambios ni atribuirlos causalmente."
)
writeLines(resumen, file.path(salida, archivos[4]), useBytes = TRUE)

existentes <- list.files(salida, all.files = FALSE, no.. = TRUE)
stopifnot(setequal(existentes, archivos))
message("Punto 9 completado: ", length(fits), " modelos; cuatro archivos autorizados.")
