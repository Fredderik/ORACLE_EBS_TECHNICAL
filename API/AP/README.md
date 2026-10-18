# AP — APIs de proveedores

Ejemplos de llamada a procedimientos estándar; no crean ni reemplazan paquetes de Oracle.

| Archivo | Paquete.procedimiento | Identificador principal |
| --- | --- | --- |
| [crear_proveedor.sql](crear_proveedor.sql) | AP_VENDOR_PUB_PKG.CREATE_VENDOR | VENDOR_ID |
| [crear_sitio.sql](crear_sitio.sql) | AP_VENDOR_PUB_PKG.CREATE_VENDOR_SITE | VENDOR_SITE_ID |
| [crear_contacto.sql](crear_contacto.sql) | AP_VENDOR_PUB_PKG.CREATE_VENDOR_CONTACT | VENDOR_CONTACT_ID |

## Preparación

Ejecutar en una sesión APPS autorizada de desarrollo o pruebas. Verificar los tipos de registro y firmas instalados en la especificación del paquete o Integration Repository. Las firmas de referencia corresponden a R12.1/R12.2; los parches y la configuración pueden añadir validaciones.

Antes de la primera llamada, inicializar el contexto con [inicializar_contexto.sql](../../utilidades/FND/inicializar_contexto.sql). APPS_INITIALIZE no autentica ni concede permisos: los IDs deben pertenecer a un usuario y una responsabilidad autorizados. Usar una sesión nueva cuando se cambie de usuario/responsabilidad, pues algunos paquetes conservan valores globales de auditoría.

Todos los ejemplos reciben p_user_id, p_resp_id, p_resp_appl_id y p_org_id como NUMBER obligatorios. Comprueban el contexto contra esos valores, inicializan MO para SQLAP, verifican acceso y seleccionan la OU explícita. El proveedor es global; sus sitios pertenecen a una OU. Aquí el contexto EBS es necesario para ejecutar las APIs, aunque las consultas de validación usan filtros explícitos.

Desde la raíz del repositorio, en SQL*Plus:

```sql
VARIABLE p_user_id NUMBER
VARIABLE p_resp_id NUMBER
VARIABLE p_resp_appl_id NUMBER
VARIABLE p_org_id NUMBER

-- Sustituir por IDs autorizados reales antes de continuar.
EXEC :p_user_id := NULL;
EXEC :p_resp_id := NULL;
EXEC :p_resp_appl_id := NULL;
EXEC :p_org_id := NULL;

@utilidades/FND/inicializar_contexto.sql
```

Ejecutar cada paso por separado y detenerse ante cualquier error. SQL*Plus puede continuar un archivo después de un error; no añadir un COMMIT incondicional al final de una ejecución por lotes.

## Parámetros y orden

Declarar también las variables opcionales y asignarles NULL cuando no se utilicen. Los identificadores se obtienen del resultado anterior; no confundir IDs de interfaz, proveedor, sitio y TCA.

**1. Proveedor.** Nombre obligatorio. Número manual según la configuración; en numeración automática usar NULL. El ejemplo no carga información fiscal ni cuentas bancarias.

```sql
VARIABLE p_vendor_name VARCHAR2(240)
VARIABLE p_vendor_num VARCHAR2(30)
EXEC :p_vendor_name := 'Proveedor de ejemplo API';
EXEC :p_vendor_num := NULL;
@API/AP/crear_proveedor.sql
```

**2. Sitio.** Indicar el VENDOR_ID devuelto, código, dirección y país. Los flags de pago y compras aceptan Y/N; al menos uno debe ser Y. Los datos geográficos requeridos dependen del país. El ejemplo deja cuentas y términos a los valores predeterminados que determine la configuración; completar el registro cuando el negocio exija valores específicos.

