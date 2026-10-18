# QP — APIs de listas de precios y modificadores

Ejemplos para Oracle Advanced Pricing en EBS R12.1/R12.2, organizados por operación. No requieren DML directo sobre tablas funcionales.

| Archivo | Operación |
| --- | --- |
| [crear_lista_precios.sql](crear_lista_precios.sql) | Crea una cabecera PRL local, activa y sin líneas. |
| [agregar_articulo.sql](agregar_articulo.sql) | Agrega una línea PLL de precio unitario fijo para un artículo y UOM. |
| [actualizar_precio.sql](actualizar_precio.sql) | Modifica el importe de una línea PLL por sus IDs y precio anterior esperado. |
| [crear_descuento.sql](crear_descuento.sql) | Crea una lista DLT y una línea DIS porcentual por artículo, inicialmente inactiva. |
| [ejemplos_ejecucion.md](ejemplos_ejecucion.md) | Declaración de todos los parámetros y secuencia de ejecución. |

## Contexto y preparación

1. Usar una sesión de desarrollo autorizada con acceso a los sinónimos APPS y a las APIs públicas.
2. Declarar y asignar `p_user_id`, `p_resp_id`, `p_resp_appl_id` y `p_org_id`. Ejecutar [inicializar_contexto.sql](../../utilidades/FND/inicializar_contexto.sql) antes de los ejemplos, en la misma sesión. Cambiar de usuario o responsabilidad requiere una sesión nueva para evitar conservar variables de paquetes.
3. Utilizar una responsabilidad con configuración de ONT/QP, acceso a la unidad operativa, perfiles de sistema origen y seguridad de precios apropiados. APPS_INITIALIZE establece contexto; no autentica al usuario ni concede permisos.
4. Los bloques comprueban el contexto contra los parámetros, inicializan MO para ONT y verifican el acceso a la unidad operativa. La organización de inventario es un identificador distinto: debe corresponder al maestro de artículos configurado para Pricing.
5. Verificar moneda, redondeo, UOM/conversiones, fechas y atributos de producto configurados. El ejemplo utiliza el atributo estándar de artículo `ITEM/PRICING_ATTRIBUTE1`. El código conserva los nombres y códigos técnicos de Oracle.

Las listas de estos ejemplos son locales: `GLOBAL_FLAG = N`. Crear cabeceras verifica después que `ORIG_ORG_ID` corresponda a la unidad solicitada; si los valores predeterminados del entorno no producen esa asociación, se deshace la operación. Agregar o actualizar exige ese mismo alcance y no modifica listas globales ni de otra unidad.

Las APIs pueden tomar valores predeterminados de perfiles y generan traducciones según su contrato y el idioma del contexto EBS. No ofrecen en estos ejemplos un parámetro de idioma para traducir nombres. Para consultar las traducciones se utiliza el idioma explícito de las [consultas QP](../../consultas/QP/README.md). No cambiar tablas TL manualmente.

## Parámetros y alcance

Los cuatro bloques reciben los cuatro NUMBER comunes del contexto. Declarar también los parámetros opcionales como NULL.

- **Crear lista:** `p_name`, `p_currency_code`, `p_start_date` obligatorios; `p_description` y `p_end_date` opcionales; `p_rounding_factor` NUMBER entero obligatorio (por ejemplo, -2 para dos decimales, sujeto a reglas de moneda). No contempla configuración multimoneda.
- **Agregar artículo:** `p_list_header_id`, `p_inventory_item_id`, `p_inventory_org_id`, `p_unit_price` NUMBER; `p_uom_code` y `p_start_date` obligatorios; `p_end_date` opcional. Precio no negativo. Rechaza cualquier línea existente del artículo/UOM, incluso histórica: para manejar períodos o tramos se requiere ampliar el ejemplo.
- **Actualizar precio:** `p_list_header_id`, `p_list_line_id`, `p_expected_price` y `p_unit_price` NUMBER obligatorios. Bloquea la fila con NOWAIT y compara el precio anterior. Una línea inexistente, bloqueada, de otra lista o basada en fórmula provoca error. Cambia el importe vigente; no crea un historial de precios ni recalcula pedidos ya ingresados.
- **Crear descuento:** `p_name`, `p_currency_code`, `p_start_date`, `p_inventory_item_id`, `p_inventory_org_id`, `p_uom_code`, `p_discount_percent`, `p_pricing_phase_id`, `p_pricing_group_sequence`, `p_incompatibility_grp_code`, `p_pte_code` y `p_source_system_code` obligatorios; `p_description` y `p_end_date` opcionales. Porcentaje mayor que 0 y hasta 100. Fase, secuencia, incompatibilidad, PTE y origen deben corresponder a la configuración real; no se fijan IDs de otro entorno.

