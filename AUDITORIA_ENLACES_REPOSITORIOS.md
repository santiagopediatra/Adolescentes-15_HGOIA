# Auditoría de enlaces de repositorios

Verificación externa: 2026-08-15. No se modificó ningún archivo Word.

| Ubicación | Texto actual | URL/DOI actual | Estado | Corrección propuesta |
|---|---|---|---|---|
| `manuscript/Adolescentes_19_julio.qmd`, disponibilidad de datos | Base anonimizada en Mendeley Data | `https://doi.org/10.17632/jbbp5vb6fy.1` | El DOI resuelve, pero DataCite todavía muestra acceso abierto/CC BY 4.0, contrario al acceso institucional controlado informado por el HGOIA | Sustituir la declaración por acceso previa solicitud/autorización y verificar la corrección externa antes del envío |
| DOCX limpio, disponibilidad de datos | Igual que QMD | `https://doi.org/10.17632/jbbp5vb6fy.1` | El hipervínculo resuelve, pero la declaración de acceso debe actualizarse | Corregir en el Word final solo después de confirmar los metadatos externos |
| `manuscript/Adolescentes_19_julio.qmd`, código | Scripts en Zenodo | `https://doi.org/10.5281/zenodo.21445981.` | El punto final está incluido en el texto subrayado; DOI resuelve a Zenodo V1.0 | Quitar el punto de la URL y dejarlo fuera del enlace; actualizar al DOI de la release R2 cuando exista |
| DOCX limpio, código | Scripts en Zenodo | `https://doi.org/10.5281/zenodo.21445981.` | El texto aparece, pero `document.xml.rels` no contiene una relación de hipervínculo para Zenodo | Tras aprobación, crear hipervínculo real y quitar el punto final del destino |
| Zenodo V1.0 | Código del proyecto | `10.5281/zenodo.21445981` | Resuelve; publicado 2026-07-19; CC BY 4.0; enlaza GitHub `V1.0` | No sustituye aún el depósito R2: su ZIP solo contiene el pipeline antiguo y dos scripts de figuras más el PPTX |
| Metadatos Zenodo | Repositorio GitHub | `https://github.com/santiagopediatra/Adolescentes_HGOIA` | Enlace declarado en metadatos; Zenodo archivó la etiqueta/rama `V1.0` | Publicar y archivar una release nueva después de validación; sugerencia `v2.0-R2` |
| `README.md` anterior y copia pública parcial | DOI de datos y código | Ambos DOI | Enlaces correctos pero declarados como pendientes de verificación | Actualizar con la verificación y advertir que V1.0 es incompleto para la solicitud actual |
| Carta-respuesta Markdown y DOCX | No se encontró sección con DOI de datos/código | Ninguno | Inconsistente con la nueva solicitud editorial | Añadir, tras aprobación, una respuesta que cite ambos depósitos y la release R2 definitiva |
| Material suplementario DOCX | No se encontraron enlaces de repositorio | Ninguno | No necesariamente requerido, pero debe ser consistente si incluye disponibilidad | Añadir solo si la revista exige repetir la declaración |

## Plan de cambios en documentos (pendiente de aprobación)

1. En el manuscrito, indicar que los datos requieren autorización previa del HGOIA y que los autores no conceden acceso de forma independiente.
2. En el manuscrito QMD y los dos DOCX revisados, convertir el DOI de código en hipervínculo real y excluir el punto final del destino.
3. Después de crear y validar una release R2, sustituir el DOI de versión `10.5281/zenodo.21445981` por el DOI específico de la nueva versión; conservar el DOI conceptual si se desea enlazar siempre la versión más reciente.
4. Añadir a la carta-respuesta una frase verificable con las condiciones de acceso a datos, el DOI de código R2 y el contenido reproducible del depósito.
5. No modificar Word hasta confirmar los DOI y condiciones definitivos.
