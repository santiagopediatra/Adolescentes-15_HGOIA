#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(brms)
  library(posterior)
  library(loo)
})

set.seed(1707)
options(mc.cores = 4)

salida <- "output/consultas_prenatales"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
archivos_permitidos <- c(
  "distribucion_observada.csv", "heaping_y_extremos.csv",
  "ppc_gaussiano.csv", "comparacion_modelos.csv",
  "modelo_gaussiano.csv", "modelo_poisson.csv", "modelo_negbin.csv",
  "diagnosticos_modelos.csv", "resumen_punto7.md"
)

# Se reconstruye exactamente la muestra materna del pipeline vigente.
datos_crudos <- read.csv(
  "Adolescentes.csv", fileEncoding = "UTF-8", check.names = FALSE,
  stringsAsFactors = FALSE
)
names(datos_crudos) <- trimws(names(datos_crudos))
names(datos_crudos) <- gsub("[[:space:]]+", " ", names(datos_crudos))

variable_consultas <- "Número Consultas prenatales"
variable_eg <- "Edad gestaciol RN"
stopifnot(all(c(variable_consultas, variable_eg) %in% names(datos_crudos)))

vars_llave_madre <- c(
  "Año", "Edad materna", "Años estudios mayor nivel",
  "PAREJA ESTABLE CODIGO", "ETNIA CODIGO", "Numero gestas previas",
  "Numero de Partos previos", "Cesáreas previas CODIGO",
  "Embarazo planeado CODIGO", "ANTICONCEPTIVO CODIGO",
  variable_consultas, "TIPO DE PARTO", "CESAREA"
)

asignar_cluster_gestacional <- function(eg_vals, umbral_semanas = 3) {
  n <- length(eg_vals)
  if (n == 0) return(integer(0))
  if (n == 1) return(1L)
  if (all(is.na(eg_vals))) return(rep(1L, n))
  ord <- order(eg_vals, na.last = TRUE)
  x <- eg_vals[ord]
  cl <- integer(n)
  cl[1] <- 1L
  for (i in 2:n) {
    cl[i] <- cl[i - 1] + as.integer(
      !is.na(x[i]) && !is.na(x[i - 1]) &&
        (x[i] - x[i - 1]) >= umbral_semanas
    )
  }
  out <- integer(n)
  out[ord] <- cl
  out
}

