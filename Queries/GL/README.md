# GL — General Ledger

Consultas y ejemplos técnicos de contabilidad general para Oracle EBS R12 en adelante. Conservan el formato de cabecera del repositorio, la autoría y la versión inicial **1.0**.

## Archivos

| Archivo | Resultados |
| --- | --- |
| [asientos_detalle.sql](asientos_detalle.sql) | Lote, cabecera, líneas, importes, origen, categoría y combinación contable con `SEGMENT1` a `SEGMENT30`. |
| [analisis_cuenta.sql](analisis_cuenta.sql) | Detalle contabilizado de una cuenta natural y comparación con `GL_BALANCES`. |
| [configuracion_gl.sql](configuracion_gl.sql) | Libros, períodos abiertos y significado/configuración de segmentos. |
| [carga_gl_interface.sql](carga_gl_interface.sql) | Plantilla PL/SQL de carga de dos líneas y pasos de importación estándar. **Contiene INSERT; ejecutar por separado.** |

Se consultan tablas base y traducciones `_TL` mediante idioma explícito; no vistas `_VL` ni contexto de sesión. En R12.2 se conservan los sinónimos y las vistas de edición internas de EBS.

## Orden de uso

1. Consulta `configuracion_gl.sql` para identificar libro, calendario y cuenta natural.
2. Usa `asientos_detalle.sql` para investigar los asientos del período.
3. Usa `analisis_cuenta.sql` para comparar sus movimientos con los saldos.
4. Consulta la plantilla de interfaz cuando necesites preparar un asiento externo.

El inventario de libros refleja los objetos accesibles al usuario de base de datos; no reproduce los permisos de una responsabilidad o Data Access Set de EBS.

## Parámetros de lectura

Todos los binds deben declararse. Los filtros opcionales aceptan `NULL`.

| Archivo | Obligatorios | Opcionales |
| --- | --- | --- |
| Detalle | `p_ledger_id`, `p_period_name`, `p_language` | `p_je_batch_id`, `p_je_header_id`, `p_code_combination_id`, `p_status`, `p_je_source`, `p_je_category` |
| Análisis | `p_ledger_id`, `p_period_name`, `p_account_value` | `p_code_combination_id`, `p_tolerance` |
| Configuración | `p_language` | `p_ledger_id`: NULL lista todos los libros |

`p_account_value` es texto: conserva los ceros iniciales. Origen y categoría usan sus códigos internos. El idioma usa códigos EBS como `US`. Los nombres de período deben coincidir exactamente con la configuración del libro.

### Cuenta natural y combinación contable

La cuenta natural puede estar en cualquier columna `SEGMENTn`. El calificador `GL_ACCOUNT` identifica esa columna para el plan de cuentas del libro. El análisis evalúa las 30 posiciones posibles.

`p_account_value` agrupa todas sus combinaciones de detalle. `p_code_combination_id` permite limitar el análisis a una combinación concreta. Una combinación debe cumplir ambos filtros.

En configuración, `display_sequence` es el orden visual y `application_column_name` la columna física. Un segmento puede tener varios calificadores; por eso puede ocupar varias filas. El análisis necesita exactamente un calificador de cuenta natural por estructura: revisa la configuración si no se encuentra o si Oracle informa varias filas en la subconsulta.

## Cómo interpretar el análisis

Ambas consultas comparten libro, período, cuenta natural y CCID opcional.

- Se incluyen asientos reales (`A`), contabilizados (`P`) y ordinarios.
- Se suman `ACCOUNTED_DR/CR` en moneda del libro, incluso si la moneda ingresada fue extranjera.
- Se excluyen asientos estadísticos y ajustes de saldo promedio.
- Se comparan saldos de detalle en moneda del libro, sin traducciones, presupuestos ni compromisos.
- Las combinaciones históricas deshabilitadas permanecen en el análisis.

La primera consulta muestra cada línea y totales analíticos por combinación/cuenta. **Los totales se repiten: no deben sumarse nuevamente.** Para sumar el detalle usa `accounted_dr`, `accounted_cr` o `line_net`.

La segunda separa:

```text
Movimiento = débitos del período - créditos del período
Saldo final = saldo inicial + movimiento
```

El saldo inicial se toma de `GL_BALANCES`; no se reconstruye la historia anterior. `CUADRA` exige que coincidan débito y crédito por separado dentro de la tolerancia (NULL = 0.01). Un neto cero no basta.

Se distinguen ausencia de saldo, movimientos sin saldo y múltiples filas de saldo. Una fila de saldo existente sin movimiento puede cuadrar aunque la primera consulta esté vacía. Sin una combinación que cumpla los filtros, ambas consultas quedan vacías.

Comprueba el período y evita comparar resultados obtenidos mientras se contabilizan nuevos asientos. Investiga diferencias: no ajustes tablas contables para forzar la coincidencia.

### Ejemplo SQL*Plus: análisis

Valores ficticios; sustituirlos por los obtenidos en configuración:

```sql
VARIABLE p_ledger_id NUMBER
VARIABLE p_period_name VARCHAR2(15)
VARIABLE p_account_value VARCHAR2(25)
VARIABLE p_code_combination_id NUMBER
VARIABLE p_tolerance NUMBER

EXEC :p_ledger_id := 1234;
EXEC :p_period_name := 'OCT-26';
EXEC :p_account_value := '04100';
EXEC :p_code_combination_id := NULL;
EXEC :p_tolerance := 0.01;

@Queries/GL/analisis_cuenta.sql
```

Para configuración, declara `p_language VARCHAR2(4)` y `p_ledger_id NUMBER`. Para detalle añade los binds indicados en su cabecera: los identificadores son NUMBER; estado, origen y categoría son VARCHAR2.

Ejecuta en modo script: `/` termina las consultas intermedias sin un `;` previo; la última termina con `;`.

## Plantilla de interfaz

El alcance del ejemplo es intencionalmente concreto: dos CCID distintos, débito y crédito por el mismo importe, moneda del libro, período normal abierto y mismo valor de segmento de balanceo.

La cabecera enumera todos los binds; las descripciones pueden ser NULL. La fecha se introduce como texto `YYYY-MM-DD`. El bloque deriva la moneda del libro y respeta la configuración **Import Using Key** para origen y categoría.

Las comprobaciones previas no sustituyen la validación completa de Journal Import. El script contiene los pasos de lanzamiento desde la ventana estándar y deja el control de la transacción al operador. Una nueva ejecución después de importar puede duplicar el asiento: la comprobación de `GROUP_ID` solo detecta filas todavía presentes en la interfaz. No es un mecanismo de idempotencia.

## Validación y referencias

Las seis consultas SELECT se ejecutaron contra datos simulados en SQLite para revisar filtros, uniones y conciliación. El bloque PL/SQL recibió revisión estática; **no fue compilado ni ejecutado en Oracle**. Falta validación en una instancia EBS con su configuración y parches.

- [Oracle EBS General Ledger User's Guide: Journal Import](https://docs.oracle.com/cd/E18727_01/doc.121/e13627/T312864T451269.htm).
- [Oracle ETRM: GL_BALANCES (copia del esquema R12.2.2)](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav40c0.html).
- [Oracle ETRM: GL_INTERFACE (copia del esquema R12.2.2)](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavfe53.html).

[Volver al inicio](../../README.md)
