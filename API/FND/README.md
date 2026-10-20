# FND — Combinaciones contables

[combinaciones_contables.sql](combinaciones_contables.sql) obtiene el identificador contable (CCID) mediante `FND_FLEX_EXT.GET_CCID`. Puede crear la combinación cuando no existe, sujeto a la configuración del flexfield, inserción dinámica y validaciones de EBS. No es una operación de solo lectura.

Se organiza bajo FND porque el paquete pertenece a Application Object Library; se aplica al flexfield contable de GL mediante `SQLGL` y `GL#`. El script obtiene `CHART_OF_ACCOUNTS_ID` del libro indicado, sin asumir que coincida con `LEDGER_ID`.

## Parámetros

| Variable | Tipo | Uso |
| --- | --- | --- |
| p_user_id | NUMBER | Usuario del contexto EBS previamente inicializado. |
| p_resp_id | NUMBER | Responsabilidad autorizada para la operación. |
| p_resp_appl_id | NUMBER | Aplicación de esa responsabilidad. |
| p_ledger_id | NUMBER | Libro cuyo plan de cuentas se utilizará. |
| p_segmentos | VARCHAR2(2000) | Valores en orden de presentación, con el separador configurado; conservar ceros iniciales. |
| p_fecha_validacion | VARCHAR2(10) | Fecha explícita AAAA-MM-DD. |
| p_code_combination_id | NUMBER | Salida: CCID; NULL ante un error. |

## Ejecución

Usar una conexión con permisos sobre los objetos estándar de APPS. Inicializar primero el contexto mediante [inicializar_contexto.sql](../../utilidades/FND/inicializar_contexto.sql), siguiendo sus parámetros, en la misma sesión y antes de llamar a FND_FLEX_EXT. El script comprueba que el contexto coincida con los identificadores proporcionados; esto no sustituye la autorización funcional sobre el libro.

Ejemplo SQL*Plus / SQL Developer en modo script, desde la raíz del repositorio. Sustituir los NULL y los segmentos ficticios antes de ejecutar:

```sql
VARIABLE p_user_id NUMBER
VARIABLE p_resp_id NUMBER
VARIABLE p_resp_appl_id NUMBER
VARIABLE p_ledger_id NUMBER
VARIABLE p_segmentos VARCHAR2(2000)
VARIABLE p_fecha_validacion VARCHAR2(10)
VARIABLE p_code_combination_id NUMBER

EXEC :p_user_id := NULL;
EXEC :p_resp_id := NULL;
EXEC :p_resp_appl_id := NULL;
EXEC :p_ledger_id := NULL;
EXEC :p_segmentos := '01.000.111000.0000';
EXEC :p_fecha_validacion := '2026-10-19';

-- Inicializar aquí el contexto con los identificadores reales, siguiendo
-- utilidades/FND/inicializar_contexto.sql, antes de ejecutar el ejemplo.
@API/FND/combinaciones_contables.sql
PRINT p_code_combination_id
```

## Resultado y transacción

Un CCID positivo indica éxito. Cero o NULL se trata como error y se muestra `GET_MESSAGE`. Los mensajes propios están en español; el texto devuelto por Oracle depende del idioma del entorno. La API utiliza el contexto de sesión de EBS para sus validaciones; la consulta propia a GL_LEDGERS usa un parámetro explícito y una tabla base.

GET_CCID no distingue en su retorno si encontró o creó la combinación. No crea valores de segmento ni configura el plan de cuentas. Un CCID válido tampoco prueba acceso al libro, disponibilidad presupuestaria ni que pueda utilizarse en cualquier transacción.

El script no ejecuta COMMIT. Ante una excepción revierte hasta su SAVEPOINT y propaga el error. En caso de éxito, finalizar pronto con COMMIT para conservar los cambios o ROLLBACK para descartarlos: la creación puede mantener bloqueos. Ambos comandos afectan también otros cambios pendientes de la sesión; usar una sesión de trabajo controlada. Tras ROLLBACK no reutilizar un CCID recién creado.

## Referencias y validación

Firma y comportamiento contrastados con el [paquete público FND_FLEX_EXT de R12.2](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnavf637-11.html?c_detail_type=source&c_name=FND_FLEX_EXT&c_owner=APPS&c_type=PACKAGE) y su [implementación R12.1](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavca0c-12.html). La fecha se convierte explícitamente al formato requerido por GET_CCID.

Pendiente compilación y ejecución en EBS con los parches del entorno. Probar combinación existente, nueva permitida, segmentos inválidos y reversión de una creación.

[Volver a APIs](../README.md)
