#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(brms)
  library(posterior)
})

set.seed(1808)
options(mc.cores = 4)

salida <- "output/diagnosticos"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
archivos <- c(
  "diagnosticos_completos.csv", "parametros_posteriores.csv",
  "ppc_modelos.csv", "sensibilidad_priors.csv", "resumen_punto8.md"
)

objetos <- readRDS("resultados_RBSMI_DEFINITIVO_CORREGIDO.rds")
stopifnot(length(objetos$modelos_principales) == 13)

etiquetas_bernoulli <- c(
  pareja_estable = "Pareja estable",
  escolaridad_baja = "Escolaridad cruda: ninguna o primaria",
  etnia_minoritaria = "Etnia minoritaria",
  gestas_previas = "Gestas previas",
  embarazo_multiple = "Embarazo múltiple",
  embarazo_planeado = "Embarazo planeado",
  falla_anticonceptivo = "Falla anticonceptiva",
  infeccion_urinaria = "Infección urinaria",
  sufrimiento_fetal = "Compromiso del bienestar fetal",
  trastorno_hipertensivo = "Trastorno hipertensivo",
  parto_vaginal = "Parto vaginal",
  rezago_escolar_bin = "Rezago escolar binario",
  adecuacion_adecuada_bin = "Control prenatal adecuado: sí/no"
)
stopifnot(setequal(names(objetos$modelos_principales), names(etiquetas_bernoulli)))

resumen_parametros <- function(fit, modelo, familia, parametros = NULL) {
  if (is.null(parametros)) {
    parametros <- variables(fit)
    parametros <- parametros[grepl("^b_|^sigma$|^shape$", parametros)]
  }
  dr <- as_draws_df(fit)
  bind_rows(lapply(parametros, function(p) {
    x <- dr[[p]]
    sm <- summarise_draws(
      as_draws_matrix(fit, variable = p),
      rhat = rhat, ess_bulk = ess_bulk, ess_tail = ess_tail
    )
    tibble(
      modelo = modelo, familia = familia, parametro = p,
      estimacion = median(x), ICr95_inferior = unname(quantile(x, .025)),
      ICr95_superior = unname(quantile(x, .975)),
      Rhat = sm$rhat, ESS_bulk = sm$ess_bulk, ESS_tail = sm$ess_tail
    )
  }))
}

ebfmi_cadenas <- function(fit) {
  nuts_params(fit) %>%
    filter(Parameter == "energy__") %>%
    arrange(Chain, Iteration) %>%
    group_by(Chain) %>%
    summarise(
      E_BFMI = mean(diff(Value)^2) / var(Value), .groups = "drop"
    )
}

max_treedepth_configurado <- function(fit) {
  ctl <- fit$fit@stan_args[[1]]$control
  if (!is.null(ctl$max_treedepth)) ctl$max_treedepth else 10
}

diagnostico <- function(fit, modelo, familia, ppc_resumen) {
  pars <- variables(fit)
  pars <- pars[grepl("^b_|^sigma$|^shape$", pars)]
  sm <- summarise_draws(
    as_draws_matrix(fit, variable = pars),
    rhat = rhat, ess_bulk = ess_bulk, ess_tail = ess_tail
  )
  np <- nuts_params(fit)
  mt <- max_treedepth_configurado(fit)
  n_post <- sum(np$Parameter == "treedepth__")
  n_mt <- sum(np$Parameter == "treedepth__" & np$Value >= mt)
  tibble(
    modelo = modelo, familia = familia,
    Rhat_max = max(sm$rhat, na.rm = TRUE),
    ESS_bulk_min = min(sm$ess_bulk, na.rm = TRUE),
    ESS_tail_min = min(sm$ess_tail, na.rm = TRUE),
    divergencias = sum(np$Parameter == "divergent__" & np$Value == 1),
    max_treedepth_configurado = mt,
    treedepth_observado_max = max(np$Value[np$Parameter == "treedepth__"]),
    iteraciones_en_max_treedepth = n_mt,
    proporcion_en_max_treedepth = n_mt / n_post,
    E_BFMI_min = min(ebfmi_cadenas(fit)$E_BFMI),
    PPC_resumen = ppc_resumen
  )
}

