# Adolescentes 10–14 vs 15–19 años: perfil sociodemográfico y obstétrico

## Objetivo del repositorio

Este repositorio contiene el código necesario para reproducir el flujo observado de depuración y selección analítica, la eliminación de duplicados exactos, la consolidación de gestaciones múltiples, las tablas, los modelos principales, las sensibilidades, los diagnósticos y las figuras disponibles del estudio hospitalario del HGOIA.

La base accesible ya estaba restringida a madres cuyos recién nacidos fueron admitidos en Neonatología. El repositorio no contiene todos los partos adolescentes institucionales ni un script que pueda reproducir esa selección previa.

## Estructura

- `R/`: configuración, diccionario, auditorías, análisis editoriales, sensibilidades, diagnósticos y script maestro.
- `data/`: README de datos y borrador reproducible del diccionario; no contiene una copia adicional de la base clínica.
- `output/`: resultados tabulares por componente, diagnósticos y logs.
- `manuscript/`: fuente Quarto, documentos y figuras incorporadas.
- `entrega_R2_final/`: documentos editoriales preparados antes de esta auditoría.
- `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R`: pipeline estadístico principal validado.
- `AUDITORIA_REPOSITORIO_REPRODUCIBILIDAD.md`: inventario y estado de cada artefacto.
- `ORDEN_EJECUCION.md`: dependencias y orden canónico detallado.
- `VALIDACION_REPRODUCIBILIDAD_REPOSITORIO.md`: alcance y resultado de las pruebas realizadas.

## Requisitos

- R 4.5.0 (versión del entorno auditado).
- Paquetes enumerados, sin instalación automática, en `R/requirements_packages.R`.
- Stan mediante `brms`/`rstan` y una cadena de compilación C++ funcional.
- Quarto para renderizar el manuscrito; las tablas del QMD son estáticas y deben cotejarse con los outputs.

No existe `renv.lock` y no se creó ni migró un entorno automáticamente. Las versiones auditadas se encuentran en `sessionInfo_R2.txt`. Para instalar dependencias en un entorno controlado, revise `required_packages` y use su mecanismo institucional habitual; no se instalan paquetes desde el pipeline.

### Versiones de R y paquetes

El entorno utilizado para la reproducción auditada fue R 4.5.0 sobre Debian GNU/Linux 13. Las versiones de las dependencias declaradas en `R/requirements_packages.R` fueron:

| Paquete | Versión auditada | Uso |
|---|---:|---|
| `BayesFactor` | 0.9.12-4.8 | Análisis bayesianos auxiliares |
| `brms` | 2.23.0 | Ajuste de modelos bayesianos con Stan |
| `dplyr` | 1.2.1 | Transformación de datos |
| `janitor` | 2.2.1 | Limpieza y tabulación |
| `loo` | 2.10.1 | Comparación predictiva mediante LOO |
| `magick` | 2.8.5 | Procesamiento de imágenes |
| `openxlsx` | 4.2.8 | Escritura de libros XLSX |
| `posterior` | 1.7.0 | Resúmenes y diagnósticos posteriores |
| `purrr` | 1.0.4 | Programación funcional |
| `ragg` | 1.3.3 | Dispositivo gráfico |
| `readr` | 2.2.0 | Lectura y escritura de archivos tabulares |
| `stringr` | 1.6.0 | Procesamiento de texto |
| `tibble` | 3.2.1 | Estructuras tabulares |
| `tidyr` | 1.3.2 | Reestructuración de datos |
| `bayesplot` | 1.15.0 | Inspección gráfica opcional de posteriores |

El inventario completo, incluidas las dependencias transitivas, BLAS, LAPACK, plataforma y configuración regional, está disponible en [`sessionInfo_R2.txt`](sessionInfo_R2.txt).

## Datos

