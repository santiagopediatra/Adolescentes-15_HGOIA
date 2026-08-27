# Resumen reproducible del punto editorial 6

## Regla operacional

La variable observada es `Número Consultas prenatales` y la edad gestacional es `Edad gestaciol RN`. Los contactos esperados son 1, 2, 3, 4, 5, 6, 7 y 8 para <20, 20–<26, 26–<30, 30–<34, 34–<36, 36–<38, 38–<40 y ≥40 semanas, respectivamente. Sin controles = 0; inadecuado = >0 y <50%; intermedio = 50–<80%; adecuado = ≥80%.

## Jerarquía analítica

El análisis principal es `Control prenatal adecuado: sí/no`, porque mantiene el estimando RP y la diferencia de prevalencias usado para las demás características binarias de la Tabla 2. La adecuación ordinal es secundaria y aporta información sobre el gradiente completo de cuatro categorías.

## Resultado binario principal

RP 0.867 (ICr95% 0.784–0.951); DP -0.082 (ICr95% -0.134–-0.030).

## Resultado ordinal secundario

Coeficiente -0.376 (ICr95% -0.578–-0.176); OR acumulativa 0.686 (ICr95% 0.561–0.838).

## Thresholds

- 1: -3.606 (ICr95% -3.755–-3.462).
- 2: -1.851 (ICr95% -1.920–-1.783).
- 3: -0.476 (ICr95% -0.525–-0.426).

## Evaluación de odds proporcionales

- Sin controles vs categorías superiores: OR 0.665 (ICr95% 0.401–1.194); diferencia frente al OR común -0.021.
- Sin controles + inadecuado vs intermedio + adecuado: OR 0.614 (ICr95% 0.475–0.802); diferencia frente al OR común -0.073.
- Sin controles + inadecuado + intermedio vs adecuado: OR 0.715 (ICr95% 0.578–0.876); diferencia frente al OR común 0.028.

Los tres OR acumulativos tienen magnitud cercana al OR común y sus intervalos se solapan con el ICr del modelo ordinal; los datos son compatibles con el supuesto de odds proporcionales.

## Comparación documental pendiente

Deberán actualizarse Métodos, Resultados y la jerarquía descrita en el resumen; Tabla 1, la línea y nota de Tabla 2; Tabla S1; Tabla S3; Discusión y Carta de Respuesta. No se modificó ninguno de esos archivos.

## Inconsistencias detectadas

La nota actual de Tabla 2 describe incorrectamente el evento binario como si comparara una variable ordinal frente a tres categorías; el código real modela adecuado (≥80%) frente a no adecuado. Métodos y resumen presentan actualmente la adecuación ordinal como principal, contrario a la jerarquía solicitada. La regla por edad gestacional existe en el código, pero no está expuesta en el manuscrito.