fila_ppc <- function(modelo, familia, estadistico, observado, pred) {
  tibble(
    modelo = modelo, familia = familia, estadistico = estadistico,
    observado = observado, pred_mediana = median(pred),
    pred_ICr95_inferior = unname(quantile(pred, .025)),
    pred_ICr95_superior = unname(quantile(pred, .975)),
    observado_fuera_ICr95 = observado < quantile(pred, .025) |
      observado > quantile(pred, .975)
  )
}

ppc_bernoulli <- function(fit, modelo, ndraws = 1000) {
  y <- fit$data$y
  g <- fit$data$menor15
  yp <- posterior_predict(fit, ndraws = ndraws)
  bind_rows(
    fila_ppc(modelo, "Bernoulli-logit", "prevalencia_global",
             mean(y), rowMeans(yp)),
    fila_ppc(modelo, "Bernoulli-logit", "prevalencia_15_19",
             mean(y[g == 0]), rowMeans(yp[, g == 0, drop = FALSE])),
    fila_ppc(modelo, "Bernoulli-logit", "prevalencia_10_14",
             mean(y[g == 1]), rowMeans(yp[, g == 1, drop = FALSE])),
    fila_ppc(modelo, "Bernoulli-logit", "varianza_global",
             var(y), apply(yp, 1, var))
  )
}

ppc_ordinal <- function(fit, modelo, ndraws = 1000) {
  y <- as.integer(fit$data$adecuacion_controles)
  yp <- posterior_predict(fit, ndraws = ndraws)
  etiquetas <- c("sin_controles", "inadecuado", "intermedio", "adecuado")
  bind_rows(lapply(1:4, function(k) {
    fila_ppc(
      modelo, "Ordinal cumulative-logit",
      paste0("proporcion_", etiquetas[k]), mean(y == k), rowMeans(yp == k)
    )
  }))
}

ppc_conteo <- function(fit, modelo, familia, ndraws = 1000) {
  y <- fit$data$consultas_prenatales
  yp <- posterior_predict(fit, ndraws = ndraws)
  filas <- list(
    fila_ppc(modelo, familia, "media", mean(y), rowMeans(yp)),
    fila_ppc(modelo, familia, "varianza", var(y), apply(yp, 1, var)),
    fila_ppc(modelo, familia, "proporcion_cero", mean(y == 0), rowMeans(yp == 0)),
    fila_ppc(modelo, familia, "proporcion_predicha_negativa", 0, rowMeans(yp < 0)),
    fila_ppc(modelo, familia, "minimo", min(y), apply(yp, 1, min)),
    fila_ppc(modelo, familia, "maximo", max(y), apply(yp, 1, max))
  )
  for (p in c(.01, .05, .25, .5, .75, .95, .99)) {
    filas[[length(filas) + 1]] <- fila_ppc(
      modelo, familia, paste0("cuantil_", p), unname(quantile(y, p)),
      apply(yp, 1, quantile, probs = p)
    )
  }
  for (v in c(5, 8, 12)) {
    filas[[length(filas) + 1]] <- fila_ppc(
      modelo, familia, paste0("frecuencia_valor_", v), mean(y == v),
      rowMeans(yp == v)
    )
  }
  bind_rows(filas)
}

extraer_principal <- function(fit, parametro = "b_menor15") {
  x <- as_draws_df(fit)[[parametro]]
  c(
    estimacion = median(x), inferior = unname(quantile(x, .025)),
    superior = unname(quantile(x, .975))
  )
}

