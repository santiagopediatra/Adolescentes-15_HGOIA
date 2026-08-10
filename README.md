# Adolescentes-15_HGOIA

Paquete reproducible del manuscrito sobre eventos obstétricos maternos en adolescentes atendidas en el HGOIA. Versión auditada: **R2, 2026-08-07**, correspondiente al commit base `5db11b9` más los ajustes finales no comprometidos descritos por `git diff`.

## Datos y objetos analíticos

- Base fuente local: `Adolescentes.csv` (7.202 registros; anonimizada; no versionada por `.gitignore`).
- Base analítica: objeto `df` de `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds` (7.035 eventos obstétricos maternos).
- Submuestra neonatal descriptiva: `df_neonatal`, construida por `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` al excluir 245 embarazos múltiples (6.790 nacimientos únicos).
- Resultados tabulares principales: `resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx` y `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds`.

La base publicada se cita en el manuscrito mediante Mendeley Data (versión 1, DOI `10.17632/jbbp5vb6fy.1`). Antes del reenvío debe comprobarse que esa versión coincide byte a byte o mediante una suma de verificación con la base utilizada localmente.

El depósito asociado en Zenodo se identifica con el DOI `10.5281/zenodo.21445981`. La correspondencia de los depósitos de Mendeley Data y Zenodo con la versión final es **PENDIENTE DE VERIFICACIÓN EXTERNA**; no puede establecerse únicamente desde este repositorio.

### Disponibilidad local auditada para R2

- `Adolescentes.csv`: **disponible localmente**; 7.202 registros iniciales; SHA-256 `159de79ef8311d1e5725dcbb55e4faff2281c8f3216dd87619be537111fe1609`.
- `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds`: **ausente**; debe contener el objeto `df` con 7.035 eventos obstétricos maternos.
- `resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx`: **ausente**.
- Submuestra neonatal esperada: 6.790 nacimientos únicos.

## Scripts, tablas, figuras y outputs

| Script | Producto |
|:--|:--|
| `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | Depuración, desduplicación, Tabla 1, Tabla 2, Tablas S1–S4 y objetos/modelos base; genera el XLSX y RDS definitivos. |
| `R/03_auditoria_gestaciones_multiples.R` | Reconciliación del flujo, conteos etarios, denominadores neonatales por variable/grupo y sensibilidad del linkage; genera `output/reconciliation/`. |
| `R/04_punto6_atencion_prenatal.R` | Regla de contactos, análisis binario/ordinal, thresholds y odds proporcionales; genera Tablas S5–S7 y `output/prenatal/`. |
| `R/05_punto7_consultas_prenatales.R` | Comparación gaussiana, Poisson y binomial negativa, PPC y LOO; genera Tabla S8 y `output/consultas_prenatales/`. |
| `R/06_punto8_diagnosticos_priors.R` | Diagnósticos, parámetros posteriores, PPC y sensibilidad a priors; genera Tablas S9–S11 y `output/diagnosticos/`. |
| `R/07_punto9_heterogeneidad_temporal.R` | Interacciones grupo × período y LOO; genera Tabla S12 y `output/heterogeneidad_temporal/`. |
| `R/08_punto4_sensibilidad_rezago_escolar.R` | Reproduce el indicador principal de rezago y ejecuta la sensibilidad edad − 5 con tope 12; genera la Tabla S14 y `output/rezago_escolar/`. |
| `Figura1_marco_conceptual.R` | `Figura1_diagrama_conceptual_seleccion.png`, incorporada como Figura 1. |
| `Grafico_años .R` | Figura anual; el archivo final incorporado en el manuscrito es `manuscript/media/media/image3.jpeg`. |
| Quarto | `manuscript/Adolescentes_19_julio.qmd` genera `manuscript/Adolescentes_19_julio.docx`. Las Figuras 1–3 incorporadas son `image1.png`, `image2.png` e `image3.jpeg`. |

`output/referencias/auditoria_referencias.csv` documenta la revisión bibliográfica. Los CSV versionados con Git LFS deben estar materializados y no ser simples punteros antes de distribuir el paquete.

## Software principal

R con `dplyr`, `tidyr`, `purrr`, `stringr`, `janitor`, `readr`, `openxlsx`, `brms`, `posterior`, `BayesFactor`, `loo` y `bayesplot`; CmdStan/Stan como backend de los modelos bayesianos; y Quarto para generar el DOCX. Las versiones exactas no están fijadas en un archivo `renv.lock`, por lo que deben registrarse con `sessionInfo()` antes del depósito final.

## Orden reproducible

Desde la raíz del repositorio y con `Adolescentes.csv` disponible:

1. `Rscript ANALISIS_ADOLESCENTES_CORREGIDO_v3.R`
2. `Rscript R/03_auditoria_gestaciones_multiples.R`
3. `Rscript R/04_punto6_atencion_prenatal.R`
4. `Rscript R/05_punto7_consultas_prenatales.R`
5. `Rscript R/06_punto8_diagnosticos_priors.R`
6. `Rscript R/07_punto9_heterogeneidad_temporal.R`
7. `Rscript R/08_punto4_sensibilidad_rezago_escolar.R`
8. Generar o verificar las figuras con sus scripts fuente.
9. `quarto render manuscript/Adolescentes_19_julio.qmd`
10. Verificar `git diff --check` y cotejar el DOCX, las tablas del QMD y todos los CSV contra los outputs anteriores.

Los scripts 04–07 reutilizan `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds`; por ello el script principal debe ejecutarse primero. Los valores publicados en el QMD son tablas estáticas y deben cotejarse contra los outputs: no se insertan dinámicamente durante el render.

En la auditoría local R2 se encontraron los scripts `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R`, `R/03_auditoria_gestaciones_multiples.R`, `R/04_punto6_atencion_prenatal.R`, `R/05_punto7_consultas_prenatales.R`, `R/06_punto8_diagnosticos_priors.R`, `R/07_punto9_heterogeneidad_temporal.R` y `Figura2_flujograma_STROBE.R`. No se encontraron localmente `Figura1_marco_conceptual.R` ni `Grafico_años .R`; no se recrearon.
