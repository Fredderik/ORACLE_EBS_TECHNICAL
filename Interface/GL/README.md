# GL — interfaz de importación de asientos

[carga_gl_interface.sql](carga_gl_interface.sql) contiene la plantilla PL/SQL y los pasos para lanzar la importación estándar. Se trasladó desde `Queries/GL` conservando íntegros el código, la cabecera, la autoría y la versión **1.1**.

## Plantilla de interfaz

El alcance del ejemplo es intencionalmente concreto: dos CCID distintos, débito y crédito por el mismo importe, moneda del libro, período normal abierto y mismo valor de segmento de balanceo.

La cabecera enumera todos los binds; las descripciones pueden ser NULL. La fecha se introduce como texto `YYYY-MM-DD`. El bloque deriva la moneda del libro y respeta la configuración **Import Using Key** para origen y categoría.

Las comprobaciones previas no sustituyen la validación completa de Journal Import. El script contiene los pasos de lanzamiento desde la ventana estándar y deja el control de la transacción al operador. Una nueva ejecución después de importar puede duplicar el asiento: la comprobación de `GROUP_ID` solo detecta filas todavía presentes en la interfaz. No es un mecanismo de idempotencia.


## Ejecución y ubicación

Declara todos los parámetros enumerados en la cabecera antes de ejecutar el archivo. Desde la raíz del repositorio, la ruta es:

```sql
@Interface/GL/carga_gl_interface.sql
```

Consulta primero [los libros, períodos y combinaciones de GL](../../Queries/GL/README.md). El archivo incluye INSERT y no debe ejecutarse como parte de una batería de consultas de lectura.

## Validación y referencias

El traslado no cambia la lógica del bloque PL/SQL. **No fue compilado ni ejecutado en Oracle**; sigue pendiente su validación en una instancia EBS con sus parches y configuración.

- [Oracle EBS General Ledger: Journal Import](https://docs.oracle.com/cd/E18727_01/doc.121/e13627/T312864T451269.htm).
- [Oracle eTRM: GL_INTERFACE](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavfe53.html).

[Interfaces](../README.md) · [Inicio](../../README.md)
