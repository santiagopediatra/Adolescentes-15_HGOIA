# Lista de comprobación para el depósito Zenodo R2

## Archivos incluidos

- Código R principal, scripts auxiliares y orquestador.
- Fuente Quarto del manuscrito, bibliografía, CSL y Figuras 1–3.
- Resultados tabulares CSV/XLSX necesarios para auditoría.
- Diccionario y documentación de datos.
- `README.md`, `LICENSE`, `CITATION.cff`, `.zenodo.json`, orden de ejecución y validación.

## Archivos excluidos

- `Adolescentes.csv` y cualquier dato clínico individual.
- `*.rds`, checkpoints y ajustes Stan guardados.
- `.git/`, configuración local del editor y cachés.
- DOCX de revisión, cartas editoriales y carpetas de entrega redundantes.
- La carpeta pública R2 antigua, que no es la fuente canónica.

## Antes de pulsar «Publish»

- [ ] Confirmar el título y la lista completa de autores/creadores.
- [ ] Añadir ORCID de cada autor, si corresponde.
- [ ] Confirmar la afiliación institucional oficial.
- [ ] Confirmar que `R2` es la etiqueta de versión deseada.
- [ ] Revisar las condiciones vigentes del DOI de datos `10.17632/jbbp5vb6fy.2`.
- [ ] Ejecutar `REPRO_VALIDATE_ONLY=true Rscript R/99_run_all.R`.
- [ ] Comprobar el ZIP con `unzip -t` y revisar `MANIFEST_SHA256.txt`.
- [ ] Verificar que el ZIP no contiene CSV clínicos, RDS ni identificadores personales.
- [ ] Seleccionar licencia CC BY 4.0 en Zenodo, consistente con `LICENSE`.
- [ ] Relacionar el DOI anterior `10.5281/zenodo.21445981` como versión previa.
- [ ] Tras publicar, sustituir en el manuscrito el DOI antiguo por el DOI versionado R2.
- [ ] Añadir el DOI R2 a `CITATION.cff` y al README en una revisión posterior al depósito.

## Campos sugeridos en Zenodo

- Tipo: Software.
- Versión: R2.
- Idioma: español.
- Licencia: Creative Commons Attribution 4.0 International.
- Recurso relacionado: Mendeley Data `10.17632/jbbp5vb6fy.2` (`isSupplementTo`).
- Versión previa: Zenodo `10.5281/zenodo.21445981` (`isNewVersionOf`).

La publicación es una acción externa irreversible. El paquete queda preparado localmente, pero debe publicarse solo después de la revisión humana de autoría y metadatos.
