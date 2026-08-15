# Auditoría del repositorio para reproducibilidad editorial

Fecha de auditoría: 2026-08-15
Rama auditada: `agent/r2-para-compartir`
Commit de partida: `5b16d9a`

## Estado inicial de Git

`git status --short --branch` mostró la rama sincronizada con `origin/agent/r2-para-compartir` y 37 archivos ya añadidos al índice dentro de `carpeta_repositorio_publico_R2/` y `entrega_R2_final/`. Esos cambios preceden esta auditoría y se preservaron. No se hizo commit ni push.

## Inventario funcional

| Archivo | Función | Necesario para reproducibilidad | Estado | Acción propuesta |
|---|---|---:|---|---|
| `Adolescentes.csv` | Base fuente SIP disponible: 7.202 registros y 202 columnas | Sí, o su copia autorizada idéntica | Disponible durante la auditoría inicial y eliminada posteriormente por solicitud del usuario; ignorada por Git; declarada anonimizada | Solicitar autorización al HGOIA y verificar SHA-256 antes de reproducir |
| `ANALISIS_ADOLESCENTES_CORREGIDO_v3.R` | Pipeline principal: limpieza, duplicados exactos, consolidación de múltiples, variables derivadas, Tabla 1, modelos Bernoulli, modelo ordinal, consultas prenatales gaussianas, subperíodos, tablas y exportación | Sí | Disponible; mezcla varias etapas; usa rutas relativas; semilla 1234 | Conservar lógica; invocar desde el maestro y documentar entradas/salidas |
| `R/03_auditoria_gestaciones_multiples.R` | Auditoría dedicada de desduplicación, consolidación, denominadores neonatales y sensibilidad de umbrales 2/3/4 semanas | Sí | Disponible; reproduce el algoritmo principal | Documentar como script específico de desduplicación/consolidación |
| `R/09_sensibilidad_linkage_corregida.R` | Sensibilidad corregida de linkage: llave exacta y umbrales 1/2/3 semanas | Sí | Disponible; incluye comprobaciones 7.202 → 7.187 → 7.035 | Ejecutar tras el pipeline principal y conservar como sensibilidad validada |
| `R/04_punto6_atencion_prenatal.R` | Regla de contactos; análisis binario y ordinal; thresholds; sensibilidad de odds proporcionales | Sí | Disponible; depende de CSV y RDS principal | Ejecutar después del pipeline principal |
| `R/05_punto7_consultas_prenatales.R` | Modelos gaussiano, Poisson y binomial negativo; distribución, PPC y LOO | Sí | Disponible; binomial negativo es principal y los otros son sensibilidades | Ejecutar antes de diagnósticos globales |
| `R/06_punto8_diagnosticos_priors.R` | R-hat, ESS, divergencias, treedepth, E-BFMI, PPC, parámetros y sensibilidad a priors | Sí | Disponible; depende del RDS y del PPC gaussiano | Ejecutar después de `R/05_...` |
| `R/07_punto9_heterogeneidad_temporal.R` | Modelos aditivos e interacción por subperíodos; estimaciones marginales y LOO | Sí | Disponible; semillas 1909–2110 | Documentar como análisis por subperíodos/sensibilidad temporal |
| `R/08_punto4_sensibilidad_rezago_escolar.R` | Regla principal edad−6 y sensibilidad edad−5, con diagnósticos y PPC | Sí | Disponible; semilla 1234 | Ejecutar y cotejar Tabla S14 |
| `Figura2_flujograma_STROBE.R` | Regenera la Figura 2 (`image2.png`) | Sí | Disponible | Invocar desde el maestro en una fase opcional de figuras |
| `Figura1_marco_conceptual.R` | Fuente declarada para Figura 1 | Sí | No encontrado | Recuperar del equipo/depósito que produjo `image1.png`; no reconstruir sin fuente |
| `Grafico_años .R` | Fuente declarada para Figura 3 | Sí | No encontrado | Recuperar del equipo/depósito que produjo `image3.jpeg`; no reconstruir sin fuente |
| `check_multiples.R` | Comprobación exploratoria de múltiples | No, si se conserva `R/03_...` | Disponible; auxiliar y parcialmente redundante | Mantener como auxiliar, no incluir en el flujo canónico |
| `run_neonatal_check.R` | Comprobación exploratoria de la submuestra neonatal | No, si se conserva `R/03_...` | Disponible; auxiliar | Mantener como auxiliar, no incluir en el flujo canónico |
| `resultados_RBSMI_DEFINITIVO_CORREGIDO.xlsx` | Libro validado con Tabla 1, Tabla 2 y tablas suplementarias base | Sí, para cotejo | Disponible y versionado | Tratar como referencia validada y comparar tras reproducción |
| `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds` | Base analítica `df`, tablas y modelos principales guardados | Sí para scripts 04–07; regenerable con alto costo | Disponible localmente; ignorado por `*.rds` | No eliminar; documentar checksum y condición de distribución |
| `checkpoint_F_descriptivos.rds` | Checkpoint de descriptivos | Conveniente | Disponible, ignorado | No publicar salvo necesidad; regenerable |
| `checkpoint_G_modelos_principales.rds` | Checkpoint incremental de modelos principales | Conveniente | Disponible, ignorado; no contiene todos los ajustes Stan | No publicar salvo necesidad; regenerable |
| `checkpoint_I_adecuacion_ordinal.rds` | Checkpoint del modelo ordinal | Conveniente | Disponible, ignorado | No publicar salvo necesidad; regenerable |
| `checkpoint_J_tabla_cpn.rds` | Checkpoint de tabla de consultas | Conveniente | Disponible, ignorado | No publicar salvo necesidad; regenerable |
| `checkpoint_K_sensibilidad.rds` | Checkpoint de sensibilidad por subperíodos | Conveniente | Disponible, ignorado | No publicar salvo necesidad; regenerable |
| `output/reconciliation/` | Conteos, denominadores y sensibilidades de desduplicación | Sí | Disponible y versionado | Mantener y regenerar |
| `output/prenatal/` | Resultados de atención prenatal | Sí | Disponible y versionado | Mantener y regenerar |
| `output/consultas_prenatales/` | Resultados de modelos de conteo | Sí | Disponible y versionado | Mantener y regenerar |
| `output/diagnosticos/` | Diagnósticos MCMC, PPC, parámetros y priors | Sí | Disponible y versionado | Mantener y regenerar |
| `output/heterogeneidad_temporal/` | Resultados por subperíodos e interacción | Sí | Disponible y versionado | Mantener y regenerar |
| `output/rezago_escolar/` | Sensibilidad de rezago escolar | Sí | Disponible y versionado | Mantener y regenerar |
| `manuscript/Adolescentes_19_julio.qmd` | Fuente editable del manuscrito y tablas estáticas | Sí | Disponible; no inserta outputs automáticamente | Documentar cotejo manual; no cambiar resultados |
| `manuscript/Adolescentes_19_julio.docx` | Manuscrito limpio generado/validado | Sí, editorial | Disponible | No modificar antes de aprobar el plan de enlaces |
| `manuscript/Adolescentes_19_julio_R2_cambios.docx` | Manuscrito con cambios | Sí, editorial | Disponible | No modificar antes de aprobar el plan de enlaces |
| `manuscript/Material_Suplementario_R2.docx` | Material suplementario | Sí, editorial | Disponible | Auditar correspondencia con outputs |
| `Carta de Respuesta.md` | Fuente legible de la carta-respuesta | Sí | Disponible | Documentar correcciones de repositorios; no alterar resultados |
| `entrega_R2_final/*.docx` | Paquete editorial final y original preservado | Sí, para entrega/cotejo | Disponible; ya añadido al índice antes de esta auditoría | No modificar sin aprobación humana |
| `manuscript/media/media/image1.png` | Figura 1 incorporada | Sí | Disponible; falta script fuente | Recuperar script original |
| `manuscript/media/media/image2.png` | Figura 2 incorporada | Sí | Disponible con script fuente | Regenerable |
| `manuscript/media/media/image3.jpeg` | Figura 3 incorporada | Sí | Disponible; falta script fuente | Recuperar script original |
| `README.md` | Guía existente | Sí | Disponible pero desactualizada sobre RDS/XLSX y scripts de figuras | Reescribir con orden, datos, semillas, versiones, restricciones y trazabilidad |
| `data/README_DATA.md` | README específico de datos | Sí | No existe | Crear sin copiar datos |
| `data/DICCIONARIO_DATOS.csv` | Diccionario de datos | Sí | No existe | Crear borrador sustentado en nombres, tipos y scripts; marcar dudas `REVISION_MANUAL` |
| `sessionInfo_R2.txt` | Versiones de software | Sí | Existe, pero solo incluye R base y `compiler` | Regenerar cargando los paquetes requeridos |
| `renv.lock` | Entorno fijado | Recomendable, no obligatorio | No existe | No instalar ni migrar automáticamente |
| `R/requirements_packages.R` | Lista declarativa de dependencias | Sí | No existe | Crear sin instalar paquetes |
| `R/00_config.R` | Configuración central de semillas/rutas | Sí | No existe | Crear preservando las semillas históricas reales |
| `R/99_run_all.R` | Orquestador reproducible | Sí | No existe | Crear con comprobaciones, logs y fases; no modificar datos fuente |
| `CITATION.cff` | Citación del repositorio | Sí | No existe | Crear solo con título y autoría verificable disponible |
| `.gitignore` | Exclusiones de datos, RDS, cachés y temporales | Sí | Disponible; patrón `*.rds` también excluye artefactos que pueden ser necesarios | Proponer reglas más explícitas sin borrar archivos |
| `carpeta_repositorio_publico_R2/` | Copia parcial preparada para depósito | No como duplicado interno | Incompleta: omite pipeline principal, datos/documentación y varios outputs | No usar como fuente canónica; regenerar paquete solo tras validación |