- Base fuente requerida: `Adolescentes.csv`, 7.202 registros y 202 variables, UTF-8. La base de datos anonimizada utilizada en el estudio está disponible en Mendeley Data, DOI [10.17632/jbbp5vb6fy.2](https://doi.org/10.17632/jbbp5vb6fy.2), bajo licencia CC BY 4.0. SHA-256 esperado de la copia utilizada: `159de79ef8311d1e5725dcbb55e4faff2281c8f3216dd87619be537111fe1609`.
- Base analítica: objeto `df` dentro de `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds`, 7.035 eventos obstétricos maternos.
- Submuestra neonatal: `df_neonatal`, creada por el pipeline, 6.790 nacimientos únicos.
La base no se duplica en el repositorio de código. Descárguela desde Mendeley Data, colóquela en la raíz con el nombre exacto `Adolescentes.csv` y verifique el checksum anterior. El archivo está ignorado por Git para evitar mantener copias divergentes del depósito de datos oficial.

## Diccionario de datos

El borrador está en `data/DICCIONARIO_DATOS.csv` y se regenera con `Rscript R/01_generate_data_dictionary.R`.Consulte además `data/README_DATA.md`.

## Uso de los datos

La base pública está anonimizada y se distribuye bajo las condiciones de la licencia CC BY 4.0 indicada en Mendeley Data. Debe preservarse la anonimización y no deben realizarse intentos de reidentificación.

Nota:La base de datos individual no es de acceso público debido a restricciones institucionales y de confidencialidad. Los datos anonimizados podrán ser utilizados previa solicitud y autorización de la Unidad de Docencia e Investigación del Hospital Gineco-Obstétrico Isidro Ayora (HGOIA), conforme a los procedimientos institucionales vigentes. Los autores no tienen autoridad para conceder de forma independiente el acceso a la base.

## Reproducibilidad

Desde la raíz: `Rscript R/99_run_all.R`.

1. `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R`
2. `R/03_auditoria_gestaciones_multiples.R`
3. `R/09_sensibilidad_linkage_corregida.R`
4. `R/04_punto6_atencion_prenatal.R`
5. `R/05_punto7_consultas_prenatales.R`
6. `R/06_punto8_diagnosticos_priors.R`
7. `R/07_punto9_heterogeneidad_temporal.R`
8. `R/08_punto4_sensibilidad_rezago_escolar.R`
9. `R/10_sensibilidad_priors_rezago_edad5.R`
10. scripts de figuras y render/cotejo del manuscrito.

Una comprobación estructural sin recalcular Stan se ejecuta con `REPRO_VALIDATE_ONLY=true Rscript R/99_run_all.R`. El orden completo, entradas y productos están en `ORDEN_EJECUCION.md`.

## Semillas

- Análisis principal, modelos Bernoulli y sensibilidad de rezago: `1234`.
- Modelos de consultas prenatales: `1707`.
- Diagnósticos/sensibilidad a priors: base `1808`, con semillas derivadas dentro del script.
- Heterogeneidad temporal: base `1909`, con `1909 + i`, `2009 + i`, `2109` y `2110`.

`R/00_config.R` registra estas semillas sin reemplazar las especificaciones históricas de los modelos.

## Resultados esperados

- Libro y objeto principales: `resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx` y `.rds`; el maestro también copia ambos a `output/main/`.
- Desduplicación: `output/reconciliation/`.
- Atención prenatal: `output/prenatal/` y `output/consultas_prenatales/`.
- Diagnósticos: `output/diagnosticos/`.
- Subperíodos: `output/heterogeneidad_temporal/`.
- Sensibilidad de rezago: `output/rezago_escolar/`.
- Figuras incorporadas: `manuscript/media/media/`.

## Correspondencia manuscrito–código

| Elemento del manuscrito | Script | Archivo generado |
|---|---|---|
| Flujo 7.202 → 7.035 y reconciliación de denominadores | `R/03_auditoria_gestaciones_multiples.R`, `R/09_sensibilidad_linkage_corregida.R` | `output/reconciliation/*` |
| Tabla 1 | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | XLSX: `Tabla1_binaria`, `Tabla1_continua`, categorías; RDS principal |
| Tabla 2 / modelos Bernoulli | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | XLSX: `Tabla2_RP_marginal`; RDS: `tabla2`, `modelos_principales` |
| Tablas S1–S4 | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | Hojas del XLSX y objetos del RDS |
| Construcción binaria de adecuación prenatal usada en Tabla 2 | `R/04_punto6_atencion_prenatal.R` | `output/prenatal/*` |
| Tabla S5 / comparación de modelos de consultas | `R/05_punto7_consultas_prenatales.R` | `output/consultas_prenatales/*` |
| Tabla S6 / diagnósticos | `R/06_punto8_diagnosticos_priors.R` | `output/diagnosticos/diagnosticos_completos.csv`, `ppc_modelos.csv` |
| Tabla S7 / parámetros posteriores | `R/06_punto8_diagnosticos_priors.R` | `output/diagnosticos/parametros_posteriores.csv` |
| Tabla S8 / sensibilidad a priors | `R/06_punto8_diagnosticos_priors.R`, `R/10_sensibilidad_priors_rezago_edad5.R` | `output/diagnosticos/sensibilidad_priors.csv` |
| Tabla S9 / datos faltantes | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | RDS: `tabla_faltantes`, `tabla_completitud` |
| Tabla S10 / heterogeneidad temporal | `R/07_punto9_heterogeneidad_temporal.R` | `output/heterogeneidad_temporal/*` |
| Definición principal edad−5 y sensibilidad edad−6 del rezago escolar | `R/08_punto4_sensibilidad_rezago_escolar.R` | `output/rezago_escolar/*` |
| Figura 1 | Fuente histórica localizada en Zenodo V1.0, no presente en el commit local auditado | `image1.png` existente; recuperación/reconciliación pendiente |
| Figura 2 | `Figura2_flujograma_STROBE.R` | `manuscript/media/media/image2.png` |
| Figura 3 | Fuente histórica localizada en Zenodo V1.0, no presente en el commit local auditado | `image3.jpeg` existente; recuperación/reconciliación pendiente |

## Licencia del código

El código y la documentación se publican bajo [CC BY 4.0](LICENSE). La base anonimizada se encuentra en Mendeley Data y está sujeta a la licencia indicada en ese depósito.

## Contacto

Santiago Vasco-Morales. Pediatra,PhD.  Hospital Gineco Obstétrico Isidro Ayora. correo: snvasco@uce.edu.ec < santiago.vasco@hgoia.gob.ec.
