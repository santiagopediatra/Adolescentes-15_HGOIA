# Resumen reproducible del punto editorial 7

## Variable y distribución observada

Variable: `Número Consultas prenatales`. n válido=6884; faltantes=151; rango=0–20; media=5.714; mediana=6.000; varianza=7.663; DE=2.768; varianza/media=1.341; asimetría=0.442.

Posibles acumulaciones por criterio local: 12, 8, 5.
Límite superior de Tukey=14.000; observaciones por encima=53.

## Efectos estimados

Gaussiano no ajustado: diferencia de medias -0.561 (ICr95% -0.854 a -0.272).
Gaussiano ajustado por oportunidad acumulada: diferencia de medias -0.546 (ICr95% -0.828 a -0.275).
Poisson no ajustado: razón de medias 0.902 (ICr95% 0.860–0.943).
Poisson ajustado por oportunidad acumulada: razón de medias 0.903 (ICr95% 0.863–0.945).
Binomial negativa no ajustada: razón de medias 0.902 (ICr95% 0.856–0.953).
Binomial negativa ajustada por oportunidad acumulada: razón de medias 0.903 (ICr95% 0.857–0.949).

## Comparación predictiva

Mejor ELPD-LOO no ajustado: negbin_no_ajustado.
Mejor ELPD-LOO ajustado: negbin_ajustado.
La decisión debe integrar LOO y los PPC cuantitativos, no la significación estadística.

## Interpretación del ajuste

El ajuste por edad gestacional al parto se interpreta como un ajuste por oportunidad acumulada de recibir consultas prenatales, no como control causal de confusión ni como estimación de un efecto independiente.