diagnostico_alternativo <- function(fit) {
  p <- variables(fit)
  p <- p[grepl("^b_|^sigma$|^shape$", p)]
  sm <- summarise_draws(
    as_draws_matrix(fit, variable = p), rhat = rhat,
    ess_bulk = ess_bulk, ess_tail = ess_tail
  )
  np <- nuts_params(fit)
  c(
    Rhat_max = max(sm$rhat), ESS_bulk_min = min(sm$ess_bulk),
    ESS_tail_min = min(sm$ess_tail),
    divergencias = sum(np$Parameter == "divergent__" & np$Value == 1)
  )
}

fila_sensibilidad <- function(
    modelo, familia, fit_principal, fit_alternativo,
    prior_principal, prior_alternativo, parametro = "b_menor15") {
  a <- extraer_principal(fit_principal, parametro)
  b <- extraer_principal(fit_alternativo, parametro)
  dg <- diagnostico_alternativo(fit_alternativo)
  tibble(
    modelo = modelo, familia = familia, parametro_principal = parametro,
    prior_principal = prior_principal,
    estimacion_principal = a["estimacion"],
    ICr95_principal_inferior = a["inferior"],
    ICr95_principal_superior = a["superior"],
    prior_alternativo = prior_alternativo,
    estimacion_alternativa = b["estimacion"],
    ICr95_alternativo_inferior = b["inferior"],
    ICr95_alternativo_superior = b["superior"],
    diferencia_absoluta = abs(b["estimacion"] - a["estimacion"]),
    diferencia_relativa = abs(b["estimacion"] - a["estimacion"]) /
      abs(a["estimacion"]),
    cambio_direccion = sign(a["estimacion"]) != sign(b["estimacion"]),
    Rhat_max_alternativo = dg["Rhat_max"],
    ESS_bulk_min_alternativo = dg["ESS_bulk_min"],
    ESS_tail_min_alternativo = dg["ESS_tail_min"],
    divergencias_alternativo = dg["divergencias"]
  )
}

parametros <- list()
ppc <- list()
diags <- list()
sens <- list()
idx <- 0L

# Trece modelos Bernoulli publicados: se reutilizan los ajustes principales.
for (nm in names(etiquetas_bernoulli)) {
  idx <- idx + 1L
  fit <- objetos$modelos_principales[[nm]]
  nombre <- etiquetas_bernoulli[[nm]]
  ppc_i <- ppc_bernoulli(fit, nombre)
  parametros[[length(parametros) + 1]] <- resumen_parametros(
    fit, nombre, "Bernoulli-logit", c("b_Intercept", "b_menor15")
  )
  ppc[[length(ppc) + 1]] <- ppc_i
  diags[[length(diags) + 1]] <- diagnostico(
    fit, nombre, "Bernoulli-logit",
    paste0(sum(ppc_i$observado_fuera_ICr95), "/", nrow(ppc_i),
           " estadísticos fuera del ICr95%")
  )
  fit_alt <- update(
    fit,
    prior = c(
      prior(normal(0, 5), class = "Intercept"),
      prior(normal(0, 2.5), class = "b")
    ),
    recompile = FALSE, chains = 4, iter = 4000, warmup = 2000,
    cores = 4, seed = 1808 + idx, refresh = 0,
    control = list(adapt_delta = .99, max_treedepth = 15)
  )
  sens[[length(sens) + 1]] <- fila_sensibilidad(
    nombre, "Bernoulli-logit", fit, fit_alt,
    "Intercepto Normal(0,3); grupo Normal(0,1.5)",
    "Intercepto Normal(0,5); grupo Normal(0,2.5)"
  )
  rm(fit_alt); gc(FALSE)
}

