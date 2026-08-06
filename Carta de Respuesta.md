# Carta de Respuesta a la Editora

Estimado/a Editor/a,

Agradecemos la revisión rigurosa y los comentarios recibidos. A continuación presentamos una respuesta detallada y blindada sobre la unidad de análisis, el manejo de gestaciones múltiples y la descripción neonatal.

## 1. Comentario del editor

El comentario editorial solicitó usar de forma consistente la terminología de la unidad de análisis y aclarar que la base contiene eventos obstétricos, no necesariamente personas distintas, dado que no se disponía de un identificador longitudinal personal.

## 2. Respuesta de los autores

Agradecemos esta observación. Reconocemos que la versión anterior utilizó de manera inconsistente expresiones referidas a personas y a eventos. La unidad de análisis fue el evento obstétrico materno, no la adolescente individual.

## 3. Problema reconocido

La formulación previa podía sugerir que los 7.035 registros analíticos equivalían a 7.035 personas únicas. Este problema era especialmente relevante en el Resumen, los Resultados, el flujograma y las notas de figura, donde la terminología podía interpretarse como referida a personas individuales.

## 4. Cambios realizados

Se corrigió la terminología en el manuscrito para referirse sistemáticamente a eventos obstétricos maternos; se reformuló el Resumen, los Resultados, el apartado de Métodos, la sección de Limitaciones y el texto del flujograma y las notas de figura. También se añadió una explicación explícita sobre la ausencia de un identificador longitudinal personal y la posibilidad de dependencia residual entre observaciones.

## 5. Terminología adoptada

Se adoptó la formulación: “Se analizaron 7.035 eventos obstétricos de adolescentes” y “La unidad de análisis fue el evento obstétrico materno”.

## 6. Explicación de la imposibilidad de identificar recurrencias

No se dispuso de un identificador personal longitudinal que permitiera determinar si una misma adolescente contribuyó con más de un evento obstétrico durante el período 2009–junio de 2024. Por ello, los registros finales se interpretaron como eventos obstétricos y no como 7.035 personas distintas.

## 7. Discusión de la dependencia residual

En consecuencia, no pudo descartarse una posible dependencia residual entre observaciones correspondientes a eventos recurrentes no identificables de una misma persona. Esta limitación se incorporó en la sección de Limitaciones, sin afirmar que la dependencia se hubiera demostrado ni que se hubiera cuantificado.

## 8. Ubicación exacta de cada cambio

- Resumen y Abstract: [manuscript/Adolescentes_19_julio.qmd](manuscript/Adolescentes_19_julio.qmd)
- Métodos: [manuscript/Adolescentes_19_julio.qmd](manuscript/Adolescentes_19_julio.qmd)
- Resultados: [manuscript/Adolescentes_19_julio.qmd](manuscript/Adolescentes_19_julio.qmd)
- Limitaciones y Discusión: [manuscript/Adolescentes_19_julio.qmd](manuscript/Adolescentes_19_julio.qmd)
- Figura 2 y nota asociada: [manuscript/Adolescentes_19_julio.qmd](manuscript/Adolescentes_19_julio.qmd)
- Fuente de la figura conceptual: [Figura1_marco_conceptual.R](Figura1_marco_conceptual.R)

## 9. Archivos modificados

- [manuscript/Adolescentes_19_julio.qmd](manuscript/Adolescentes_19_julio.qmd)
- [Carta de Respuesta.md](Carta%20de%20Respuesta.md)
- [Figura1_marco_conceptual.R](Figura1_marco_conceptual.R)

## 10. Verificación final de consistencia

Se verificó que el manuscrito, la carta de respuesta y la fuente de la figura empleen de forma consistente la terminología de eventos obstétricos maternos y que se evite presentar los 7.035 registros como 7.035 personas distintas.

### Comentario editorial 4: indicador de rezago escolar

Agradecemos esta observación. Se aclaró que el rezago escolar se calculó como la diferencia entre los años esperados y los años aprobados, con un máximo de 12 años, y que esta definición es operacional. La redacción del manuscrito ahora indica que, bajo esta fórmula, una subestimación de los años esperados puede subestimar el rezago calculado, especialmente en adolescentes escolarizadas bajo la reforma educativa. Este punto se incorporó en los apartados de Métodos y Limitaciones.

