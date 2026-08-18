# Orden de ejecución reproducible

Ejecutar siempre desde la raíz del repositorio. La base accesible ya está condicionada por admisión neonatal; no existe en este repositorio una base anterior ni un script que reproduzca esa selección clínica.

## Pipeline real observado

`Adolescentes.csv` (base SIP disponible, 7.202 filas)
→ duplicados exactos con `distinct()` (7.187)
→ agrupamiento de registros marcados como gestación múltiple mediante llave materna de 13 variables
→ separación de eventos dentro de cada llave por saltos consecutivos de edad gestacional ≥3 semanas
→ consolidación a una fila por llave/subgrupo y restricción a edad materna 10–19
→ `df` (7.035 eventos obstétricos maternos)
→ `df_neonatal` (6.790 nacimientos únicos para descriptivos, excluyendo 245 múltiples)
→ descriptivos, modelos, sensibilidades, diagnósticos y figuras.

## Orden canónico

| Paso | Comando/script | Entradas | Productos principales |
|---:|---|---|---|
| 0 | `source("R/00_config.R")` | Ninguna | Semillas y rutas documentadas; no escribe datos |
| 1 | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | `Adolescentes.csv` | `resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx`, `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds`, checkpoints F/G/I/J/K; Tabla 1, Tabla 2, modelos principales y sensibilidad por subperíodos |
| 2 | `R/03_auditoria_gestaciones_multiples.R` | `Adolescentes.csv` | `output/reconciliation/reconciliation_summary.csv`, conteos etarios, denominadores neonatales, sensibilidad 2/3/4 semanas y RDS de auditoría |
| 3 | `R/09_sensibilidad_linkage_corregida.R` | CSV y resultados principales | `output/reconciliation/sensibilidad_linkage_CORREGIDA.csv`, `output/logs/AUDITORIA_EJECUTADO.txt` |
| 4 | `R/04_punto6_atencion_prenatal.R` | CSV y RDS principal | `output/prenatal/`: regla de contactos y análisis binario de adecuación prenatal usado en la Tabla 2 |
| 5 | `R/05_punto7_consultas_prenatales.R` | CSV y RDS principal | `output/consultas_prenatales/`: distribución, heaping, modelos gaussiano/Poisson/binomial negativo, PPC y LOO |
| 6 | `R/06_punto8_diagnosticos_priors.R` | RDS principal y `output/consultas_prenatales/ppc_gaussiano.csv` | Tablas S6–S8: diagnósticos completos, parámetros posteriores, PPC y sensibilidad a priors |
| 7 | `R/10_sensibilidad_priors_rezago_edad5.R` | RDS principal y salida del paso 6 | Corrige en Tabla S8 la fila de rezago para el modelo principal edad−5 |
| 8 | `R/07_punto9_heterogeneidad_temporal.R` | RDS principal | Tabla S10: interacción, estimaciones por período y comparación LOO |
| 9 | `R/08_punto4_sensibilidad_rezago_escolar.R` | CSV | Regla principal edad−5 y sensibilidad edad−6, diagnósticos y PPC |
| 10 | `Figura2_flujograma_STROBE.R` | Ninguna; usa conteos codificados que deben cotejarse | `manuscript/media/media/image2.png` |
| 11 | Scripts originales faltantes de Figuras 1 y 3 | Por recuperar | `image1.png` e `image3.jpeg` |
| 12 | Render del manuscrito vigente | Fuente del manuscrito, CSL, bibliografía y figuras | DOCX; las tablas deben cotejarse con S1–S10 |

El comando coordinador es:

```r
source("R/99_run_all.R")
```

La ejecución completa vuelve a ajustar modelos Stan y puede tardar horas. Para comprobar solo estructura, dependencias, hashes y sintaxis sin recalcular modelos se puede usar:

```bash
REPRO_VALIDATE_ONLY=true Rscript R/99_run_all.R
```

Ese modo de validación no sustituye la reproducción estadística completa.

## Dependencias críticas

- Los pasos 4–9 requieren `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds`, producido en el paso 1.
- El paso 6 requiere que el paso 5 haya producido `ppc_gaussiano.csv`.
- Los scripts 03 y 09 vuelven a construir la desduplicación directamente desde el CSV y sirven como verificación independiente del objeto `df`.
- No se debe ejecutar un script desde otra carpeta: las rutas están definidas respecto de la raíz.