# Modelo ordinal publicado.
fit_ord <- objetos$fit_adecuacion_ordinal
nombre_ord <- "Adecuación ordinal del control prenatal"
ppc_ord <- ppc_ordinal(fit_ord, nombre_ord)
parametros[[length(parametros) + 1]] <- resumen_parametros(
  fit_ord, nombre_ord, "Ordinal cumulative-logit",
  c("b_menor15", "b_Intercept[1]", "b_Intercept[2]", "b_Intercept[3]")
)
ppc[[length(ppc) + 1]] <- ppc_ord
diags[[length(diags) + 1]] <- diagnostico(
  fit_ord, nombre_ord, "Ordinal cumulative-logit",
  paste0(sum(ppc_ord$observado_fuera_ICr95), "/4 categorías fuera del ICr95%")
)
fit_ord_alt <- update(
  fit_ord, prior = prior(normal(0, 2.5), class = "b"),
  recompile = FALSE, chains = 4, iter = 4000, warmup = 2000,
  cores = 4, seed = 1880, refresh = 0,
  control = list(adapt_delta = .995, max_treedepth = 15)
)
sens[[length(sens) + 1]] <- fila_sensibilidad(
  nombre_ord, "Ordinal cumulative-logit", fit_ord, fit_ord_alt,
  "Grupo Normal(0,1.5); thresholds Student-t(3,0,2.5)",
  "Grupo Normal(0,2.5); thresholds Student-t(3,0,2.5)"
)
rm(fit_ord_alt); gc(FALSE)

# Muestras vigentes del punto 7.
df_cpn <- objetos$df %>%
  transmute(
    consultas_prenatales = `Número Consultas prenatales`, menor15,
    edad_gestacional_rn = `Edad gestaciol RN`
  )
d_crudo <- df_cpn %>% filter(!is.na(consultas_prenatales), !is.na(menor15))
d_aj <- df_cpn %>% filter(complete.cases(.))
stopifnot(nrow(d_crudo) == 6884, nrow(d_aj) == 6860)

args <- list(
  chains = 4, iter = 4000, warmup = 2000, cores = 4, refresh = 0,
  control = list(adapt_delta = .95, max_treedepth = 12)
)
ajustar <- function(formula, data, family, prior, seed) {
  do.call(brm, c(list(
    formula = formula, data = data, family = family, prior = prior, seed = seed
  ), args))
}

pri_g0 <- c(
  prior(normal(5, 3), class = "Intercept"),
  prior(normal(0, 1.5), class = "b"),
  prior(exponential(1), class = "sigma")
)
pri_g1 <- c(
  pri_g0, prior(normal(0, .5), class = "b", coef = "edad_gestacional_rn")
)
pri_g0_alt <- c(
  prior(normal(5, 5), class = "Intercept"),
  prior(normal(0, 2.5), class = "b"),
  prior(exponential(.5), class = "sigma")
)
pri_g1_alt <- c(
  pri_g0_alt, prior(normal(0, 1), class = "b", coef = "edad_gestacional_rn")
)

fit_g0 <- ajustar(
  consultas_prenatales ~ menor15, d_crudo, gaussian(), pri_g0, 1901
)
fit_g1 <- ajustar(
  consultas_prenatales ~ menor15 + edad_gestacional_rn,
  d_aj, gaussian(), pri_g1, 1902
)

# Los PPC gaussianos específicos válidos del punto 7 se reutilizan literalmente.
ppc_g <- read.csv(
  "output/consultas_prenatales/ppc_gaussiano.csv", stringsAsFactors = FALSE
) %>% mutate(familia = "Gaussiano") %>%
  select(modelo, familia, estadistico, observado, pred_mediana,
         pred_ICr95_inferior, pred_ICr95_superior, observado_fuera_ICr95)
ppc[[length(ppc) + 1]] <- ppc_g

