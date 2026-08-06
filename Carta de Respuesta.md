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

## 4. Indicador de rezago escolar

**Comentario editorial**

El nuevo indicador constituye una mejora importante, pero el manuscrito invierte la dirección del posible error: si el rezago se calcula como años esperados menos años aprobados, subestimar los años esperados reduce —no aumenta— el rezago estimado. Se solicita corregir esta afirmación en Métodos y Limitaciones; presentar una tabla con los años esperados por edad; justificar la regla “edad menos seis”; realizar sensibilidad con una regla alternativa plausible; describir el impacto de la reforma educativa; y reconocer que la escolaridad registrada en el parto puede haber sido afectada por interrupción escolar durante la propia gestación.

**Respuesta**

Agradecemos esta observación. Se corrigió la dirección del posible error de clasificación. Dado que el rezago se definió como años esperados menos años aprobados, una subestimación de los años esperados reduce el rezago calculado y puede producir una estimación conservadora, en lugar de sobreestimarlo.

La regla principal, edad materna menos seis con un máximo de 12 años, se mantuvo como aproximación operacional al avance escolar esperado bajo la estructura educativa ecuatoriana previa a 2011 y al inicio habitual de la escolarización formal alrededor de los seis años. Se incorporó una tabla suplementaria con los años esperados para cada edad entre 10 y 19 años.

Además, se realizó un análisis de sensibilidad con una regla alternativa de edad materna menos cinco y un máximo de 13 años. Esta especificación reclasificó 434 de 7.027 registros (6,18 %). La estimación principal fue RP=2,07 (ICr95%: 1,78–2,41) y diferencia de prevalencias=0,18 (ICr95%: 0,13–0,23). Con la regla alternativa, la asociación se atenuó a RP=1,83 (ICr95%: 1,60–2,07), mientras que la diferencia de prevalencias fue 0,19 (ICr95%: 0,14–0,24). Por tanto, la magnitud relativa fue sensible a la especificación, pero la dirección y la diferencia absoluta se mantuvieron.

También se incorporó en Métodos y Limitaciones que la base no permitió identificar el régimen educativo aplicable individualmente y que la reforma educativa pudo modificar los años de escolaridad esperados. Se reconoció, además, que la escolaridad registrada en el momento del parto pudo haber sido afectada por interrupciones escolares durante la propia gestación, por lo que no puede asumirse que todo el rezago precedió al embarazo.

**Cambios realizados**

- Métodos: definición, justificación y sensibilidad del indicador de rezago escolar.
- Resultados: número de registros reclasificados y estimaciones bajo la regla alternativa.
- Limitaciones: corrección de la dirección del posible sesgo, efecto de la reforma educativa y temporalidad de la escolaridad registrada.
- Material suplementario: tabla de años esperados por edad y resultados completos de sensibilidad.
- Código reproducible: R/06_sensibilidad_rezago_escolar.R.
- Archivos de salida: output/rezago_escolar/.

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
