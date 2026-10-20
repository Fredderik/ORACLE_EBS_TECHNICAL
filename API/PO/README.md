# PO — APIs de Oracle Purchasing

Ejemplos PL/SQL para órdenes de compra **estándar** en EBS R12.1/R12.2. Las funciones se invocan mediante las APIs públicas, sin DML directo sobre tablas funcionales.

| Archivo | Operación |
| --- | --- |
| [actualizar_orden.sql](actualizar_orden.sql) | Cambiar cantidad, precio o fechas mediante PO_CHANGE_API1_S.UPDATE_PO. |
| [registrar_aceptacion.sql](registrar_aceptacion.sql) | Registrar aceptación o rechazo del proveedor mediante RECORD_ACCEPTANCE. |
| [cancelar_documento.sql](cancelar_documento.sql) | Cancelar cabecera, línea o envío mediante PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT. |
| [diagnostico_operaciones.sql](diagnostico_operaciones.sql) | Revisar revisión, estados, líneas, envíos, aceptaciones, errores y códigos. |
| [ejemplos_ejecucion.md](ejemplos_ejecucion.md) | Declaración de todos los parámetros y ejecución. |

## Preparación

Utilizar una sesión autorizada de desarrollo con acceso a los sinónimos APPS y permisos sobre las APIs. Declarar los NUMBER `p_user_id`, `p_resp_id`, `p_resp_appl_id` y `p_org_id`; ejecutar [inicializar_contexto.sql](../../utilidades/FND/inicializar_contexto.sql) antes del bloque y en la misma conexión. Usar una responsabilidad de Purchasing, con comprador y acceso a la unidad operativa configurados.

APPS_INITIALIZE establece contexto, no autentica ni concede permisos. Los ejemplos comprueban los IDs contra el contexto, inicializan MO para PO y verifican acceso a la unidad operativa. Usar una sesión nueva al cambiar usuario o responsabilidad para no conservar variables globales de paquetes.

El identificador de orden es `PO_HEADERS_ALL.PO_HEADER_ID`; el número visible se obtiene de SEGMENT1 después de validar unidad operativa y tipo STANDARD. La revisión esperada se compara con REVISION_NUM bajo bloqueo NOWAIT. Una revisión distinta, orden ajena o documento bloqueado produce error. Las validaciones funcionales y de seguridad definitivas corresponden a la API.

## Parámetros

Todos los binds deben declararse, incluso los opcionales. Fechas VARCHAR2 con formato estricto YYYY-MM-DD. NULL en valores nuevos de UPDATE_PO significa no cambiar el campo; estos ejemplos no permiten borrar una fecha mediante NULL.

**Comunes a las tres operaciones:** los cuatro IDs de contexto, `p_po_header_id` y `p_revision_num`, todos NUMBER obligatorios.

**Actualización:**

- `p_line_num` NUMBER obligatorio; `p_shipment_num` NUMBER opcional.
- `p_new_quantity` NUMBER positivo y `p_new_price` NUMBER no negativo, opcionales.
- `p_new_promised_date` y `p_new_need_by_date` VARCHAR2 opcionales; requieren envío.
- `p_override_date` VARCHAR2 opcional: fecha para desreservar fondos cuando corresponde.
- Indicar al menos un cambio. Una cantidad es el nuevo total, no un incremento. Sin envío el cambio se aplica a la línea; con envío la API aplica sus reglas de distribución y acumulación. Comprobar todos los envíos afectados.
- No incluye releases, acuerdos, órdenes complejas, atributos de doble unidad ni cambios de comprador. No lanza aprobaciones automáticamente: revisar el estado y tramitar la reaprobación estándar cuando corresponda.

**Aceptación/rechazo:**

- `p_accepted_flag` VARCHAR2: Y o N.
- `p_acceptance_lookup_code` VARCHAR2 obligatorio, código válido de ACCEPTANCE TYPE; revisar los códigos y su vigencia con el diagnóstico.
- `p_action_date` VARCHAR2 obligatorio y `p_note` VARCHAR2 opcional.
- La aceptación comercial del proveedor no es la aprobación interna del documento. Se utiliza el comprador de la orden; no se confunde EMPLOYEE_ID con USER_ID. El ejemplo pasa X_ACTION=NEW según la especificación pública.
- La API no devuelve ID de aceptación. Consultarlo en PO_ACCEPTANCES por orden/revisión. No repetir automáticamente una operación exitosa: podría registrar otra aceptación.

**Cancelación:**