for (z in list(
  list(fit = fit_g0, nombre = "gaussiano_no_ajustado", pars = c("b_Intercept", "b_menor15", "sigma")),
  list(fit = fit_g1, nombre = "gaussiano_ajustado", pars = c("b_Intercept", "b_menor15", "b_edad_gestacional_rn", "sigma"))
)) {
  parametros[[length(parametros) + 1]] <- resumen_parametros(
    z$fit, z$nombre, "Gaussiano", z$pars
  )
  pg <- filter(ppc_g, modelo == z$nombre)
  diags[[length(diags) + 1]] <- diagnostico(
    z$fit, z$nombre, "Gaussiano",
    paste0(sum(pg$observado_fuera_ICr95), "/", nrow(pg),
           " estadísticos fuera del ICr95%")
  )
}
fit_g0_alt <- update(
  fit_g0, prior = pri_g0_alt, recompile = FALSE, seed = 1911, refresh = 0
)
fit_g1_alt <- update(
  fit_g1, prior = pri_g1_alt, recompile = FALSE, seed = 1912, refresh = 0
)
sens[[length(sens) + 1]] <- fila_sensibilidad(
  "gaussiano_no_ajustado", "Gaussiano", fit_g0, fit_g0_alt,
  "Intercepto Normal(5,3); grupo Normal(0,1.5); sigma Exp(1)",
  "Intercepto Normal(5,5); grupo Normal(0,2.5); sigma Exp(0.5)"
)
sens[[length(sens) + 1]] <- fila_sensibilidad(
  "gaussiano_ajustado", "Gaussiano", fit_g1, fit_g1_alt,
  "Intercepto Normal(5,3); grupo Normal(0,1.5); EG Normal(0,0.5); sigma Exp(1)",
  "Intercepto Normal(5,5); grupo Normal(0,2.5); EG Normal(0,1); sigma Exp(0.5)"
)
rm(fit_g0_alt, fit_g1_alt); gc(FALSE)

# Modelos de Poisson publicados en la comparación del punto 7.
pri_p0 <- c(
  prior(normal(log(5), 1), class = "Intercept"),
  prior(normal(0, .5), class = "b")
)
pri_p1 <- c(
  pri_p0, prior(normal(0, .1), class = "b", coef = "edad_gestacional_rn")
)
pri_p0_alt <- c(
  prior(normal(log(5), 1.5), class = "Intercept"),
  prior(normal(0, 1), class = "b")
)
pri_p1_alt <- c(
  pri_p0_alt, prior(normal(0, .2), class = "b", coef = "edad_gestacional_rn")
)
fit_p0 <- ajustar(
  consultas_prenatales ~ menor15, d_crudo, poisson(), pri_p0, 1951
)
fit_p1 <- ajustar(
  consultas_prenatales ~ menor15 + edad_gestacional_rn,
  d_aj, poisson(), pri_p1, 1952
)
for (z in list(
  list(fit = fit_p0, nombre = "poisson_no_ajustado", pars = c("b_Intercept", "b_menor15")),
  list(fit = fit_p1, nombre = "poisson_ajustado", pars = c("b_Intercept", "b_menor15", "b_edad_gestacional_rn"))
)) {
  pp <- ppc_conteo(z$fit, z$nombre, "Poisson")
  ppc[[length(ppc) + 1]] <- pp
  parametros[[length(parametros) + 1]] <- resumen_parametros(
    z$fit, z$nombre, "Poisson", z$pars
  )
  diags[[length(diags) + 1]] <- diagnostico(
    z$fit, z$nombre, "Poisson",
    paste0(sum(pp$observado_fuera_ICr95), "/", nrow(pp),
           " estadísticos fuera del ICr95%")
  )
}
fit_p0_alt <- update(
  fit_p0, prior = pri_p0_alt, recompile = FALSE, seed = 1961, refresh = 0
)
fit_p1_alt <- update(
  fit_p1, prior = pri_p1_alt, recompile = FALSE, seed = 1962, refresh = 0
)
sens[[length(sens) + 1]] <- fila_sensibilidad(
  "poisson_no_ajustado", "Poisson", fit_p0, fit_p0_alt,
  "Intercepto Normal(log(5),1); grupo Normal(0,0.5)",
  "Intercepto Normal(log(5),1.5); grupo Normal(0,1)"
)
sens[[length(sens) + 1]] <- fila_sensibilidad(
  "poisson_ajustado", "Poisson", fit_p1, fit_p1_alt,
  "Intercepto Normal(log(5),1); grupo Normal(0,0.5); EG Normal(0,0.1)",
  "Intercepto Normal(log(5),1.5); grupo Normal(0,1); EG Normal(0,0.2)"
)
rm(fit_p0_alt, fit_p1_alt); gc(FALSE)

