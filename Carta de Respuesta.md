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

## 7. Modelo gaussiano para número de consultas

**Comentario del editor:** El número de consultas es una variable de conteo susceptible a asimetría, acumulaciones y sobredispersión. Se solicitó presentar verificaciones predictivas posteriores específicas, comparar el modelo gaussiano con modelos de Poisson y binomial negativa, mostrar la distribución observada y predicha, informar valores extremos y acumulaciones, y aclarar la interpretación del ajuste por edad gestacional.

**Respuesta de los autores:** Evaluamos nuevamente el modelo gaussiano sin eliminarlo a priori y lo comparamos con modelos bayesianos de Poisson y binomial negativa, en versiones no ajustada y ajustada por edad gestacional al parto. La decisión se basó en la naturaleza de conteo del desenlace, las verificaciones predictivas posteriores y LOO, no en la significación estadística. Dado el mejor desempeño predictivo de la binomial negativa, este modelo se adoptó como análisis principal para el número de consultas; Poisson y gaussiano se conservaron como análisis de sensibilidad.

**Distribución observada:** La variable `Número Consultas prenatales` tuvo 6.884 observaciones válidas y 151 faltantes. El rango fue 0–20, la media 5,714, la mediana 6, la varianza 7,663 y la desviación estándar 2,768. La relación varianza/media fue 1,341 y la asimetría 0,442. Se registraron 187 ceros (2,72 %), acumulaciones reproducibles en 5, 8 y 12 consultas, y 53 observaciones por encima del límite superior de Tukey de 14. Estos resultados mostraron asimetría moderada, heaping y sobredispersión respecto de Poisson.

**PPC del gaussiano:** Aunque el modelo gaussiano reprodujo la media y la varianza globales, 12 de 16 estadísticos predictivos observados quedaron fuera del ICr95 % tanto sin ajuste como con ajuste. El modelo subestimó la proporción de ceros, generó aproximadamente 2 % de predicciones negativas y no reprodujo adecuadamente los extremos ni las acumulaciones principales.

**Comparación de modelos:** En el modelo principal binomial negativo, la razón de medias para adolescentes de 10–14 frente a 15–19 años fue 0,902 (ICr95 %: 0,856–0,953) sin ajuste y 0,903 (0,857–0,949) con ajuste por oportunidad acumulada. En Poisson fue 0,902 (0,860–0,943) y 0,903 (0,863–0,945), respectivamente. En el gaussiano, las diferencias de medias fueron −0,561 (−0,854 a −0,272) sin ajuste y −0,546 (−0,828 a −0,275) con ajuste. La dirección y la magnitud relativa fueron concordantes entre familias.

**Resultado de LOO:** La binomial negativa obtuvo el mayor ELPD-LOO en ambos conjuntos comparables. Frente a ella, el gaussiano presentó delta ELPD de −9,65 sin ajuste y −27,00 con ajuste; Poisson presentó −167,92 y −91,50, respectivamente. La binomial negativa tuvo 6/16 estadísticos PPC fuera del ICr95 %, frente a 12/16 en el gaussiano. No hubo valores de Pareto-k >0,7. Todos los modelos mostraron convergencia adecuada, con R-hat máximo ≤1,0021 y cero divergencias.

**Decisión final:** La binomial negativa se considera el análisis principal porque respeta el soporte de conteo, admite sobredispersión y presentó el mejor ajuste predictivo. Los modelos de Poisson y gaussiano se mantienen únicamente como sensibilidades. El gaussiano no se mantuvo como principal por inercia ni se seleccionó ningún modelo por significación estadística.

**Interpretación de la edad gestacional:** El ajuste por edad gestacional al parto se interpretó como un ajuste por la oportunidad acumulada de recibir consultas prenatales y no como control causal de confusión. No se interpreta como un efecto independiente ni causalmente ajustado.

**Ubicación exacta de los cambios:**

- **Resumen y Abstract:** binomial negativa como análisis principal y razón de medias ajustada.
- **Materiales y métodos:** distribución evaluada, jerarquía de modelos, PPC, LOO y significado del ajuste por edad gestacional.
- **Resultados, apartado “Atención prenatal”:** distribución observada, resultado principal binomial negativo y comparación predictiva.
- **Discusión:** decisión metodológica y cautela interpretativa sobre edad gestacional.
- **Tabla S3:** corrección del modelo gaussiano no ajustado a n=6.884 e ICr95 % de −0,85 a −0,27.
- **Tabla S8:** comparación única de los seis modelos, sus estimadores, LOO, PPC y diagnósticos de convergencia.