```sql
VARIABLE p_vendor_id NUMBER
VARIABLE p_vendor_site_code VARCHAR2(15)
VARIABLE p_address_line1 VARCHAR2(240)
VARIABLE p_country VARCHAR2(2)
VARIABLE p_city VARCHAR2(60)
VARIABLE p_state VARCHAR2(150)
VARIABLE p_zip VARCHAR2(60)
VARIABLE p_pay_site_flag VARCHAR2(1)
VARIABLE p_purchasing_site_flag VARCHAR2(1)
EXEC :p_vendor_id := NULL;
EXEC :p_vendor_site_code := 'PRINCIPAL';
EXEC :p_address_line1 := 'Direccion de ejemplo';
EXEC :p_country := 'CO';
EXEC :p_city := 'Bogota';
EXEC :p_state := NULL;
EXEC :p_zip := NULL;
EXEC :p_pay_site_flag := 'Y';
EXEC :p_purchasing_site_flag := 'N';
-- Asignar el VENDOR_ID real y completar la dirección antes de ejecutar.
@API/AP/crear_sitio.sql
```

**3. Contacto.** Recibe el proveedor y un sitio activo de la OU. Crea una persona nueva; no es una operación de actualización ni un ejemplo para asociar una persona ya existente.

```sql
VARIABLE p_vendor_site_id NUMBER
VARIABLE p_first_name VARCHAR2(150)
VARIABLE p_last_name VARCHAR2(150)
VARIABLE p_email_address VARCHAR2(2000)
EXEC :p_vendor_site_id := NULL;
EXEC :p_first_name := 'Persona';
EXEC :p_last_name := 'Ejemplo';
EXEC :p_email_address := NULL;
-- Asignar el VENDOR_SITE_ID real antes de ejecutar.
@API/AP/crear_contacto.sql
```

## Retorno y transacciones

Los ejemplos pasan versión 1.0, inicialización de mensajes, validación completa y p_commit = FND_API.G_FALSE. Imprimen la pila de FND_MSG_PUB y aceptan únicamente estado S; E, U o NULL generan error. Los textos propios están en español; los mensajes de Oracle se conservan en el idioma devuelto por la sesión.

Una llamada exitosa deja cambios pendientes y muestra los IDs. Revisar en la misma sesión y decidir COMMIT o ROLLBACK manualmente. No hace falta lanzar un importador de proveedores. Si se consulta desde otra conexión, los cambios no serán visibles hasta confirmar.

Cada bloque establece su SAVEPOINT y revierte su operación ante error. Un fallo en contacto no deshace un proveedor o sitio creado por un bloque anterior. Para una unidad de trabajo completa, el llamador debe controlar una transacción exterior y detener el flujo ante el primer error.

Las comprobaciones de duplicados de proveedor/sitio son preventivas, no garantizan idempotencia ni excluyen carreras concurrentes. El contacto puede duplicarse al repetir la llamada; conservar IDs y revisar el resultado antes de reintentar. No combinar interfaz y API para crear la misma entidad.

Revisar las altas mediante [consultas de proveedores](../../consultas/AP/proveedores_configuracion.sql). Cuentas bancarias, instrumentos de pago, configuración fiscal y actualizaciones quedan fuera de estos ejemplos.

## Referencias y validación

- [Especificación AP_VENDOR_PUB_PKG R12.1](https://etrm.live/etrm-12.1.1/etrm.oracle.com/pls/et1211d9/etrm_pnav804d-9.html).
- [Especificación AP_VENDOR_PUB_PKG R12.2](https://etrm.live/etrm-12.2.2/etrm.oracle.com/pls/trm1222/etrm_pnav804d-5.html).
- [Alternativa de carga por interfaces AP](../../Interface/AP/README.md).

Firmas revisadas documentalmente y código revisado de forma estática. **Pendientes la compilación y las pruebas funcionales en una instancia EBS**. Comprobar alta válida, datos rechazados, OU sin acceso, duplicados y reversión antes de usar en una integración.

[Volver a API](../README.md)