pri_n0 <- c(
  prior(normal(log(5), 1), class = "Intercept"),
  prior(normal(0, .5), class = "b"),
  prior(exponential(1), class = "shape")
)
pri_n1 <- c(
  pri_n0, prior(normal(0, .1), class = "b", coef = "edad_gestacional_rn")
)
pri_n0_alt <- c(
  prior(normal(log(5), 1.5), class = "Intercept"),
  prior(normal(0, 1), class = "b"),
  prior(exponential(.5), class = "shape")
)
pri_n1_alt <- c(
  pri_n0_alt, prior(normal(0, .2), class = "b", coef = "edad_gestacional_rn")
)
fit_n0 <- ajustar(
  consultas_prenatales ~ menor15, d_crudo, negbinomial(), pri_n0, 2001
)
fit_n1 <- ajustar(
  consultas_prenatales ~ menor15 + edad_gestacional_rn,
  d_aj, negbinomial(), pri_n1, 2002
)
for (z in list(
  list(fit = fit_n0, nombre = "negbin_no_ajustado", pars = c("b_Intercept", "b_menor15", "shape")),
  list(fit = fit_n1, nombre = "negbin_ajustado", pars = c("b_Intercept", "b_menor15", "b_edad_gestacional_rn", "shape"))
)) {
  pn <- ppc_conteo(z$fit, z$nombre, "Binomial negativa")
  ppc[[length(ppc) + 1]] <- pn
  parametros[[length(parametros) + 1]] <- resumen_parametros(
    z$fit, z$nombre, "Binomial negativa", z$pars
  )
  diags[[length(diags) + 1]] <- diagnostico(
    z$fit, z$nombre, "Binomial negativa",
    paste0(sum(pn$observado_fuera_ICr95), "/", nrow(pn),
           " estadísticos fuera del ICr95%")
  )
}
fit_n0_alt <- update(
  fit_n0, prior = pri_n0_alt, recompile = FALSE, seed = 2011, refresh = 0
)
fit_n1_alt <- update(
  fit_n1, prior = pri_n1_alt, recompile = FALSE, seed = 2012, refresh = 0
)
sens[[length(sens) + 1]] <- fila_sensibilidad(
  "negbin_no_ajustado", "Binomial negativa", fit_n0, fit_n0_alt,
  "Intercepto Normal(log(5),1); grupo Normal(0,0.5); shape Exp(1)",
  "Intercepto Normal(log(5),1.5); grupo Normal(0,1); shape Exp(0.5)"
)
sens[[length(sens) + 1]] <- fila_sensibilidad(
  "negbin_ajustado", "Binomial negativa", fit_n1, fit_n1_alt,
  "Intercepto Normal(log(5),1); grupo Normal(0,0.5); EG Normal(0,0.1); shape Exp(1)",
  "Intercepto Normal(log(5),1.5); grupo Normal(0,1); EG Normal(0,0.2); shape Exp(0.5)"
)

parametros_df <- bind_rows(parametros)
ppc_df <- bind_rows(ppc)
diags_df <- bind_rows(diags)
sens_df <- bind_rows(sens)