Todas las fechas de entrada son VARCHAR2 con formato estricto YYYY-MM-DD. No se incluyen calificadores por cliente, acumulaciones, promociones, fórmulas ni tramos. El descuento está limitado al artículo/UOM, **no a una lista de precios ni a un cliente**. Al activarlo, podría aplicarse a todos los clientes elegibles del alcance configurado. Revisar fase, eventos, incompatibilidades y reglas de elegibilidad desde EBS antes de activarlo.

## Retorno y transacción

Los ejemplos utilizan `QP_PRICE_LIST_PUB.PROCESS_PRICE_LIST` o `QP_MODIFIERS_PUB.PROCESS_MODIFIERS`, con versión API 1.0 y `p_commit => fnd_api.g_false`. El éxito se evalúa por `x_return_status`; los mensajes se leen de **OE_MSG_PUB** y se imprimen en DBMS_OUTPUT. El texto nativo de Oracle se conserva en el idioma que devuelva EBS.

Se inicializan los registros con G_MISS para distinguir campos omitidos de NULL. En las altas la API genera los identificadores; los atributos se enlazan mediante el índice de la línea de entrada. La salida muestra el ID de cabecera y, al agregar un artículo, el ID de línea.

No hay COMMIT automático. Ante error se revierte al SAVEPOINT del bloque y se propaga la excepción. Ante éxito revisar el resultado en la misma sesión y decidir COMMIT o ROLLBACK. Mantener autocommit desactivado; SQL*Plus puede confirmar al salir normalmente, por lo que debe decidirse la transacción antes de cerrar. El bloqueo de actualización permanece hasta esa decisión. Los bloques no son idempotentes: una nueva ejecución puede crear otro registro o fallar por duplicidad.

## Validación

Revisión estática de parámetros, llamadas, aliases, sintaxis de consultas y control de transacción. **Pendiente compilación y ejecución en una instancia EBS**; R12.1/R12.2 son versiones objetivo, no certificación de todos los niveles de parche.

Probar creación, alta de artículo, actualización y descuento inactivo; comprobar cabecera/línea/atributo y ejecutar ROLLBACK inicialmente. Probar también un precio anterior incorrecto, una línea de otra lista, acceso MO denegado, artículo/UOM inválidos y fechas invertidas. En dos sesiones comprobar NOWAIT y, después de confirmar, el rechazo del precio anterior desactualizado. Las prevalidaciones no sustituyen la validación funcional ni la seguridad de la API.

## Referencias

- [Oracle: guía de implementación de Advanced Pricing R12.1](https://docs.oracle.com/cd/E18727_01/doc.121/e13428/T327893T327913.htm).
- [Fuente Oracle QP_PRICE_LIST_PUB, conservada en eTRM 12.2.2](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav4761-15.html?c_detail_type=source&c_name=QP_PRICE_LIST_PUB&c_owner=APPS&c_type=PACKAGE+BODY).
- [Especificación Oracle QP_MODIFIERS_PUB, conservada en eTRM 12.2.2](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav5ac3-22.html).

Consultar la especificación instalada y el Integration Repository del entorno antes de ejecutar. Para simulaciones de precios existe PRICE_REQUEST, fuera del alcance de estos cuatro ejemplos.

[Volver al catálogo de APIs](../README.md)