## 8. Diagnósticos bayesianos y sensibilidad a priors

**Comentario del editor:** Se solicitó presentar integralmente los diagnósticos bayesianos de los modelos Bernoulli, ordinales, gaussianos y de conteo, incluidas R-hat, ESS bulk y tail, divergencias, treedepth, E-BFMI, verificaciones predictivas posteriores, sensibilidad a priors y parámetros posteriores completos.

**Respuesta de los autores:** Auditamos los 20 modelos que sustentan resultados publicados: 13 Bernoulli-logit, un cumulative-logit ordinal, dos binomiales negativos principales, dos Poisson y dos gaussianos de sensibilidad. La auditoría consideró todos los parámetros relevantes de cada modelo, no únicamente el coeficiente del grupo.

**Diagnósticos globales:** El R-hat máximo fue 1,0018; el ESS bulk mínimo, 4.182; y el ESS tail mínimo, 4.568. No hubo divergencias ni iteraciones que alcanzaran el max treedepth. El E-BFMI mínimo fue 0,909. En consecuencia, no se detectaron problemas de convergencia, eficiencia del muestreo, saturación de treedepth ni exploración de la energía posterior.

**PPC por familia:** Los PPC compararon prevalencias globales y por grupo y varianza en los Bernoulli, las cuatro proporciones en el ordinal, y media, varianza, ceros, cuantiles, extremos y acumulaciones en los modelos de consultas. Las comparaciones observadas fuera del ICr95 % predictivo fueron 0/52 para Bernoulli-logit, 0/4 para el ordinal, 24/32 para los gaussianos, 15/32 para Poisson y 12/32 para binomial negativa. Específicamente, Poisson presentó 9/16 discrepancias sin ajuste y 6/16 con ajuste; la binomial negativa presentó 6/16 en cada versión. Estos valores describen el desempeño predictivo observado y no se interpretan como ajuste perfecto.

**Sensibilidad a priors:** Cada coeficiente principal se comparó con una especificación alternativa moderadamente más amplia y coherente con su familia. Se ampliaron por separado los priors de interceptos, coeficientes y, según correspondía, sigma o shape; no se asumieron priors idénticos entre familias. La máxima diferencia absoluta entre estimaciones principales y alternativas fue 0,0113 y ninguno de los 20 modelos cambió de dirección. Por tanto, la magnitud y dirección de los resultados fueron estables frente a las especificaciones alternativas evaluadas.

**Parámetros posteriores completos:** Se añadieron los interceptos y coeficientes de grupo de los 13 Bernoulli; el coeficiente de grupo y los tres thresholds del ordinal; intercepto, grupo, edad gestacional cuando correspondía y sigma de los gaussianos; los parámetros equivalentes y shape de las binomiales negativas; e intercepto, grupo y edad gestacional de Poisson. Para cada parámetro se informan estimación posterior, ICr95 %, R-hat, ESS bulk y ESS tail.

**Ubicación exacta de los cambios:**

- **Materiales y métodos, análisis bayesiano:** se explicitan todos los diagnósticos, los PPC por familia y las especificaciones principales y alternativas de priors.
- **Resultados, “Diagnósticos bayesianos y sensibilidad a priors”:** se resumen los diagnósticos globales, PPC y estabilidad frente a priors.
- **Tabla S9:** diagnósticos completos y resumen PPC de los 20 modelos.
- **Tabla S10:** parámetros posteriores completos, incluidos interceptos, thresholds, sigma y shape.
- **Tabla S11:** comparación compacta de coeficientes principales bajo priors principales y alternativos.

## 9. Heterogeneidad temporal

**Comentario del editor:** Se solicitó dar centralidad a la heterogeneidad temporal observada, evaluar formalmente la interacción entre grupo etario y período, evitar presentar como rasgos estables asociaciones que dependen del período, discutir prudentemente posibles cambios de registro o prácticas institucionales y aclarar que 2024 comprende únicamente enero--junio.

**Respuesta de los autores:** Incorporamos un análisis formal por tres subperíodos categóricos: 2009--2014, 2015--2019 y 2020--junio 2024. Para pareja estable, etnia minoritaria y control prenatal adecuado (sí/no) comparamos modelos bayesianos Bernoulli-logit aditivos y con interacción grupo etario × período. Estimamos prevalencias marginales por grupo, diferencias y razones de prevalencia por período, e informamos los términos de interacción. La comparación entre modelos se realizó mediante LOO, considerando conjuntamente la dirección, magnitud, incertidumbre, ΔELPD y su error estándar. La adecuación ordinal se conservó únicamente como sensibilidad secundaria.

