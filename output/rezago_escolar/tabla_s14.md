## Tabla S14. Regla de años esperados y sensibilidad del indicador de rezago escolar {#tabla-s14.-sensibilidad-rezago-escolar .unnumbered}

**Panel A. Años esperados según edad**

| **Edad (años)** | **Regla principal: edad − 6, tope 12** | **Regla alternativa: edad − 5, tope 12** |
|---:|---:|---:|
| 10 | 4 | 5 |
| 11 | 5 | 6 |
| 12 | 6 | 7 |
| 13 | 7 | 8 |
| 14 | 8 | 9 |
| 15 | 9 | 10 |
| 16 | 10 | 11 |
| 17 | 11 | 12 |
| 18 | 12 | 12 |
| 19 | 12 | 12 |

**Panel B. Comparación del indicador binario de rezago ≥2 años**

| **Regla** | **n total** | **Prevalencia 10–14** | **Prevalencia 15–19** | **RP (ICr95 %)** | **R-hat máx.** | **ESS bulk mín.** | **ESS tail mín.** | **Divergencias** | **E-BFMI mín.** | **PPC fuera del ICr95 %** |
|:--|--:|--:|--:|:--|--:|--:|--:|--:|--:|--:|
| Principal: edad − 6; tope 12 | 7.027 | 34,6 % | 16,6 % | 2,07 (1,78–2,41) | 1,0002 | 6.150 | 5.698 | 0 | 0,961 | 0/3 |
| Sensibilidad: edad − 5; tope 12 | 7.027 | 41,6 % | 18,2 % | 2,28 (1,99–2,59) | 1,0008 | 5.791 | 5.665 | 0 | 0,947 | 0/3 |

Ambas reglas utilizaron el mismo cálculo de años aprobados, tope de 12 años, tratamiento de datos faltantes, definición binaria (rezago ≥2 años) y modelo bayesiano Bernoulli-logit con estandarización posterior. En ambos ajustes la profundidad máxima observada fue 4, ninguna iteración alcanzó el máximo configurado de 15 y los PPC de las prevalencias global y por grupo quedaron dentro del ICr95 % predictivo. Fuente reproducible: `R/08_punto4_sensibilidad_rezago_escolar.R` y `output/rezago_escolar/`.

