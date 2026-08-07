# Carta de Respuesta a la Editora

Estimado/a Editor/a,

Agradecemos la revisión rigurosa y los comentarios recibidos. A continuación presentamos una respuesta detallada y blindada sobre la unidad de análisis, el manejo de gestaciones múltiples y la descripción neonatal.

## 1. Unidad de análisis

- La unidad de análisis principal del estudio es el **evento obstétrico materno** en adolescentes de 10–19 años.
- La muestra analítica final para variables maternas incluye **7.035 eventos obstétricos**, de los cuales **386** corresponden a adolescentes de 10–14 años y **6.649** a adolescentes de 15–19 años.
- Estos eventos se obtuvieron a partir de **7.202 registros iniciales**.
- Se eliminaron **15 duplicados exactos**.

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

## 6. Adecuación de la atención prenatal

**Comentario del editor:** Se solicitó aclarar la construcción de la adecuación de la atención prenatal, definir la jerarquía entre el análisis binario y el ordinal, documentar el modelo ordinal y sus thresholds, y evaluar el supuesto de odds proporcionales.

**Respuesta de los autores:** Aclaramos que el análisis principal es **Control prenatal adecuado: sí/no**, definido como ≥80 % frente a <80 % de los contactos esperados según la edad gestacional al parto. La adecuación ordinal de cuatro categorías se mantiene como análisis secundario. Actualizamos el Resumen/Abstract, Métodos, Resultados, la Tabla 2 y el Material Suplementario para reflejar de forma consistente esta jerarquía, sin modificar los análisis ni las cifras verificadas.

**Análisis realizado:** Los contactos esperados se asignaron acumulativamente según la edad gestacional: 1 para <20 semanas; 2 para 20–<26; 3 para 26–<30; 4 para 30–<34; 5 para 34–<36; 6 para 36–<38; 7 para 38–<40; y 8 para ≥40 semanas. La proporción observados/esperados se clasificó como sin controles (0), inadecuado (>0 y <50 %), intermedio (50 a <80 %) y adecuado (≥80 %). El análisis principal binario se estimó mediante un modelo bayesiano Bernoulli-logit con estandarización posterior para obtener la RP. El análisis secundario utilizó un modelo cumulative-logit con thresholds flexibles para las cuatro categorías ordenadas.

**Resultado principal binario:** En adolescentes de 10–14 frente a 15–19 años, el control prenatal adecuado fue menos frecuente: **RP=0,87 (ICr95 %: 0,78–0,95)**; n=6.860 y 4.198 eventos.

**Resultado ordinal secundario:** La OR acumulativa para pertenecer a una categoría de mejor adecuación fue **0,69 (ICr95 %: 0,56–0,84)**; n=6.860.

**Thresholds:** Los tres thresholds del modelo ordinal fueron: **−3,607 (ICr95 %: −3,755 a −3,462)**, **−1,851 (−1,920 a −1,783)** y **−0,476 (−0,525 a −0,426)**. Los diagnósticos fueron adecuados: R-hat máximo=1,0009; ESS bulk mínimo=4.182; ESS tail mínimo=5.184; cero divergencias; profundidad máxima observada=7; y E-BFMI mínimo=0,985.

**Evaluación de odds proporcionales:** Se ajustaron tres modelos binarios acumulativos. Los OR fueron **0,67 (ICr95 %: 0,40–1,19)** para sin controles frente a categorías superiores; **0,61 (0,48–0,80)** para sin controles + inadecuado frente a intermedio + adecuado; y **0,71 (0,58–0,88)** para sin controles + inadecuado + intermedio frente a adecuado. Los tres OR fueron cercanos al OR ordinal común y sus intervalos se solaparon con el intervalo del modelo ordinal; por tanto, los resultados fueron compatibles con el supuesto de odds proporcionales.

**Ubicación exacta de los cambios:**

- **Resumen y Abstract:** se presenta la RP binaria como resultado principal.
- **Materiales y métodos, párrafos de utilización y modelado de atención prenatal:** se explicitan el algoritmo, las cuatro categorías, la jerarquía analítica, el modelo cumulative-logit y la evaluación de odds proporcionales.
- **Resultados, apartado “Atención prenatal”:** se presenta primero la RP binaria y luego la OR ordinal secundaria, junto con el resumen de la evaluación del supuesto.
- **Tabla 2:** la fila se renombró “Control prenatal adecuado: sí/no” y se corrigió su nota.
- **Tabla S3:** se mantiene “Adecuación ordinal del control prenatal” como análisis secundario.
- **Tablas S5–S7:** se incorporan, respectivamente, la regla de contactos esperados, los thresholds y diagnósticos del modelo ordinal, y la sensibilidad del supuesto de odds proporcionales.

## 7. Resumen técnico

- La muestra materna y la muestra neonatal están claramente separadas.
- La descripción neonatal se realiza únicamente en la submuestra de nacimientos únicos.
- No se retuvo de forma arbitraria ningún recién nacido de una gestación múltiple.
- Las denominaciones de las tablas neonatales y las notas del manuscrito reflejan esta lógica.

## 8. Conclusión

Hemos corregido completamente la redacción y la documentación del proceso. El análisis ahora declara y aplica con transparencia:

- la unidad de análisis materna,
- el manejo de gestaciones múltiples,
- la restricción a nacimientos únicos para las variables neonatales,
- y los denominadores auditados y reproducibles.

Quedamos a disposición para proporcionar el código de auditoría y cualquier extracto adicional necesario para la revisión.