## 2. Gestaciones múltiples

- Se identificaron **245 eventos de embarazo múltiple** en la muestra final de 7.035 eventos obstétricos.
- Los embarazos múltiples se consolidaron **a nivel materno** con un procedimiento reproducible y explícito.
- El algoritmo de consolidación utilizado fue:
  1. Identificar grupos maternos usando una llave de **13 variables**:
     - año de atención,
     - edad materna,
     - escolaridad,
     - pareja estable,
     - etnia,
     - gestas previas,
     - partos previos,
     - cesáreas previas,
     - embarazo planeado,
     - uso de anticonceptivos,
     - número de consultas prenatales,
     - tipo de parto,
     - cesárea.
  2. Dentro de cada grupo, calcular un **cluster de edad gestacional**.
  3. Si la diferencia de edad gestacional entre registros era **≥ 3 semanas**, se consideraban **eventos obstétricos distintos**.
  4. Si la diferencia era **< 3 semanas**, se conservaba un **único evento materno**.
- Este método asegura que no se sobrecuenten gestaciones múltiples en el análisis materno y que la muestra resultante sea consistente con la unidad de análisis declarada.

## 3. Descripción neonatal y denominadores

- La descripción neonatal **se restringió exclusivamente a nacimientos únicos**.
- Para este propósito se definió una submuestra llamada `df_neonatal` que excluye cualquier registro con `embarazo_multiple == 1`.
- En el manuscrito y en el código se aclara que la muestra materna completa de 7.035 eventos y la submuestra neonatal única de 6.790 nacimientos son distintas.
- Esta submuestra neonatal única corresponde a:
  - **381 nacimientos únicos** en adolescentes de 10–14 años.
  - **6.409 nacimientos únicos** en adolescentes de 15–19 años.

## 4. Denominadores neonatales exactos

- Los denominadores de las variables neonatales no son 7.035, porque se calculan en la submuestra de **6.790 nacimientos únicos**.
- Además, los denominadores específicos dependen de la disponibilidad de datos para cada variable, lo que explica que algunos ítems tengan menos de 6.790 registros válidos.
- Ejemplos de denominadores auditados:
  - `PREMATURO CODIGO`: 6.747
  - `CODIGO Apgar 1 minuto <7`: 6.665
  - `CODIGO Apgar 5to. < 7`: 6.673
  - `RCIU`: 6.789
  - `MACROSÓMICO`: 6.790
  - `BEBE Ictericia`: 6.790
  - `RN vivo CODIGO`: 6.778
  - `Lactancia exclusiva SI NO`: 5.809

## 5. Verificación reproducible

- Se creó un script de auditoría independiente: `R/03_auditoria_gestaciones_multiples.R`.
- Este script genera pruebas reproducibles y guarda resultados en `output/reconciliation/`.
- Los resultados validados son:
  - 7.202 registros iniciales.
  - 15 duplicados exactos eliminados.
  - 152 registros consolidados por gestaciones múltiples.
  - 7.035 eventos obstétricos finales.
  - 245 embarazos múltiples en la muestra final.
  - 6.790 nacimientos únicos en la muestra neonatal.

## 6. Resumen técnico

- La muestra materna y la muestra neonatal están claramente separadas.
- La descripción neonatal se realiza únicamente en la submuestra de nacimientos únicos.
- No se retuvo de forma arbitraria ningún recién nacido de una gestación múltiple.
- Las denominaciones de las tablas neonatales y las notas del manuscrito reflejan esta lógica.

## 7. Conclusión

Hemos corregido completamente la redacción y la documentación del proceso. El análisis ahora declara y aplica con transparencia:

- la unidad de análisis materna,
- el manejo de gestaciones múltiples,
- la restricción a nacimientos únicos para las variables neonatales,
- y los denominadores auditados y reproducibles.

Quedamos a disposición para proporcionar el código de auditoría y cualquier extracto adicional necesario para la revisión.
