# Adolescentes de 10–14 frente a 15–19 años en el HGOIA

Material reproducible del estudio **«Diferencias sociodemográficas, reproductivas y obstétricas entre adolescentes de 10–14 años y de 15–19 años en una población hospitalaria seleccionada por admisión neonatal: estudio transversal retrospectivo»**.

El estudio utiliza registros del Sistema de Información Perinatal del Hospital Gineco-Obstétrico Isidro Ayora (HGOIA), Quito, Ecuador, correspondientes a enero de 2009–junio de 2024. La base accesible al equipo ya estaba restringida a madres cuyos recién nacidos habían sido admitidos en Neonatología; este repositorio no reproduce esa selección previa ni representa todos los partos adolescentes institucionales.

## Contenido del depósito

| Ruta | Contenido |
|---|---|
| `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | Pipeline estadístico principal |
| `R/` | Configuración, diccionario, auditorías, sensibilidades, diagnósticos y orquestador |
| `data/` | Diccionario y documentación de datos; no contiene registros individuales |
| `output/` | Resultados tabulares reproducibles y diagnósticos; se excluyen objetos RDS pesados |
| `manuscript/` | Fuente Quarto y las tres figuras finales |
| `Figura1_marco_seleccion_EN.R` | Fuente reproducible de la Figura 1 |
| `Figura2_flujograma_STROBE.R` | Fuente reproducible de la Figura 2 |
| `Figura3_distribucion_anual_EN.R` | Fuente reproducible de la Figura 3 |
| `resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx` | Libro de resultados validado |
| `ORDEN_EJECUCION.md` | Dependencias y orden detallado del análisis |
| `sessionInfo_R2.txt` | Entorno de software auditado |
| `CITATION.cff` | Metadatos de citación |

Las carpetas locales de entrega editorial, copias DOCX, checkpoints, ajustes Stan guardados y la base clínica no forman parte del depósito público. Son documentos de trabajo, copias redundantes o artefactos regenerables.

## Diseño y flujo analítico

El flujo observado es:

1. 7.202 registros madre–recién nacido disponibles.
2. Eliminación de 15 duplicados exactos: 7.187 registros.
3. Consolidación de registros de gestaciones múltiples mediante una llave materna de 13 variables y un umbral de edad gestacional de tres semanas.
4. Muestra analítica final: 7.035 eventos obstétricos maternos (386 de 10–14 años y 6.649 de 15–19 años).
5. Submuestra neonatal descriptiva: 6.790 nacimientos únicos, tras excluir 245 gestaciones múltiples.

No existe un identificador único de parto o admisión. Consulte el manuscrito y `ORDEN_EJECUCION.md` para conocer las reglas completas y sus limitaciones.

## Datos y confidencialidad

El depósito de código **no incluye `Adolescentes.csv` ni ninguna base individual**. El registro externo asociado es Mendeley Data, DOI [`10.17632/jbbp5vb6fy.2`](https://doi.org/10.17632/jbbp5vb6fy.2). Antes de obtener o reutilizar datos, consulte en ese registro las condiciones vigentes y las autorizaciones institucionales aplicables. Los autores no conceden acceso por medio de este repositorio.

Para una reproducción autorizada, la copia auditada debe guardarse en la raíz con el nombre `Adolescentes.csv`. Su huella esperada es:

```text
SHA-256  159de79ef8311d1e5725dcbb55e4faff2281c8f3216dd87619be537111fe1609
Filas     7.202
Columnas  202
Codificación UTF-8
```

El diccionario está en `data/DICCIONARIO_DATOS.csv`. Algunos campos marcados `REVISION_MANUAL` conservan advertencias que requieren comprobación humana contra la documentación institucional del SIP.

No intente reidentificar personas ni combine estos datos con otras fuentes para ese fin.

## Requisitos

- R 4.5.0 (entorno auditado).
- Paquetes declarados en `R/requirements_packages.R`.
- `brms`/Stan y una cadena de compilación C++ funcional para los modelos bayesianos.
- Quarto para renderizar el manuscrito.
- `ragg` y `magick` para las figuras.

Las versiones auditadas se encuentran en `sessionInfo_R2.txt`. No se incluye `renv.lock`; por ello, una reproducción futura puede presentar pequeñas diferencias numéricas o de renderizado entre versiones de software.

## Reproducción

Ejecute los comandos desde la raíz del proyecto.

### Validación rápida sin datos ni ajuste de modelos

```bash
REPRO_VALIDATE_ONLY=true Rscript R/99_run_all.R
```

Esta comprobación valida la presencia y sintaxis de los scripts; no reproduce resultados estadísticos.

### Reproducción completa

Con una copia autorizada de `Adolescentes.csv`:

```bash
Rscript R/99_run_all.R
```

La ejecución completa vuelve a ajustar modelos Stan y puede tardar varias horas. El orquestador ejecuta, en orden, el diccionario, el pipeline principal, la reconciliación, las sensibilidades, los diagnósticos y las tres figuras. Los resultados se escriben en `output/`; los objetos grandes se mantienen fuera del depósito.

Las tablas del archivo Quarto son estáticas: renderizar el QMD no recalcula ni inserta automáticamente los resultados. Deben cotejarse con el XLSX y los CSV generados antes de una nueva versión editorial.

Para el orden detallado, las entradas y los productos de cada paso, consulte [`ORDEN_EJECUCION.md`](ORDEN_EJECUCION.md).

## Figuras

```bash
Rscript Figura1_marco_seleccion_EN.R
Rscript Figura2_flujograma_STROBE.R
Rscript Figura3_distribucion_anual_EN.R
```

Los archivos finales se escriben en `manuscript/media/media/`. Los conteos de las Figuras 2 y 3 están codificados a partir de los resultados validados y deben cotejarse si cambia la base o el pipeline.

## Semillas

- Análisis principal y sensibilidad de rezago escolar: `1234`.
- Modelos de consultas prenatales: `1707`.
- Diagnósticos y sensibilidad a priors: base `1808`.
- Heterogeneidad temporal: base `1909`, con semillas derivadas dentro del script.

## Alcance reproducible

El depósito permite auditar el código, las reglas de construcción, las figuras y los resultados tabulares distribuidos. La reproducción completa requiere acceso autorizado al archivo fuente y recursos suficientes para Stan. No reproduce el mecanismo clínico previo que determinó la admisión neonatal.

## Citación

Use los metadatos de `CITATION.cff`. Cuando Zenodo asigne el DOI de esta versión, cite preferentemente el DOI versionado del depósito y el artículo asociado.

## Licencia

El código y la documentación se distribuyen bajo [CC BY 4.0](LICENSE). Esta licencia no concede acceso a datos clínicos ni reemplaza las condiciones del depósito de datos o las autorizaciones del HGOIA.

## Contacto

Santiago Vasco-Morales<br>
Hospital Gineco-Obstétrico Isidro Ayora, Quito, Ecuador<br>
`snvasco@uce.edu.ec` · `santiago.vasco@hgoia.gob.ec`
