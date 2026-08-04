library(dplyr)
library(stringr)

# Load and clean data like the main script
Adolescentes <- read.csv("Adolescentes.csv", fileEncoding = "UTF-8", check.names = FALSE, stringsAsFactors = FALSE)
names(Adolescentes) <- trimws(names(Adolescentes))
names(Adolescentes) <- gsub("[[:space:]]+", " ", names(Adolescentes))
Adolescentes <- distinct(Adolescentes)

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
    if (!is.na(eg_sorted[i]) && !is.na(eg_sorted[i - 1]) && (eg_sorted[i] - eg_sorted[i - 1]) >= umbral_semanas) {
      cl <- cl + 1L
    }
    cluster_sorted[i] <- cl
  }
  cluster_out <- integer(n)
  cluster_out[ord] <- cluster_sorted
  cluster_out
}

multiples_antes <- Adolescentes %>% filter(`Embarazo múltiple CODIGO` == 1)
multiples_dedup <- multiples_antes %>%
  group_by(across(all_of(vars_llave_madre))) %>%
  mutate(subgrupo_gestacional = asignar_cluster_gestacional(`Edad gestaciol RN`, umbral_semanas = 3)) %>%
  ungroup() %>%
  distinct(across(all_of(c(vars_llave_madre, "subgrupo_gestacional"))), .keep_all = TRUE)

Adolescentes_por_madre <- bind_rows(
  Adolescentes %>% filter(`Embarazo múltiple CODIGO` != 1 | is.na(`Embarazo múltiple CODIGO`)),
  multiples_dedup
) %>%
  filter(!is.na(`Edad materna`), `Edad materna` >= 10, `Edad materna` <= 19)

# Derived variables relevant for neonatal subset
Adolescentes_por_madre <- Adolescentes_por_madre %>%
  mutate(
    menor15 = if_else(`Edad materna` < 15, 1L, 0L),
    grupo_edad = factor(
      if_else(menor15 == 1, "10–14 años", "15–19 años"),
      levels = c("15–19 años", "10–14 años")
    ),
    embarazo_multiple = as.integer(`Embarazo múltiple CODIGO`),
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
      str_to_lower(str_trim(`Lactancia exclusiva SI NO`)) %in% c("si", "sí") ~ 1L,
      str_to_lower(str_trim(`Lactancia exclusiva SI NO`)) == "no" ~ 0L,
      TRUE ~ NA_integer_
    )
  )

# Neonatal-only subset

df_neonatal <- Adolescentes_por_madre %>%
  filter(embarazo_multiple != 1 | is.na(embarazo_multiple))

cat("n final por madre/parto:", nrow(Adolescentes_por_madre), "\n")
cat("multiples en la muestra materna:", sum(Adolescentes_por_madre$embarazo_multiple == 1, na.rm = TRUE), "\n")
cat("n nacimientos únicos para descripción neonatal:", nrow(df_neonatal), "\n")
cat("n nacimientos únicos por grupo etario:\n")
print(df_neonatal %>% count(grupo_edad))
cat("\nDenominadores por variable neonatal:\n")
vars_neonatales <- c("prematuro", "apgar1_bajo", "apgar5_bajo", "peg", "macrosomico", "ictericia_neonatal", "rn_vivo", "lactancia_exclusiva")
for (v in vars_neonatales) {
  nval <- sum(!is.na(df_neonatal[[v]]))
  cat(v, ":", nval, "\n")
}
