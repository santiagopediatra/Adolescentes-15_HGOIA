# Validación de reproducibilidad del repositorio

Fecha: 2026-08-15
Estado final: **REPRODUCIBLE_CON_ADVERTENCIAS**

## Alcance ejecutado

| Prueba/script | Resultado |
|---|---|
| `REPRO_VALIDATE_ONLY=true Rscript R/99_run_all.R` | Correcto: localizó la raíz, comprobó archivos/paquetes y analizó la sintaxis de todos los scripts canónicos |
| `Rscript R/01_generate_data_dictionary.R` | Correcto: 202 variables documentadas; dudas marcadas `REVISION_MANUAL` |
| `Rscript R/03_auditoria_gestaciones_multiples.R` | Correcto: reprodujo 7.202 iniciales, 15 duplicados, 152 consolidaciones, 7.035 eventos y 245 múltiples |
| `Rscript R/09_sensibilidad_linkage_corregida.R` | Correcto: llave exacta 7.048; umbral 1 semana 7.047; 2 semanas 7.041; principal 3 semanas 7.035; todos producen 6.790 nacimientos únicos |
| Lectura de `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds` | Correcto: `df` tiene 7.035 filas y 234 variables; contiene tablas, 13 modelos principales y ajustes prenatal/ordinal |
| Cotejo XLSX ↔ RDS | Valores coincidentes en las 12 hojas. Diez fueron idénticas con tolerancia `1e-12`; las dos tablas categóricas solo difieren en que XLSX importa `categoria` como texto y RDS la conserva como factor ordenado |
| Diagnósticos guardados | 20 modelos; R-hat máximo 1,001783; ESS bulk mínimo 4.181,934; ESS tail mínimo 4.568,046; 0 divergencias; 0 iteraciones en treedepth máximo; E-BFMI mínimo 0,9090904 |
| Rutas absolutas en scripts R | No se encontraron rutas `/home/...` ni rutas Windows |
| `git diff --check` | Sin errores de espacios después de normalizar el archivo de sesión; el README conserva un salto final estándar |

## Resultados reproducidos/comprobados

- Flujo de desduplicación y consolidación completo.
- Conteos etarios y denominadores maternos/neonatales.
- Sensibilidades de linkage.
- Integridad interna entre el RDS y el XLSX validados.
- Presencia y criterios de R-hat, ESS bulk/tail, divergencias, treedepth, E-BFMI y PPC.
- Versiones de R y paquetes cargados.
- Resolución de los DOI de datos y código, además del contenido del ZIP público de código.

## No reejecutado

No se reestimaron los modelos Stan durante esta auditoría. Una corrida completa puede tardar horas y sobrescribir los artefactos validados de la raíz antes de copiarlos a `output/main/`. El maestro quedó preparado para esa validación final controlada, pero la comparación realizada utilizó los modelos y resultados guardados.

Tampoco se renderizó el DOCX porque el usuario solicitó revisar primero el plan de enlaces y porque las tablas del QMD son estáticas.

## Advertencias y estado actualizado para R2

1. Las fuentes vigentes de las tres figuras están disponibles como `Figura1_marco_seleccion_EN.R`, `Figura2_flujograma_STROBE.R` y `Figura3_distribucion_anual_EN.R`. Fueron regeneradas y sincronizadas con el manuscrito durante la preparación de R2.
2. `readr` informó problemas de parseo al leer la base en `R/03_...`; los conteos y resultados esperados se reprodujeron. Conviene guardar y revisar `problems()` en una futura mejora sin cambiar el análisis validado.
3. La documentación R2 referencia Mendeley Data versión 2, DOI `10.17632/jbbp5vb6fy.2`. No se verificó en esta actualización el archivo remoto byte a byte contra la copia auditada; el README conserva el checksum esperado.
4. No existe `renv.lock`; la sesión está documentada, pero el entorno no está congelado.
5. Zenodo V1.0 contiene solo el pipeline antiguo, dos scripts históricos de figuras y el PPTX; no satisface la solicitud editorial R2. Debe crearse una release nueva tras revisión.
6. Después de completar las pruebas, `Adolescentes.csv` fue eliminado localmente por solicitud expresa del usuario. Para una nueva ejecución debe obtenerse con autorización del HGOIA, guardarse temporalmente en la raíz y coincidir con el SHA-256 documentado.

## Diferencias numéricas

No se encontraron diferencias numéricas entre las hojas del XLSX principal y los objetos correspondientes del RDS. La única diferencia del cotejo fue de clase de datos (factor ordenado frente a texto) en las columnas `categoria` de dos hojas.

## Criterio final

**REPRODUCIBLE_CON_ADVERTENCIAS**: el flujo determinista, la trazabilidad tabular, el entorno, las tres figuras y el orquestador están documentados; quedan pendientes una corrida Stan completa desde un entorno limpio y la comprobación exacta de la base externa autorizada.
