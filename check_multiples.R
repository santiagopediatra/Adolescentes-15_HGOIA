library(dplyr)
library(stringr)
df <- read.csv("Adolescentes.csv", fileEncoding = "UTF-8", check.names = FALSE, stringsAsFactors = FALSE)
names(df) <- trimws(names(df))
names(df) <- gsub("[[:space:]]+", " ", names(df))
df <- distinct(df)
vars_llave_madre <- c("Año", "Edad materna", "Años estudios mayor nivel", "PAREJA ESTABLE CODIGO", "ETNIA CODIGO", "Numero gestas previas", "Numero de Partos previos", "Cesáreas previas CODIGO", "Embarazo planeado CODIGO", "ANTICONCEPTIVO CODIGO", "Número Consultas prenatales", "TIPO DE PARTO", "CESAREA")
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

cat("n filas crudas iniciales:\t", nrow(df), "\n")
cat("embarazos múltiples (raw):\t", sum(df$`Embarazo múltiple CODIGO` == 1, na.rm = TRUE), "\n")
cat("filas únicas tras distinct():\t", nrow(df), "\n")

multiples_antes <- df %>% filter(`Embarazo múltiple CODIGO` == 1)
cat("raw multiples rows:\t", nrow(multiples_antes), "\n")
cat("raw multiples unique mother keys:\t", nrow(distinct(multiples_antes, across(all_of(vars_llave_madre)))), "\n")

multiples_dedup <- multiples_antes %>% group_by(across(all_of(vars_llave_madre))) %>% mutate(subgrupo_gestacional = asignar_cluster_gestacional(`Edad gestaciol RN`, umbral_semanas = 3)) %>% ungroup() %>% distinct(across(all_of(c(vars_llave_madre, "subgrupo_gestacional"))), .keep_all = TRUE)
cat("multiples dedup rows:\t", nrow(multiples_dedup), "\n")
cat("multiples dedup unique mother+cluster keys:\t", nrow(distinct(multiples_dedup, across(all_of(c(vars_llave_madre, "subgrupo_gestacional"))))), "\n")

Adolescentes_por_madre <- bind_rows(
  df %>% filter(`Embarazo múltiple CODIGO` != 1 | is.na(`Embarazo múltiple CODIGO`)),
  multiples_dedup
) %>% filter(!is.na(`Edad materna`), `Edad materna` >= 10, `Edad materna` <= 19)

cat("n final por madre/parto:\t", nrow(Adolescentes_por_madre), "\n")
cat("multiples in final data:\t", sum(Adolescentes_por_madre$`Embarazo múltiple CODIGO` == 1, na.rm = TRUE), "\n")
cat("unique mother keys in final data:\t", nrow(distinct(Adolescentes_por_madre, across(all_of(vars_llave_madre)))), "\n")
cat("multiple pregnancies by age group:\n")
print(Adolescentes_por_madre %>% mutate(grupo = if_else(`Edad materna` < 15, '10-14', '15-19')) %>% count(grupo, `Embarazo múltiple CODIGO`))

vars_neonatales <- c("PREMATURO CODIGO","CODIGO Apgar 1 minuto <7","CODIGO Apgar 5to. < 7","RCIU","MACROSÓMICO","BEBE Ictericia","RN vivo CODIGO","Lactancia exclusiva SI NO")
for (v in vars_neonatales) {
  nval <- sum(!is.na(Adolescentes_por_madre[[v]]))
  cat(v, "validos final:\t", nval, "\n")
}
