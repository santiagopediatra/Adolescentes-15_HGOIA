# Datos del estudio

## Archivos y nivel de procesamiento

| Archivo | Registros aproximados | Nivel | Disponibilidad |
|---|---:|---|---|
| `Adolescentes.csv` | 7.202 | Base SIP fuente disponible al estudio, ya condicionada por admisión neonatal | Disponible en Mendeley Data; no duplicada en Git |
| `resultados_RBSMI_DEFINITIVO_CORREGIDO.rds` (`df`) | 7.035 | Base analítica materna después de duplicados exactos, consolidación de múltiples y restricción etaria | Presente localmente, ignorada por Git y regenerable por el pipeline principal |
| `df_neonatal` | 6.790 | Submuestra descriptiva de nacimientos únicos, creada en memoria excluyendo 245 embarazos múltiples | No se guarda como archivo independiente; se reconstruye por código |
| `data/DICCIONARIO_DATOS.csv` | 202 variables | Borrador de diccionario de la base fuente | Incluido; requiere revisión humana de etiquetas/códigos marcados `REVISION_MANUAL` |

## Relación entre la base fuente y la analítica

El flujo parte de 7.202 filas. Elimina 15 filas completamente duplicadas, agrupa las filas marcadas como gestaciones múltiples por una llave materna de 13 variables y las separa en eventos cuando dos edades gestacionales consecutivas difieren en al menos tres semanas. Tras consolidar 152 registros se obtienen 7.035 eventos obstétricos maternos. La descripción neonatal excluye los 245 eventos múltiples retenidos y utiliza 6.790 nacimientos únicos.

No hay una base anterior que contenga todos los partos adolescentes institucionales: la selección por admisión neonatal ocurrió antes del archivo disponible.

## Variables clave e identificadores

La base contiene variables maternas, reproductivas, obstétricas, de atención prenatal y neonatales. No existe un identificador único de parto o admisión. La consolidación usa año, edad materna, escolaridad, pareja estable, etnia, gestas, partos y cesáreas previas, embarazo planeado, anticoncepción, número de consultas, tipo de parto y cesárea, más edad gestacional.

No se observaron nombres, números de historia clínica u otros identificadores directos evidentes en los encabezados. El manuscrito y los metadatos del depósito describen la base como anonimizada. Aun así, se trata de datos clínicos individuales: no copie ni publique el archivo local fuera del depósito autorizado sin revisión humana de riesgo y condiciones.

## Registro y disponibilidad

- Registro de datos: [Mendeley Data, “Embarazo adolescente”, versión 1](https://doi.org/10.17632/jbbp5vb6fy.1).
- El DOI resolvió el 2026-08-15 a `https://data.mendeley.com/datasets/jbbp5vb6fy/1`.
- La base de datos anonimizada utilizada en el estudio está disponible públicamente en ese depósito bajo licencia CC BY 4.0.
- El archivo no se duplica en Git; debe descargarse desde el depósito oficial y guardarse en la raíz como `Adolescentes.csv`.

SHA-256 esperado de la copia auditada: `159de79ef8311d1e5725dcbb55e4faff2281c8f3216dd87619be537111fe1609`. Verifique cualquier descarga contra este valor antes de ejecutar el pipeline.
