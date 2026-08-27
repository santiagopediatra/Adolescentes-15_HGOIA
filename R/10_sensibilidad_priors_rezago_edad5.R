#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(brms)
  library(dplyr)
  library(posterior)
})

set.seed(1819)
options(mc.cores = 4)

objetos <- readRDS("resultados_RBSMI_DEFINITIVO_CORREGIDO.rds")
df <- objetos$df %>%
  mutate(
    anios_aprobados = case_when(
      `Estudios CODIGO` == 0 ~ 0,
      `Estudios CODIGO` == 1 ~ `Años estudios mayor nivel`,
      `Estudios CODIGO` == 2 ~ 9 + `Años estudios mayor nivel`,
      `Estudios CODIGO` == 3 ~ 12 + `Años estudios mayor nivel`,
      TRUE ~ NA_real_
    ),
    anios_escolaridad_esperados_edad5 = pmin(pmax(`Edad materna` - 5, 0), 12),
    rezago_escolar_anios_edad5 =
      anios_escolaridad_esperados_edad5 - anios_aprobados,
    rezago_escolar_bin_edad5 = case_when(
      is.na(rezago_escolar_anios_edad5) ~ NA_integer_,
      rezago_escolar_anios_edad5 >= 2 ~ 1L,
      TRUE ~ 0L
    )
  )

datos <- df %>%
  transmute(y = rezago_escolar_bin_edad5, menor15 = as.integer(menor15)) %>%
  filter(!is.na(y), !is.na(menor15))

stopifnot(nrow(datos) == 7027L)

fit_base <- objetos$modelos_principales[["rezago_escolar_bin"]]

ajustar <- function(priors, semilla, iteraciones = 4000, calentamiento = 2000) {
  update(
    fit_base,
    newdata = datos,
    prior = priors,
    recompile = FALSE,
    chains = 4, iter = iteraciones, warmup = calentamiento,
    cores = 4, seed = semilla, refresh = 500,
    control = list(adapt_delta = 0.99, max_treedepth = 15)
  )
}

fit_principal <- ajustar(c(
  prior(normal(0, 3), class = "Intercept"),
  prior(normal(0, 1.5), class = "b")
), 1234, iteraciones = 6000, calentamiento = 3000)

fit_alternativo <- ajustar(c(
  prior(normal(0, 5), class = "Intercept"),
  prior(normal(0, 2.5), class = "b")
), 1820)

extraer <- function(fit, tipo_prior) {
  x <- as_draws_df(fit)$b_menor15
  data.frame(
    modelo = "Rezago escolar binario — modelo principal edad−5",
    tipo_prior = tipo_prior,
    estimacion = median(x),
    ICr95_inferior = unname(quantile(x, 0.025)),
    ICr95_superior = unname(quantile(x, 0.975)),
    Rhat = rhat(x),
    ESS_bulk = ess_bulk(x),
    ESS_tail = ess_tail(x)
  )
}

resultado <- bind_rows(
  extraer(fit_principal, "Prior principal"),
  extraer(fit_alternativo, "Prior alternativo")
) %>%
  mutate(cambio_direccion =
           sign(estimacion[1]) != sign(estimacion[2]))

write.csv(
  resultado,
  "output/diagnosticos/sensibilidad_priors_rezago_edad5.csv",
  row.names = FALSE
)

# R/06 genera el inventario global a partir del objeto histórico, cuyo desenlace
# de rezago usa edad−6. Sustituir únicamente esa fila por el ajuste final edad−5.
archivo_global <- "output/diagnosticos/sensibilidad_priors.csv"
if (file.exists(archivo_global)) {
  global <- read.csv(archivo_global, check.names = FALSE)
  i <- which(grepl("^Rezago escolar binario", global$modelo))
  stopifnot(length(i) == 1L)
  global$modelo[i] <- "Rezago escolar binario — modelo principal edad−5"
  global$estimacion_principal[i] <- resultado$estimacion[1]
  global$ICr95_principal_inferior[i] <- resultado$ICr95_inferior[1]
  global$ICr95_principal_superior[i] <- resultado$ICr95_superior[1]
  global$estimacion_alternativa[i] <- resultado$estimacion[2]
  global$ICr95_alternativo_inferior[i] <- resultado$ICr95_inferior[2]
  global$ICr95_alternativo_superior[i] <- resultado$ICr95_superior[2]
  global$diferencia_absoluta[i] <-
    abs(resultado$estimacion[2] - resultado$estimacion[1])
  global$diferencia_relativa[i] <-
    global$diferencia_absoluta[i] / abs(resultado$estimacion[1])
  global$cambio_direccion[i] <- resultado$cambio_direccion[1]
  global$Rhat_max_alternativo[i] <- resultado$Rhat[2]
  global$ESS_bulk_min_alternativo[i] <- resultado$ESS_bulk[2]
  global$ESS_tail_min_alternativo[i] <- resultado$ESS_tail[2]
  global$divergencias_alternativo[i] <- sum(
    nuts_params(fit_alternativo)$Parameter == "divergent__" &
      nuts_params(fit_alternativo)$Value == 1
  )
  write.csv(global, archivo_global, row.names = FALSE)
}

saveRDS(
  list(principal = fit_principal, alternativo = fit_alternativo),
  "output/diagnosticos/sensibilidad_priors_rezago_edad5.rds"
)

print(resultado)