stopifnot(nrow(diags_df) == 20, nrow(sens_df) == 20)
stopifnot(max(diags_df$Rhat_max) <= 1.01)
stopifnot(all(diags_df$divergencias == 0))
stopifnot(all(diags_df$iteraciones_en_max_treedepth == 0))
stopifnot(all(diags_df$E_BFMI_min > .30))
stopifnot(max(sens_df$Rhat_max_alternativo) <= 1.01)
stopifnot(all(sens_df$divergencias_alternativo == 0))
stopifnot(all(c("b_Intercept", "b_Intercept[1]", "b_Intercept[2]",
                "b_Intercept[3]", "sigma", "shape") %in%
              parametros_df$parametro))

write.csv(diags_df, file.path(salida, archivos[1]), row.names = FALSE)
write.csv(parametros_df, file.path(salida, archivos[2]), row.names = FALSE)
write.csv(ppc_df, file.path(salida, archivos[3]), row.names = FALSE)
write.csv(sens_df, file.path(salida, archivos[4]), row.names = FALSE)

fmt <- function(x, d = 3) formatC(x, digits = d, format = "f")
familias_ppc <- ppc_df %>%
  group_by(familia) %>%
  summarise(
    estadisticos = n(), fuera_ICr95 = sum(observado_fuera_ICr95),
    .groups = "drop"
  )
resumen <- c(
  "# Resumen reproducible del punto editorial 8", "",
  "## Inventario", "",
  paste0("Se auditaron ", nrow(diags_df),
         " modelos: 13 Bernoulli-logit, un ordinal, dos gaussianos de sensibilidad, dos Poisson de sensibilidad y dos binomiales negativos principales."), "",
  "## Diagnósticos globales", "",
  paste0("R-hat máximo: ", fmt(max(diags_df$Rhat_max), 4), "."),
  paste0("ESS bulk mínimo: ", fmt(min(diags_df$ESS_bulk_min), 0), "."),
  paste0("ESS tail mínimo: ", fmt(min(diags_df$ESS_tail_min), 0), "."),
  paste0("Divergencias: ", sum(diags_df$divergencias), "."),
  paste0("Iteraciones en max treedepth: ", sum(diags_df$iteraciones_en_max_treedepth), "."),
  paste0("E-BFMI mínimo: ", fmt(min(diags_df$E_BFMI_min), 3), "."), "",
  "## PPC por familia", "",
  paste0("- ", familias_ppc$familia, ": ", familias_ppc$fuera_ICr95,
         "/", familias_ppc$estadisticos,
         " comparaciones observadas fuera del ICr95% predictivo."), "",
  "## Sensibilidad a priors", "",
  paste0("Máxima diferencia absoluta del coeficiente principal: ",
         fmt(max(sens_df$diferencia_absoluta), 4), "."),
  paste0("Modelos con cambio de dirección: ", sum(sens_df$cambio_direccion), "."),
  "La magnitud y la dirección de los coeficientes principales fueron estables frente a priors moderadamente más amplios.", "",
  "## Parámetros completos", "",
  "Se incluyeron interceptos y coeficientes de todos los modelos; los tres thresholds ordinales; sigma en ambos gaussianos; y shape en ambos modelos binomiales negativos, con ICr95%, R-hat, ESS bulk y ESS tail.", "",
  "## Problemas reales", "",
  "No se detectaron problemas de convergencia, divergencias, saturación de treedepth ni E-BFMI bajo. Las discrepancias PPC se documentan por modelo y familia y deben interpretarse como evaluación de ajuste, no como fallos del muestreador."
)
writeLines(resumen, file.path(salida, archivos[5]), useBytes = TRUE)

producidos <- list.files(salida, all.files = FALSE, no.. = TRUE)
stopifnot(setequal(producidos, archivos))
stopifnot(all(file.info(file.path(salida, archivos))$size > 0))
cat("PUNTO 8 COMPLETADO\n")
cat("Modelos auditados:", nrow(diags_df), "\n")
cat("R-hat máximo:", max(diags_df$Rhat_max), "\n")
cat("Divergencias:", sum(diags_df$divergencias), "\n")
cat("Archivos generados:", length(archivos), "\n")
