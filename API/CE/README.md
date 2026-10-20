# CE — APIs de bancos y cuentas internas

Ejemplos de **CE_BANK_PUB** para Oracle Cash Management R12.1/R12.2. Cubren el flujo banco → sucursal → cuenta bancaria interna → uso por unidad operativa.

| Archivo | Procedimiento | Resultado |
| --- | --- | --- |
| [crear_banco.sql](crear_banco.sql) | CREATE_BANK | ID TCA del banco. |
| [crear_sucursal.sql](crear_sucursal.sql) | CREATE_BANK_BRANCH | ID TCA de la sucursal. |
| [crear_cuenta_interna.sql](crear_cuenta_interna.sql) | CREATE_BANK_ACCT | BANK_ACCOUNT_ID. |
| [crear_uso_cuenta.sql](crear_uso_cuenta.sql) | CREATE_BANK_ACCT_USE | BANK_ACCT_USE_ID para AP y/o AR. |
| [diagnostico_configuracion.sql](diagnostico_configuracion.sql) | Consultas de tablas base | IDs, propietario, estados y cuentas contables. |
| [ejemplos_ejecucion.md](ejemplos_ejecucion.md) | Guía SQL*Plus | Declaración y asignación de todos los binds. |

## Alcance y contexto

Son cuentas **internas de la empresa**, con clasificación INTERNAL y una sola moneda. No son cuentas externas de proveedores o clientes, ni incluyen conciliación, extractos, transferencias, tesorería XTR o nómina. No se incluyen todavía actualizaciones ni bajas.

Los bancos y sucursales se representan como parties de TCA. El propietario de la cuenta es una **entidad legal**: en estos ejemplos ACCOUNT_OWNER_ORG_ID se carga con LEGAL_ENTITY_ID y ACCOUNT_OWNER_PARTY_ID se obtiene de XLE_ENTITY_PROFILES. La **OU del uso** es un identificador diferente y se registra en CE_BANK_ACCT_USES_ALL. No intercambiar estos IDs.

Antes de ejecutar, declarar los NUMBER obligatorios `p_user_id`, `p_resp_id` y `p_resp_appl_id`, y ejecutar [inicializar_contexto.sql](../../utilidades/FND/inicializar_contexto.sql) en la misma sesión. Emplear una responsabilidad y usuario autorizados para mantenimiento bancario y acceso a la entidad legal. APPS_INITIALIZE establece contexto; no autentica ni otorga permisos. Cambiar de usuario/responsabilidad requiere una sesión nueva para no conservar variables globales de paquetes.

Crear el uso inicializa MO para CE y comprueba acceso a la OU indicada. Esa comprobación no sustituye los permisos de mantenimiento bancario ni las reglas de acceso de la entidad legal. Las consultas base de diagnóstico tampoco aplican por sí mismas la seguridad funcional de las pantallas EBS: ejecutarlas solo con acceso autorizado.

## Parámetros

Declarar también los opcionales con NULL. Códigos y números bancarios son VARCHAR2 para conservar ceros iniciales. Las fechas son VARCHAR2 con formato estricto YYYY-MM-DD.

| Script | Obligatorios además del contexto | Opcionales |
| --- | --- | --- |
| Crear banco | p_country_code, p_bank_name | p_bank_number, p_description |
| Crear sucursal | p_bank_id (NUMBER), p_branch_name | p_branch_number, p_branch_type, p_bic, p_description |
| Crear cuenta | p_branch_id y p_legal_entity_id (NUMBER); p_bank_account_name, p_bank_account_num, p_currency_code, p_start_date, p_ap_allowed, p_ar_allowed | p_account_type, p_iban, p_check_digits, p_description, p_end_date |
| Crear uso | p_org_id, p_bank_account_id, p_legal_entity_id, p_ledger_id y p_cash_ccid (NUMBER); p_ap_enabled, p_ar_enabled, p_validation_date | Ninguno |
| Diagnóstico | Declarar los cinco NUMBER p_bank_id, p_branch_id, p_legal_entity_id, p_bank_account_id, p_org_id | Se permite NULL para omitir resultados del filtro correspondiente. |

Los indicadores AP/AR admiten Y/N y exigen al menos una aplicación habilitada. En el uso no puede habilitarse una aplicación que no esté permitida en la cabecera bancaria.

La opcionalidad de país, tipo de sucursal, número, IBAN o dígitos depende también de la localización: un parámetro opcional en la firma puede ser obligatorio por las validaciones del país. No omitir esas validaciones ni inventar códigos de lookup. El tipo de cuenta y el tipo de sucursal deben existir en la configuración instalada.

