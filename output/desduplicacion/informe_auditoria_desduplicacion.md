# Informe de auditoría de desduplicación y linkage

Fecha de ejecución: 2026-08-05

## Validaciones automáticas
- Registros iniciales en Adolescentes.csv: 7202
- Duplicados exactos eliminados: 15
- Registros después de duplicados exactos: 7187
- Filas consolidadas en escenario principal (3 semanas): 152
- Eventos obstétricos finales en escenario principal: 7035
- Eventos múltiples en escenario principal: 245
- Eventos únicos en escenario principal: 6790
- Conteo 10-14 años en escenario principal: 386
- Conteo 15-19 años en escenario principal: 6649

## Resultados principales por escenario

# A tibble: 5 × 22
  escenario        registros_iniciales duplicados_exactos registros_despues_du…¹
  <chr>                          <int>              <int>                  <int>
1 A_exact_duplica…                7187                 15                   7187
2 B_llave_exacta                  7187                 15                   7187
3 C_1_semana                      7187                 15                   7187
4 D_2_semanas                     7187                 15                   7187
5 E_3_semanas                     7187                 15                   7187
# ℹ abbreviated name: ¹​registros_despues_duplicados
# ℹ 18 more variables: registros_consolidados <int>, eventos_finales <int>,
#   eventos_multiples <int>, eventos_unicos <int>, agrupamientos_totales <int>,
#   agrupamientos_1 <int>, agrupamientos_2 <int>, agrupamientos_3 <int>,
#   agrupamientos_4mas <int>, max_registros_por_agrupamiento <int>,
#   agrupamientos_afectados <int>, grupos_10_14 <int>, grupos_15_19 <int>,
#   diff_eventos_finales <int>, diff_eventos_multiples <int>, …

## Distribución del tamaño de agrupamientos

# A tibble: 15 × 6
   escenario  size n_agrupamientos registros_involucrados porcentaje_agrupamie…¹
   <chr>     <int>           <int>                  <int>                  <dbl>
 1 A_exact_…     1              89                     89                 36.9  
 2 A_exact_…     2             150                    300                 62.2  
 3 A_exact_…     4               2                      8                  0.830
 4 B_llave_…     1             121                    121                 46.9  
 5 B_llave_…     2             136                    272                 52.7  
 6 B_llave_…     4               1                      4                  0.388
 7 C_1_sema…     1             119                    119                 46.3  
 8 C_1_sema…     2             137                    274                 53.3  
 9 C_1_sema…     4               1                      4                  0.389
10 D_2_sema…     1             107                    107                 42.6  
11 D_2_sema…     2             143                    286                 57.0  
12 D_2_sema…     4               1                      4                  0.398
13 E_3_sema…     1              95                     95                 38.8  
14 E_3_sema…     2             149                    298                 60.8  
15 E_3_sema…     4               1                      4                  0.408
# ℹ abbreviated name: ¹​porcentaje_agrupamientos
# ℹ 1 more variable: porcentaje_registros <dbl>

## Agrupamientos ambiguos identificados
- Clusters ambiguos en escenario principal: 14

## Reconciliación entre 152 y 245
# A tibble: 11 × 3
   elemento                         valor nota                                  
   <chr>                            <int> <chr>                                 
 1 registros_iniciales               7202 Registros crudos iniciales            
 2 duplicados_exactos                  15 Duplicados exactos eliminados         
 3 registros_despues_duplicados      7187 Registros después de duplicados exact…
 4 filas_multiples_originales         397 Filas con código de embarazo múltiple…
 5 filas_multiples_finales            245 Filas finales con código de embarazo …
 6 filas_consolidadas_por_multiples   152 Filas múltiples consolidadas por link…
 7 eventos_multiples_finales          245 Eventos obstétricos finales clasifica…
 8 eventos_unicos_finales            6790 Eventos obstétricos finales clasifica…
 9 registros_finales                 7035 Eventos obstétricos finales totales   
10 identity_7202_15_152              7035 Identidad aritmética: 7202 - 15 - 152…
11 identity_245_6790                 7035 Identidad aritmética: 245 + 6790 = 70…

## Limitaciones detectadas

- El umbral de tres semanas se aplica solo dentro de las filas con `Embarazo múltiple CODIGO == 1`.
- El agrupamiento original usa diferencias de edad gestacional ordenadas y no compara todos los pares entre sí.
- Los valores de edad gestacional faltantes se agrupan con el registro anterior cuando existen registros no faltantes en la misma llave.
- La consolidación conserva la primera fila encontrada dentro de cada cluster, lo que puede retener información de un recién nacido de manera arbitraria cuando hay múltiples registros con la misma llave y cluster.
