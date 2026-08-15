# Dependencias declarativas del proyecto.
# Este archivo NO instala ni actualiza paquetes.

required_packages <- c(
  "BayesFactor",
  "brms",
  "dplyr",
  "janitor",
  "loo",
  "magick",
  "openxlsx",
  "posterior",
  "purrr",
  "ragg",
  "readr",
  "stringr",
  "tibble",
  "tidyr"
)

optional_packages <- c(
  "bayesplot" # útil para inspección gráfica adicional de posteriores
)

missing_required_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