## Orden de ejecución y validaciones

1. Crear banco; conservar el ID devuelto. CHECK_BANK_EXIST comprueba coincidencias antes del alta.
2. Crear sucursal con ese banco; conservar el ID devuelto. CHECK_BRANCH_EXIST comprueba coincidencias.
3. Crear cuenta con la sucursal y entidad legal. Se comprueba vigencia de la entidad, fechas y coincidencia exacta de número/sucursal. La API valida y puede normalizar los datos bancarios según el país.
4. Crear el uso con la cuenta y OU. Se verifica propietario, vigencia, indicadores de aplicación, libro de la OU y combinación contable.
5. Ejecutar diagnóstico y revisar la configuración desde EBS antes de utilizar la cuenta.

Las comprobaciones de duplicados no convierten los scripts en idempotentes ni sustituyen las validaciones de Oracle. Si el banco o sucursal ya existen, reutilizar sus IDs después de verificar identidad y vigencia; no ejecutar el alta otra vez.

El ejemplo de uso es básico, ORG_TYPE=OU. Verifica el libro mediante HR_ORGANIZATION_INFORMATION y el plan contable mediante GL_LEDGERS. La combinación de efectivo debe estar habilitada, vigente, permitir contabilización de detalle y no ser resumen. Se utiliza la misma combinación como efectivo general y como efectivo AP/AR de las aplicaciones habilitadas.

No se configura automáticamente la totalidad de cuentas de compensación, diferencias, remesas, descuentos ni actividades de AR. Completar las cuentas y reglas que requiera el proceso contable real. Crear el uso no crea métodos de recibo, perfiles de pago ni garantiza que toda la configuración para pagar o cobrar esté completa. El vínculo permitido entre OU y entidad propietaria debe verificarse en la configuración de acceso bancario del entorno; no se deduce por igualdad entre sus IDs.

`p_validation_date` sirve para revisar vigencia; **no programa el inicio del uso**. El uso se crea sin fecha final. Un uso existente, incluso inactivo, se rechaza y debe revisarse para una futura actualización. El bloqueo NOWAIT sobre la cuenta evita que dos ejecuciones de este ejemplo creen simultáneamente el mismo uso; permanece hasta terminar la transacción.

## Retorno y transacción

Estas cuatro firmas no reciben p_api_version ni p_commit; no se agregan parámetros de otras APIs. Se usa p_init_msg_list=FND_API.G_TRUE, se comprueba X_RETURN_STATUS y se imprime el contenido de FND_MSG_PUB junto con el ID creado. Los mensajes propios están en español; los mensajes nativos mantienen el idioma de EBS.

Los scripts no ejecutan COMMIT. Cada bloque toma un SAVEPOINT, revierte su operación ante error y propaga la excepción. Tras éxito, revisar en la misma sesión y decidir COMMIT o ROLLBACK manualmente. Mantener autocommit desactivado; decidir antes de cerrar SQL*Plus, que puede confirmar al salir. Un error posterior no deshace automáticamente los bloques anteriores: cada uno tiene su propio SAVEPOINT.

El diagnóstico muestra solo los últimos cuatro caracteres de la cuenta y no muestra IBAN. No guardar números reales ni mensajes de error con información bancaria en el repositorio.

## Validación y referencias

Revisión estática de firmas, campos, parámetros, consultas y control de transacción. **Pendiente compilación y ejecución en una instancia EBS**. R12.1/R12.2 son versiones objetivo; revisar la especificación instalada, parches y catálogo de Integration Repository.

Probar el flujo con datos de prueba y ROLLBACK; verificar creación y persistencia solo después de confirmar. Probar duplicados, país/códigos inválidos, propietario inexistente, OU sin acceso, libro incorrecto, CCID de otro plan contable y aplicación no permitida. En dos sesiones comprobar el bloqueo del alta de uso. El diagnóstico no sustituye las validaciones de seguridad funcional.

- [Fuente Oracle: CE_BANK_PUB R12.1 conservada en eTRM](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav1039-10.html?c_detail_type=source&c_name=CE_BANK_PUB&c_owner=APPS&c_type=PACKAGE).
- [Fuente Oracle: CE_BANK_PUB R12.2 conservada en eTRM](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav1039-11.html?c_detail_type=source&c_name=CE_BANK_PUB&c_owner=APPS&c_type=PACKAGE).
- [Fuente Oracle: implementación y validaciones](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnave82e-5.html).

[Consultas CE](../../consultas/CE/README.md) · [Catálogo de APIs](../README.md)
