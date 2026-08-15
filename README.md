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

## Datos

- Base fuente requerida: `Adolescentes.csv`, 7.202 registros y 202 variables, UTF-8. No está incluida en este repositorio; su acceso requiere autorización previa del HGOIA. SHA-256 esperado de la copia utilizada: `159de79ef8311d1e5725dcbb55e4faff2281c8f3216dd87619be537111fe1609`.
- Base analítica: objeto `df` dentro de `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds`, 7.035 eventos obstétricos maternos.
- Submuestra neonatal: `df_neonatal`, creada por el pipeline, 6.790 nacimientos únicos.
- Registro de datos: Mendeley Data ("Embarazo adolescente")  Doi: 10.17632/jbbp5vb6fy.2.   En la descripcion se aclara: La base de datos individual no es de acceso público debido a restricciones institucionales y de confidencialidad. Los datos anonimizados podrán estar disponibles previa solicitud y autorización de la Unidad de Docencia e Investigación del Hospital Gineco-Obstétrico Isidro Ayora (HGOIA), conforme a los procedimientos institucionales vigentes. Los autores no tienen autoridad para conceder de forma independiente el acceso a la base.

La base está anonimizada, pero no se distribuye con el código. Una vez obtenida con autorización institucional, colóquela en la raíz con el nombre exacto `Adolescentes.csv` y verifique el checksum anterior. El archivo está ignorado por Git y no debe añadirse ni redistribuirse.

## Diccionario de datos

El borrador está en `data/DICCIONARIO_DATOS.csv` y se regenera con `Rscript R/01_generate_data_dictionary.R`.Consulte además `data/README_DATA.md`.

## Restricciones de uso

Los datos anonimizados utilizados en este estudio no se distribuyen mediante el repositorio de código. Su acceso requiere solicitud y autorización previa de la Unidad de Docencia e Investigación del Hospital Gineco-Obstétrico Isidro Ayora (HGOIA), conforme a los procedimientos y condiciones institucionales vigentes. Los autores no pueden conceder acceso de forma independiente. Debe mantenerse la anonimización y están prohibidos los intentos de reidentificación.

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
9. scripts de figuras y render/cotejo del manuscrito.

Una comprobación estructural sin recalcular Stan se ejecuta con `REPRO_VALIDATE_ONLY=true Rscript R/99_run_all.R`. El orden completo, entradas y productos están en `ORDEN_EJECUCION.md`.

## Semillas

- Análisis principal, Bernoulli, ordinal y sensibilidad de rezago: `1234`.
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
| Flujo 7.202 → 7.035 y Tabla S13 | `R/03_auditoria_gestaciones_multiples.R`, `R/09_sensibilidad_linkage_corregida.R` | `output/reconciliation/*` |
| Tabla 1 | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | XLSX: `Tabla1_binaria`, `Tabla1_continua`, categorías; RDS principal |
| Tabla 2 / modelos Bernoulli | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | XLSX: `Tabla2_RP_marginal`; RDS: `tabla2`, `modelos_principales` |
| Tablas S1–S4 | `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | Hojas del XLSX y objetos del RDS |
| Tablas S5–S7 | `R/04_punto6_atencion_prenatal.R` | `output/prenatal/*` |
| Tabla S8 / consultas | `R/05_punto7_consultas_prenatales.R` | `output/consultas_prenatales/*` |
| Tablas S9–S11 / diagnósticos y priors | `R/06_punto8_diagnosticos_priors.R` | `output/diagnosticos/*` |
| Tabla S12 / subperíodos | `R/07_punto9_heterogeneidad_temporal.R` | `output/heterogeneidad_temporal/*` |
| Tabla S14 / rezago | `R/08_punto4_sensibilidad_rezago_escolar.R` | `output/rezago_escolar/*` |
| Figura 1 | Fuente histórica localizada en Zenodo V1.0, no presente en el commit local auditado | `image1.png` existente; recuperación/reconciliación pendiente |
| Figura 2 | `Figura2_flujograma_STROBE.R` | `manuscript/media/media/image2.png` |
| Figura 3 | Fuente histórica localizada en Zenodo V1.0, no presente en el commit local auditado | `image3.jpeg` existente; recuperación/reconciliación pendiente |

## Licencia del código

El código y la documentación se publican bajo [CC BY 4.0](LICENSE), en continuidad con la licencia registrada para el software V2.0 en Zenodo. Esta licencia no se extiende a la base clínica individual, cuyo acceso permanece sujeto a autorización previa del HGOIA.

## Contacto

Santiago Vasco-Morales. Pediatra,PhD.  Hospital Gineco Obstétrico Isidro Ayora. correo: snvasco@uce.edu.ec < santiago.vasco@hgoia.gob.ec.