**Pareja estable:** En adolescentes de 10--14 frente a 15--19 años, las prevalencias marginales fueron 0,51 frente a 0,61 en 2009--2014 (DP=-0,10; ICr95 %: -0,18 a -0,02; RP=0,84; ICr95 %: 0,71--0,97), 0,31 frente a 0,47 en 2015--2019 (DP=-0,16; ICr95 %: -0,24 a -0,07; RP=0,66; ICr95 %: 0,50--0,84) y 0,63 frente a 0,58 en 2020--junio 2024 (DP=0,05; ICr95 %: -0,04 a 0,15; RP=1,10; ICr95 %: 0,93--1,26). Por tanto, la dirección se invirtió descriptivamente en el período reciente, aunque con incertidumbre. La razón de OR de interacción reciente fue 1,88 (ICr95 %: 1,13--3,17). El modelo con interacción tuvo ΔELPD=3,46 (EE=3,25), interpretado como una ventaja predictiva pequeña e incierta, no como evidencia concluyente.

**Etnia minoritaria:** Las prevalencias marginales fueron 0,05 frente a 0,03 en 2009--2014 (DP=0,02; ICr95 %: -0,01 a 0,06; RP=1,62; ICr95 %: 0,79--3,02), 0,12 frente a 0,06 en 2015--2019 (DP=0,06; ICr95 %: 0,01--0,13; RP=2,01; ICr95 %: 1,19--3,18) y 0,09 frente a 0,09 en 2020--junio 2024 (DP=0,00; ICr95 %: -0,04 a 0,07; RP=1,04; ICr95 %: 0,53--1,82). La diferencia fue mayor principalmente en 2015--2019 y se aproximó a la nulidad en el período reciente, con mayor incertidumbre. La razón de OR de interacción reciente fue 0,64 (ICr95 %: 0,25--1,63) y el modelo con interacción no mejoró la predicción (ΔELPD=-0,51; EE=1,65).

**Control prenatal adecuado:** Las prevalencias marginales fueron 0,47 frente a 0,60 en 2009--2014 (DP=-0,13; ICr95 %: -0,21 a -0,05; RP=0,79; ICr95 %: 0,65--0,92), 0,59 frente a 0,66 en 2015--2019 (DP=-0,06; ICr95 %: -0,16 a 0,02; RP=0,90; ICr95 %: 0,77--1,03) y 0,55 frente a 0,57 en 2020--junio 2024 (DP=-0,02; ICr95 %: -0,12 a 0,08; RP=0,97; ICr95 %: 0,80--1,14). La diferencia negativa fue mayor en el primer período y se aproximó progresivamente a la nulidad. La razón de OR de interacción reciente fue 1,59 (ICr95 %: 0,95--2,63), sin ventaja predictiva del modelo con interacción (ΔELPD=-0,19; EE=1,76). La sensibilidad ordinal mostró un patrón concordante: OR de 0,57, 0,76 y 0,86 por período, y ΔELPD=-0,31 (EE=1,79).

**Interpretación:** Las estimaciones muestran variación temporal de dirección o magnitud, especialmente para pareja estable, pero la comparación predictiva no proporciona evidencia concluyente de interacción. Cambios en la composición de la población atendida, el registro o cobertura del SIP, las prácticas institucionales, el acceso o uso de atención prenatal y las circunstancias del período pandémico son explicaciones plausibles. El estudio no permite identificar cuál mecanismo explica los cambios ni atribuirles causalmente la heterogeneidad.

**Aclaración de 2024:** En todo el manuscrito y en la tabla suplementaria, el último período se denomina **2020--junio 2024**. El año 2024 incluye exclusivamente enero--junio y no se interpreta como un año completo.

**Ubicación exacta de los cambios:**

- **Resumen y Abstract:** período de estudio corregido a enero de 2009--junio de 2024 y resultados globales matizados como no temporalmente uniformes.
- **Materiales y métodos, análisis estadístico:** definición de los tres períodos, modelos aditivo y con interacción, estimaciones marginales, comparación mediante LOO y sensibilidad ordinal.
- **Resultados, apartado “Heterogeneidad temporal”:** resultados completos de pareja estable, etnia minoritaria y control prenatal adecuado, incluidos estimandos marginales, términos de interacción y comparación LOO.
- **Discusión:** asociaciones globales reformuladas como dependientes del período, atención especial a la inversión descriptiva de pareja estable e interpretación no causal de mecanismos plausibles.
- **Conclusiones:** aclaración de que estas diferencias no fueron temporalmente uniformes.
- **Tabla S2:** período final corregido a 2020--junio 2024 y período total aclarado como enero de 2009--junio de 2024.
- **Tabla S12:** resumen compacto de prevalencias marginales, DP, RP, términos de interacción y ΔELPD con su EE.

