## Sensibilidad del indicador de rezago escolar

**Panel A. Años esperados según edad**

| **Edad (años)** | **Regla principal: edad − 5, tope 12** | **Regla alternativa: edad − 6, tope 12** |
|---:|---:|---:|
| 10 | 5 | 4 |
| 11 | 6 | 5 |
| 12 | 7 | 6 |
| 13 | 8 | 7 |
| 14 | 9 | 8 |
| 15 | 10 | 9 |
| 16 | 11 | 10 |
| 17 | 12 | 11 |
| 18 | 12 | 12 |
| 19 | 12 | 12 |

**Panel B. Comparación del indicador binario de rezago ≥2 años**

| **Regla** | **n total** | **Prevalencia 10–14** | **Prevalencia 15–19** | **RP (ICr95 %)** | **R-hat máx.** | **ESS bulk mín.** | **ESS tail mín.** | **Divergencias** | **E-BFMI mín.** | **PPC fuera del ICr95 %** |
|:--|--:|--:|--:|:--|--:|--:|--:|--:|--:|--:|
| Principal: edad − 5; tope 12 | 7.027 | 41,6 % | 18,2 % | 2,28 (1,99–2,59) | 1,0008 | 5.791 | 5.665 | 0 | 0,947 | 0/3 |
| Sensibilidad: edad − 6; tope 12 | 7.027 | 34,6 % | 16,6 % | 2,07 (1,78–2,41) | 1,0002 | 6.150 | 5.698 | 0 | 0,961 | 0/3 |

Ambas reglas utilizaron el mismo cálculo de años aprobados, tope de 12 años, tratamiento de datos faltantes, definición binaria (rezago ≥2 años) y modelo bayesiano Bernoulli-logit con estandarización posterior. En ambos ajustes la profundidad máxima observada fue 4, ninguna iteración alcanzó el máximo configurado de 15 y los PPC de las prevalencias global y por grupo quedaron dentro del ICr95 % predictivo. Fuente reproducible: `R/08_punto4_sensibilidad_rezago_escolar.R` y `output/rezago_escolar/`.