## Hallazgos de trazabilidad

- No se encontró un script de «selección por admisión neonatal»: esa selección ocurrió antes de la base accesible. El primer archivo observado ya contiene únicamente madres cuyos recién nacidos fueron admitidos en Neonatología. Inventar una etapa de selección reproducible sería incorrecto.
- Las exclusiones ejecutadas por código son: 15 duplicados exactos y restricción a edades maternas de 10–19 años; en los conteos validados, la base fuente ya cumple el rango etario.
- La llave de consolidación contiene 13 variables maternas. Dentro de cada llave, los registros múltiples se ordenan por edad gestacional y se separan cuando la diferencia entre valores consecutivos es mayor o igual a 3 semanas.
- Resultado validado: 7.202 registros iniciales → 7.187 tras duplicados exactos → 7.035 eventos obstétricos maternos (386 de 10–14; 6.649 de 15–19) → 6.790 nacimientos únicos para descriptivos neonatales (381 y 6.409).
- No hay identificador único de parto/admisión. La documentación debe conservar esta limitación y evitar afirmar linkage determinístico perfecto.
- La base no contiene nombres, números de historia clínica ni identificadores directos evidentes en los encabezados; aun así, es información clínica individual y no debe publicarse desde esta copia local sin confirmar las condiciones del depósito de datos.
- El QMD contiene tablas estáticas: renderizarlo no recalcula ni inserta automáticamente las salidas analíticas.

## Semillas encontradas

- Pipeline principal, Bernoulli, ordinal, gaussianos y sensibilidad de rezago: `1234`.
- Consultas prenatales (Poisson/binomial negativa y ajustes relacionados): `1707`.
- Diagnósticos y sensibilidad de priors: base `1808`, con semillas derivadas por modelo.
- Heterogeneidad temporal: `1909`, semillas derivadas `1909 + i`, `2009 + i`, `2109` y `2110`.
- Los scripts de desduplicación no requieren aleatoriedad.

## Riesgos pendientes

1. Faltan los scripts originales de las Figuras 1 y 3; por ello el depósito aún no reproduce todas las figuras.
2. La base y el RDS principal están ignorados por Git. El DOI externo debe confirmarse y el RDS debe regenerarse o distribuirse de forma controlada.
3. El DOI de Zenodo mostrado en el DOCX limpio no está codificado como hipervínculo, aunque el texto sí aparece.
4. La restricción institucional fue confirmada posteriormente por el responsable del proyecto: el acceso a los datos requiere autorización previa de la Unidad de Docencia e Investigación del HGOIA y los autores no pueden concederlo de forma independiente.
5. La ejecución completa de Stan es costosa; la validación debe distinguir comprobaciones rápidas de una reproducción completa.