## 10. Figuras y marco de selección

**Comentario del editor:** Se señaló que la Figura 1 podía sugerir que el estudio partió de todos los partos adolescentes institucionales y aplicó después el criterio de admisión neonatal, aunque la base accesible ya estaba restringida a recién nacidos admitidos. También se solicitó identificar claramente que 2024 contiene solo enero--junio y evitar su comparación directa con años completos en la Figura 3.

**Respuesta de los autores:** Rediseñamos ambas figuras y revisamos sus llamadas, pies y texto interpretativo. La Figura 1 comienza ahora por la base SIP realmente disponible para el estudio, ya condicionada por admisión neonatal, y distingue visualmente este marco analítico del contexto institucional completo no observado. La Figura 3 identifica y separa explícitamente el período parcial de 2024.

**Figura 1 y base accesible:** La población institucional de todos los partos de adolescentes aparece únicamente como contexto externo, en una caja discontinua rotulada “no observado directamente”, y no como un paso del flujo de inclusión. Se aclara que no se dispuso del denominador institucional ni de los partos no incluidos. El primer nodo observado es la base SIP disponible: 7.202 registros iniciales de adolescentes de 10--19 años cuyos recién nacidos ya habían sido admitidos en Neonatología. Desde allí se representa el proceso real de eliminación de 15 duplicados exactos, linkage/consolidación de gestaciones múltiples, muestra materna final de 7.035 eventos obstétricos y submuestra neonatal descriptiva de 6.790 nacimientos únicos.

**Posibles determinantes del mecanismo de selección:** Se incorporaron, como factores potencialmente relacionados con la probabilidad de admisión neonatal e inclusión en la base, características sociodemográficas —edad/grupo etario, etnia, pareja estable y educación/rezago—; reproductivas/obstétricas —embarazo planeado, antecedentes y condiciones obstétricas/perinatales—; y de atención prenatal —adecuación y número de consultas—. Las flechas y el pie indican expresamente que se trata de un diagrama conceptual y no de causas o efectos causales estimados.

**Figura 3 y 2024 parcial:** La etiqueta del eje X se cambió a **“2024 (ene--jun)”**. El período se separó de 2009--2023 mediante espacio adicional, una línea discontinua y un contorno diferenciado. Dentro de la figura se añadió la advertencia **“2024: enero--junio; conteo parcial; no comparable directamente con años completos”**. No se anualizaron, proyectaron ni extrapolaron los datos de julio--diciembre.

**Interpretación:** El texto del manuscrito aclara que la variación anual se describe dentro de la población hospitalaria seleccionada y no representa una tendencia poblacional. El dato parcial de 2024 no se interpreta como descenso anual ni se compara directamente con los años calendario completos.

**Ubicación exacta de los cambios:**

- **Materiales y métodos, primer párrafo:** se aclara que la base accesible ya estaba restringida por admisión neonatal y que no se observaron todos los partos adolescentes institucionales.
- **Figura 1 y su nota:** nuevo marco de selección, flujo real de depuración, posibles determinantes de selección, ausencia de atribución causal y restricción de la inferencia.
- **Discusión, párrafo sobre variación anual:** llamada a la Figura 3 y aclaración de que 2024 es parcial y no directamente comparable.
- **Figura 3, eje X, anotación y nota:** identificación de enero--junio de 2024, separación visual y advertencia de no comparabilidad anual.

## 11. Resumen técnico

- La muestra materna y la muestra neonatal están claramente separadas.
- La descripción neonatal se realiza únicamente en la submuestra de nacimientos únicos.
- No se retuvo de forma arbitraria ningún recién nacido de una gestación múltiple.
- Las denominaciones de las tablas neonatales y las notas del manuscrito reflejan esta lógica.

## 12. Conclusión

Hemos corregido completamente la redacción y la documentación del proceso. El análisis ahora declara y aplica con transparencia:

- la unidad de análisis materna,
- el manejo de gestaciones múltiples,
- la restricción a nacimientos únicos para las variables neonatales,
- y los denominadores auditados y reproducibles.

Quedamos a disposición para proporcionar el código de auditoría y cualquier extracto adicional necesario para la revisión.