datos_limpios <- distinct(datos_crudos)
datos_multiples <- datos_limpios %>%
  filter(`Embarazo múltiple CODIGO` == 1) %>%
  group_by(across(all_of(vars_llave_madre))) %>%
  mutate(
    subgrupo_gestacional = asignar_cluster_gestacional(
      .data[[variable_eg]], 3
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
  filter(!is.na(`Edad materna`), between(`Edad materna`, 10, 19)) %>%
  transmute(
    consultas_prenatales = .data[[variable_consultas]],
    menor15 = as.integer(`Edad materna` < 15),
    edad_gestacional_rn = .data[[variable_eg]]
  )

objetos <- readRDS("resultados_RBSMI_DEFINITIVO_CORREGIDO.rds")
stopifnot(nrow(df) == 7035, nrow(df) == nrow(objetos$df))
stopifnot(isTRUE(all.equal(
  df$consultas_prenatales, objetos$df[[variable_consultas]],
  check.attributes = FALSE
)))
stopifnot(isTRUE(all.equal(
  df$edad_gestacional_rn, objetos$df[[variable_eg]],
  check.attributes = FALSE
)))

d_crudo <- df %>% filter(!is.na(consultas_prenatales), !is.na(menor15))
d_ajustado <- df %>%
  filter(
    !is.na(consultas_prenatales), !is.na(menor15),
    !is.na(edad_gestacional_rn)
  )
stopifnot(all(d_crudo$consultas_prenatales >= 0))
stopifnot(all(d_crudo$consultas_prenatales == floor(d_crudo$consultas_prenatales)))

# Distribución observada: resumen, percentiles y frecuencia de cada entero.
y <- d_crudo$consultas_prenatales
probs <- c(0, .01, .025, .05, .10, .25, .50, .75, .90, .95, .975, .99, 1)
resumen_obs <- tibble(
  tipo = "resumen",
  estadistico = c(
    "n_total_materno", "n_valido", "n_faltante", "proporcion_faltante",
    "minimo", "maximo", "media", "mediana", "varianza", "desviacion_estandar",
    "varianza_sobre_media", "asimetria_muestral"
  ),
  valor = c(
    nrow(df), length(y), sum(is.na(df$consultas_prenatales)),
    mean(is.na(df$consultas_prenatales)), min(y), max(y), mean(y), median(y),
    var(y), sd(y), var(y) / mean(y),
    mean((y - mean(y))^3) / sd(y)^3
  ),
  n = NA_integer_, proporcion = NA_real_
)
percentiles <- tibble(
  tipo = "percentil",
  estadistico = paste0("p", formatC(100 * probs, format = "fg", digits = 4)),
  valor = as.numeric(quantile(y, probs, names = FALSE, type = 7)),
  n = NA_integer_, proporcion = NA_real_
)
frecuencias <- tibble(valor_entero = seq(min(y), max(y))) %>%
  left_join(count(tibble(valor_entero = y), valor_entero, name = "n"),
            by = "valor_entero") %>%
  mutate(
    n = replace_na(n, 0L), tipo = "frecuencia",
    estadistico = paste0("valor_", valor_entero), valor = valor_entero,
    proporcion = n / length(y)
  ) %>%
  select(tipo, estadistico, valor, n, proporcion)
distribucion <- bind_rows(resumen_obs, percentiles, frecuencias)
write.csv(distribucion, file.path(salida, archivos_permitidos[1]), row.names = FALSE)

# Heaping: exceso local de frecuencia respecto del promedio de enteros adyacentes.
q1 <- unname(quantile(y, .25))
q3 <- unname(quantile(y, .75))
limite_extremo <- q3 + 1.5 * IQR(y)
freq_vec <- setNames(frecuencias$n, frecuencias$valor)
heaping <- frecuencias %>%
  transmute(
    tipo = "acumulacion",
    valor = valor,
    n,
    proporcion,
    frecuencia_vecinos = if_else(
      valor > min(y) & valor < max(y),
      (freq_vec[as.character(valor - 1)] + freq_vec[as.character(valor + 1)]) / 2,
      NA_real_
    ),
    razon_sobre_vecinos = n / frecuencia_vecinos,
    criterio = "razón frecuencia/promedio de vecinos; posible heaping si >=1,25 y n>=1%"
  ) %>%
  mutate(posible_heaping = razon_sobre_vecinos >= 1.25 & proporcion >= .01)
extremos <- tibble(valor = sort(unique(y[y > limite_extremo]))) %>%
  mutate(
    tipo = "extremo_superior_Tukey",
    n = vapply(valor, function(z) sum(y == z), integer(1)),
    proporcion = n / length(y), frecuencia_vecinos = NA_real_,
    razon_sobre_vecinos = NA_real_,
    criterio = paste0("valor > Q3 + 1,5*RIC = ", limite_extremo),
    posible_heaping = NA
  )
heaping_extremos <- bind_rows(heaping, extremos)
write.csv(
  heaping_extremos, file.path(salida, archivos_permitidos[2]), row.names = FALSE
)

priors_gauss_crudo <- c(
  prior(normal(5, 3), class = "Intercept"),
  prior(normal(0, 1.5), class = "b"),
  prior(exponential(1), class = "sigma")
)
priors_gauss_aj <- c(
  prior(normal(5, 3), class = "Intercept"),
  prior(normal(0, 1.5), class = "b"),
  prior(normal(0, 0.5), class = "b", coef = "edad_gestacional_rn"),
  prior(exponential(1), class = "sigma")
)
# Priors débiles en escala log para las sensibilidades de conteo.
priors_conteo_crudo <- c(
  prior(normal(log(5), 1), class = "Intercept"),
  prior(normal(0, 0.5), class = "b")
)
priors_conteo_aj <- c(
  prior(normal(log(5), 1), class = "Intercept"),
  prior(normal(0, 0.5), class = "b"),
  prior(normal(0, 0.1), class = "b", coef = "edad_gestacional_rn")
)

args_mcmc <- list(
  chains = 4, iter = 4000, warmup = 2000, seed = 1707,
  cores = 4, refresh = 200,
  control = list(adapt_delta = 0.95, max_treedepth = 12)
)
ajustar <- function(formula, data, family, prior) {
  do.call(brm, c(list(formula = formula, data = data, family = family,
                      prior = prior), args_mcmc))
}

fits <- list(
  gaussiano_no_ajustado = ajustar(
    consultas_prenatales ~ menor15, d_crudo, gaussian(), priors_gauss_crudo
  ),
  gaussiano_ajustado = ajustar(
    consultas_prenatales ~ menor15 + edad_gestacional_rn,
    d_ajustado, gaussian(), priors_gauss_aj
  ),
  poisson_no_ajustado = ajustar(
    consultas_prenatales ~ menor15, d_crudo, poisson(), priors_conteo_crudo
  ),
  poisson_ajustado = ajustar(
    consultas_prenatales ~ menor15 + edad_gestacional_rn,
    d_ajustado, poisson(), priors_conteo_aj
  ),
  negbin_no_ajustado = ajustar(
    consultas_prenatales ~ menor15, d_crudo, negbinomial(),
    c(priors_conteo_crudo, prior(exponential(1), class = "shape"))
  ),
  negbin_ajustado = ajustar(
    consultas_prenatales ~ menor15 + edad_gestacional_rn,
    d_ajustado, negbinomial(),
    c(priors_conteo_aj, prior(exponential(1), class = "shape"))
  )
)

resumen_coef <- function(fit, nombre, familia, ajuste, n) {
  dr <- as_draws_df(fit)
  b <- dr$b_menor15
  es_conteo <- familia != "gaussiano"
  tibble(
    modelo = nombre, familia = familia, ajuste = ajuste, n = n,
    estimando = if_else(es_conteo, "razon_de_medias", "diferencia_de_medias"),
    estimacion = median(if (es_conteo) exp(b) else b),
    ICr95_inferior = quantile(if (es_conteo) exp(b) else b, .025),
    ICr95_superior = quantile(if (es_conteo) exp(b) else b, .975),
    coeficiente = median(b),
    coeficiente_ICr95_inferior = quantile(b, .025),
    coeficiente_ICr95_superior = quantile(b, .975),
    shape_mediana = if ("shape" %in% names(dr)) median(dr$shape) else NA_real_,
    shape_ICr95_inferior = if ("shape" %in% names(dr)) quantile(dr$shape, .025) else NA_real_,
    shape_ICr95_superior = if ("shape" %in% names(dr)) quantile(dr$shape, .975) else NA_real_
  )
}

modelos <- bind_rows(
  resumen_coef(fits$gaussiano_no_ajustado, "gaussiano_no_ajustado", "gaussiano", "ninguno", nrow(d_crudo)),
  resumen_coef(fits$gaussiano_ajustado, "gaussiano_ajustado", "gaussiano", "oportunidad_acumulada", nrow(d_ajustado)),
  resumen_coef(fits$poisson_no_ajustado, "poisson_no_ajustado", "poisson", "ninguno", nrow(d_crudo)),
  resumen_coef(fits$poisson_ajustado, "poisson_ajustado", "poisson", "oportunidad_acumulada", nrow(d_ajustado)),
  resumen_coef(fits$negbin_no_ajustado, "negbin_no_ajustado", "binomial_negativa", "ninguno", nrow(d_crudo)),
  resumen_coef(fits$negbin_ajustado, "negbin_ajustado", "binomial_negativa", "oportunidad_acumulada", nrow(d_ajustado))
)
write.csv(filter(modelos, familia == "gaussiano"), file.path(salida, archivos_permitidos[5]), row.names = FALSE)
write.csv(filter(modelos, familia == "poisson"), file.path(salida, archivos_permitidos[6]), row.names = FALSE)
write.csv(filter(modelos, familia == "binomial_negativa"), file.path(salida, archivos_permitidos[7]), row.names = FALSE)

diagnostico_fit <- function(fit, nombre) {
  sm <- summarise_draws(as_draws_array(fit))
  np <- nuts_params(fit)
  energia <- np %>%
    filter(Parameter == "energy__") %>%
    arrange(Chain, Iteration) %>%
    group_by(Chain) %>%
    summarise(ebfmi = mean(diff(Value)^2) / var(Value), .groups = "drop")
  tibble(
    modelo = nombre, Rhat_max = max(sm$rhat, na.rm = TRUE),
    ESS_bulk_min = min(sm$ess_bulk, na.rm = TRUE),
    ESS_tail_min = min(sm$ess_tail, na.rm = TRUE),
    divergencias = sum(np$Parameter == "divergent__" & np$Value == 1),
    treedepth_max_observado = max(np$Value[np$Parameter == "treedepth__"]),
    transiciones_treedepth_max = sum(
      np$Parameter == "treedepth__" & np$Value >= 12
    ),
    E_BFMI_min = min(energia$ebfmi)
  )
}
diagnosticos <- bind_rows(Map(diagnostico_fit, fits, names(fits)))
write.csv(diagnosticos, file.path(salida, archivos_permitidos[8]), row.names = FALSE)

estadisticos_ppc <- function(fit, nombre, y_obs, ndraws = 1000) {
  yp <- posterior_predict(fit, ndraws = ndraws)
  valores_heaping <- heaping %>% filter(posible_heaping) %>% pull(valor)
  stat_draw <- function(etiqueta, obs, pred) tibble(
    modelo = nombre, estadistico = etiqueta, observado = obs,
    pred_mediana = median(pred), pred_ICr95_inferior = quantile(pred, .025),
    pred_ICr95_superior = quantile(pred, .975),
    observado_fuera_ICr95 = obs < quantile(pred, .025) | obs > quantile(pred, .975)
  )
  filas <- list(
    stat_draw("media", mean(y_obs), rowMeans(yp)),
    stat_draw("varianza", var(y_obs), apply(yp, 1, var)),
    stat_draw("proporcion_cero", mean(y_obs == 0), rowMeans(yp >= -.5 & yp < .5)),
    stat_draw("proporcion_predicha_negativa", 0, rowMeans(yp < 0)),
    stat_draw("minimo", min(y_obs), apply(yp, 1, min)),
    stat_draw("maximo", max(y_obs), apply(yp, 1, max))
  )
  for (p in c(.01, .05, .25, .5, .75, .95, .99)) {
    filas[[length(filas) + 1]] <- stat_draw(
      paste0("cuantil_", p), unname(quantile(y_obs, p)),
      apply(yp, 1, quantile, probs = p)
    )
  }
  for (v in valores_heaping) {
    filas[[length(filas) + 1]] <- stat_draw(
      paste0("frecuencia_valor_", v), mean(y_obs == v),
      rowMeans(yp >= v - .5 & yp < v + .5)
    )
  }
  bind_rows(filas)
}

ppc_todos <- bind_rows(
  estadisticos_ppc(fits$gaussiano_no_ajustado, "gaussiano_no_ajustado", d_crudo$consultas_prenatales),
  estadisticos_ppc(fits$gaussiano_ajustado, "gaussiano_ajustado", d_ajustado$consultas_prenatales),
  estadisticos_ppc(fits$poisson_no_ajustado, "poisson_no_ajustado", d_crudo$consultas_prenatales),
  estadisticos_ppc(fits$poisson_ajustado, "poisson_ajustado", d_ajustado$consultas_prenatales),
  estadisticos_ppc(fits$negbin_no_ajustado, "negbin_no_ajustado", d_crudo$consultas_prenatales),
  estadisticos_ppc(fits$negbin_ajustado, "negbin_ajustado", d_ajustado$consultas_prenatales)
)
write.csv(
  filter(ppc_todos, grepl("^gaussiano", modelo)),
  file.path(salida, archivos_permitidos[3]), row.names = FALSE
)

# LOO solo dentro de muestras idénticas: modelos crudos entre sí y ajustados entre sí.
loos <- lapply(fits, function(f) loo(f, moment_match = FALSE, cores = 1))
extraer_loo <- function(x, nombre) tibble(
  modelo = nombre, elpd_loo = x$estimates["elpd_loo", "Estimate"],
  se_elpd_loo = x$estimates["elpd_loo", "SE"],
  looic = x$estimates["looic", "Estimate"],
  se_looic = x$estimates["looic", "SE"],
  pareto_k_mayor_07 = sum(pareto_k_values(x) > .7),
  pareto_k_max = max(pareto_k_values(x))
)
loo_tab <- bind_rows(Map(extraer_loo, loos, names(loos)))
comparacion <- ppc_todos %>%
  group_by(modelo) %>%
  summarise(
    ppc_estadisticos_fuera_ICr95 = sum(observado_fuera_ICr95),
    ppc_estadisticos_total = n(), .groups = "drop"
  ) %>%
  left_join(loo_tab, by = "modelo") %>%
  left_join(select(modelos, modelo, familia, ajuste, n), by = "modelo") %>%
  group_by(ajuste) %>%
  mutate(delta_elpd_vs_mejor = elpd_loo - max(elpd_loo)) %>%
  ungroup()
write.csv(comparacion, file.path(salida, archivos_permitidos[4]), row.names = FALSE)

fmt <- function(x, d = 3) formatC(x, digits = d, format = "f")
fila <- function(nombre) filter(modelos, modelo == nombre)
g0 <- fila("gaussiano_no_ajustado"); g1 <- fila("gaussiano_ajustado")
p0 <- fila("poisson_no_ajustado"); p1 <- fila("poisson_ajustado")
n0 <- fila("negbin_no_ajustado"); n1 <- fila("negbin_ajustado")
mejor_crudo <- comparacion %>% filter(ajuste == "ninguno") %>% slice_max(elpd_loo, n = 1)
mejor_aj <- comparacion %>% filter(ajuste == "oportunidad_acumulada") %>% slice_max(elpd_loo, n = 1)
heaps <- heaping %>% filter(posible_heaping) %>% arrange(desc(razon_sobre_vecinos))

resumen_md <- c(
  "# Resumen reproducible del punto editorial 7", "",
  "## Variable y distribución observada", "",
  paste0("Variable: `", variable_consultas, "`. n válido=", length(y),
         "; faltantes=", sum(is.na(df$consultas_prenatales)),
         "; rango=", min(y), "–", max(y), "; media=", fmt(mean(y)),
         "; mediana=", fmt(median(y)), "; varianza=", fmt(var(y)),
         "; DE=", fmt(sd(y)), "; varianza/media=", fmt(var(y)/mean(y)),
         "; asimetría=", fmt(mean((y-mean(y))^3)/sd(y)^3), "."), "",
  paste0("Posibles acumulaciones por criterio local: ",
         ifelse(nrow(heaps) == 0, "ninguna", paste(heaps$valor, collapse = ", ")), "."),
  paste0("Límite superior de Tukey=", fmt(limite_extremo),
         "; observaciones por encima=", sum(y > limite_extremo), "."), "",
  "## Efectos estimados", "",
  paste0("Gaussiano no ajustado: diferencia de medias ", fmt(g0$estimacion),
         " (ICr95% ", fmt(g0$ICr95_inferior), " a ", fmt(g0$ICr95_superior), ")."),
  paste0("Gaussiano ajustado por oportunidad acumulada: diferencia de medias ", fmt(g1$estimacion),
         " (ICr95% ", fmt(g1$ICr95_inferior), " a ", fmt(g1$ICr95_superior), ")."),
  paste0("Poisson no ajustado: razón de medias ", fmt(p0$estimacion),
         " (ICr95% ", fmt(p0$ICr95_inferior), "–", fmt(p0$ICr95_superior), ")."),
  paste0("Poisson ajustado por oportunidad acumulada: razón de medias ", fmt(p1$estimacion),
         " (ICr95% ", fmt(p1$ICr95_inferior), "–", fmt(p1$ICr95_superior), ")."),
  paste0("Binomial negativa no ajustada: razón de medias ", fmt(n0$estimacion),
         " (ICr95% ", fmt(n0$ICr95_inferior), "–", fmt(n0$ICr95_superior), ")."),
  paste0("Binomial negativa ajustada por oportunidad acumulada: razón de medias ", fmt(n1$estimacion),
         " (ICr95% ", fmt(n1$ICr95_inferior), "–", fmt(n1$ICr95_superior), ")."), "",
  "## Comparación predictiva", "",
  paste0("Mejor ELPD-LOO no ajustado: ", mejor_crudo$modelo, "."),
  paste0("Mejor ELPD-LOO ajustado: ", mejor_aj$modelo, "."),
  "La decisión debe integrar LOO y los PPC cuantitativos, no la significación estadística.", "",
  "## Interpretación del ajuste", "",
  paste(
    "El ajuste por edad gestacional al parto se interpreta como un ajuste por",
    "oportunidad acumulada de recibir consultas prenatales, no como control causal",
    "de confusión ni como estimación de un efecto independiente."
  )
)
writeLines(resumen_md, file.path(salida, archivos_permitidos[9]), useBytes = TRUE)

producidos <- list.files(salida, all.files = FALSE, no.. = TRUE)
stopifnot(setequal(producidos, archivos_permitidos))
stopifnot(all(file.info(file.path(salida, archivos_permitidos))$size > 0))
stopifnot(all(diagnosticos$divergencias == 0), max(diagnosticos$Rhat_max) < 1.01)
cat("PUNTO 7 COMPLETADO\n")
cat("Variable:", variable_consultas, "\n")
cat("n válido:", length(y), "\n")
cat("Archivos generados:", length(archivos_permitidos), "\n")