- `p_nivel` VARCHAR2 obligatorio: CABECERA, LINEA o ENVIO.
- CABECERA requiere `p_po_line_id` y `p_line_location_id` NULL; LINEA exige solo el ID de línea; ENVIO exige ambos IDs NUMBER.
- `p_action_date`, `p_cancel_reason` obligatorios; `p_note` opcional.
- `p_cancel_reqs_flag` y `p_use_gldate`: Y/N explícitos. El primero decide si también se cancelan requisiciones asociadas; el segundo afecta la asignación contable de fondos desreservados.
- `p_confirmar_cancelacion` debe ser SI para llamar a la API. Por defecto el ejemplo de ejecución usa NO.
- La cabecera afecta el documento completo; una línea incluye sus envíos. No confundir cancelar con cerrar, cerrar para recepción o cerrar definitivamente. El contrato revisado de CONTROL_DOCUMENT contempla CANCEL; no se presentan esos cierres como acciones soportadas.

## Retornos y transacciones

**UPDATE_PO** devuelve NUMBER: 1 éxito, 0 error; no devuelve S/E/U. Los errores llegan en PO_API_ERRORS_REC_TYPE y se imprimen desde MESSAGE_TEXT. El ejemplo mantiene LAUNCH_APPROVALS_FLAG=N: la ruta de aprobación síncrona puede emitir COMMIT y no se incluye en este bloque. Tras éxito revisar y decidir COMMIT o ROLLBACK manualmente.

**RECORD_ACCEPTANCE** devuelve también 1/0. El script genera un identificador con PO_INTERFACE_ERRORS_S e imprime los errores CHANGEPO de esa transacción. Los errores pueden persistir porque Oracle los registra mediante una transacción autónoma; un ROLLBACK funcional no elimina ese diagnóstico. Los cambios funcionales quedan pendientes de confirmación manual.

Ambos scripts usan SAVEPOINT, revierten su operación ante error y propagan la excepción. No activar autocommit; decidir la transacción antes de salir de SQL*Plus, que puede confirmar al cerrar normalmente.

**CONTROL_DOCUMENT es una excepción:** la especificación pública R12.1 pide `p_commit = FND_API.G_TRUE` para cancelación. El ejemplo respeta ese contrato, aunque el cuerpo de la API admite el parámetro booleano. Ejecutar en una **sesión exclusiva sin trabajo pendiente**: una llamada exitosa confirma la transacción y no se puede deshacer con ROLLBACK posterior. Los errores se leen de FND_MSG_PUB; el manejador libera cambios/bloqueos aún pendientes y pide revisar el estado final, sin afirmar que revierte una cancelación confirmada. No es una simulación.

Los mensajes propios están en español; los mensajes de Oracle mantienen el idioma que devuelve EBS.

## Altas de órdenes y requisiciones

Para crear documentos desde sistemas externos, Oracle documenta **Purchasing Documents Open Interface (PDOI)** para órdenes estándar y **Requisition Import** para requisiciones. Son cargas e importaciones y deben organizarse en Interface/PO cuando se implementen. Esta entrega incluye las tres operaciones anteriores, no las plantillas de carga ni un supuesto procedimiento público genérico de creación.

## Validación y referencias

Objetivo R12.1/R12.2, sujeto a firmas y parches instalados. Revisión estática realizada; **compilación y ejecución en EBS pendientes**. Confirmar el contrato en Integration Repository y la especificación instalada.

En desarrollo probar revisión incorrecta, unidad operativa distinta, envío de otra orden, bloqueo en segunda sesión y datos inválidos. Para actualización y aceptación comprobar resultados en la misma sesión y su reversión. Probar cancelación únicamente sobre documentos de prueba, verificando persistencia desde otra sesión y el efecto sobre requisiciones/fondos.

- [Fuente Oracle: PO_CHANGE_API1_S R12.1, conservada en eTRM](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavae1a-17.html).
- [Fuente Oracle: implementación de cambios y aceptación](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav943a-10.html).
- [Fuente Oracle: contrato de CONTROL_DOCUMENT](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav4598-12.html).
- [Fuente Oracle: comportamiento transaccional de aprobación](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnavf20c-15.html).
- [Oracle Purchasing R12.1: PDOI](https://docs.oracle.com/cd/E18727_01/doc.121/e13410/T446883T443954.htm).
- [Oracle Purchasing R12.1: Requisition Import](https://docs.oracle.com/cd/E18727_01/doc.121/e13410/T446883T443952.htm).

[Consultas PO](../../consultas/PO/README.md) · [Catálogo de APIs](../README.md)
