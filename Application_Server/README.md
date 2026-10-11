# Servidor de aplicaciones — Oracle EBS R12

Esta sección documenta el sistema de archivos del servidor de aplicaciones desde la perspectiva del desarrollador. Incluye la ubicación de scripts, ejecutables y reportes, además de comandos para migrar componentes.

Los árboles son esquemas orientativos para UNIX/Linux, no un inventario de una instalación concreta. Las rutas dependen de la configuración y del nodo.

## Programas Host en bin

[Shell básico y guía de despliegue](bin/README.md): log, variables, condicionales, bucle, SQL, Java y SFTP; permisos, formato UNIX y enlace a fndcpesr.

## Migración de componentes

Consulta [FNDLOAD y XDOLoader](fndload/README.md) para descargar y subir concurrentes, listas de valores, metadatos de XML Publisher, plantillas RTF y otros componentes.

## Ubicación de una aplicación

`APPL_TOP` agrupa los productos. El `<PROD>_TOP` identifica la raíz de uno de ellos; por ejemplo, `FND_TOP`. Una aplicación personalizada debe tener su basepath registrado: crear una carpeta por sí solo no la registra en EBS. [Oracle Developer's Guide](https://docs.oracle.com/cd/E26401_01/doc.122/e22961/T302934T303723.htm).

### Ejemplo de R12.1

```text
<base>/
├── apps/
│   ├── apps_st/
│   │   ├── appl/                  ← APPL_TOP
│   │   └── comn/                  ← COMMON_TOP
│   └── tech_st/                   ← componentes tecnológicos
└── inst/apps/<contexto>/          ← INST_TOP
```

### Ejemplo de R12.2

```text
<base>/
├── fs1/
│   ├── EBSapps/
│   │   ├── appl/                 ← APPL_TOP de este filesystem
│   │   └── comn/                 ← COMMON_TOP de este filesystem
│   ├── FMW_Home/
│   └── inst/apps/<contexto>/      ← INST_TOP
├── fs2/
│   ├── EBSapps/
│   │   ├── appl/
│   │   └── comn/
│   ├── FMW_Home/
│   └── inst/apps/<contexto>/
└── fs_ne/                        ← archivos no editionados
```

En R12.2, `fs1` y `fs2` alternan los roles `run` y `patch` durante el parcheo online: **fs1 no siempre es run**. `fs_ne` conserva datos y determinados logs que deben permanecer entre ciclos. Este modelo no debe trasladarse a R12.1. Consulta [File System Structure, R12.2](https://docs.oracle.com/cd/E26401_01/doc.122/e22949/T120505T120509.htm) y [File System, R12.1](https://docs.oracle.com/cd/E18727_01/doc.121/e12841/T120505T120509.htm).

## Árbol dentro del producto

Esquema de referencia; no todos los productos utilizan todas las carpetas:

```text
$APPL_TOP/
├── admin/                         ← administración global
└── <producto>/
    └── 12.0.0/                    ← <PROD>_TOP
        ├── admin/                 ← administración del producto
        │   ├── driver/
        │   ├── import/
        │   ├── odf/
        │   ├── sql/
        │   └── <idioma>/
        ├── bin/
        ├── forms/<idioma>/
        ├── help/<idioma>/
        ├── html/
        ├── include/
        ├── java/
        ├── lib/
        ├── log/
        ├── out/
        ├── media/
        ├── mesg/
        ├── patch/
        ├── reports/<idioma>/
        ├── resource/
        └── sql/
```

`12.0.0` no determina la versión exacta instalada. [Oracle EBS Concepts, R12.2](https://docs.oracle.com/cd/E26401_01/doc.122/e22949/T120505T120509.htm).

## Directorios y tipos de archivo

Resumen de **todas las entradas de la tabla 2-1** de [Oracle EBS Concepts, R12.1](https://docs.oracle.com/cd/E18727_01/doc.121/e12841/T120505T120509.htm), contrastado con [Product Files, R12.2](https://docs.oracle.com/cd/E26401_01/doc.122/e22949/T120505T120509.htm).

Rutas relativas a `<PROD>_TOP`. **S**: subcarpetas por idioma; **F**: idioma en el archivo; **—**: la tabla no prescribe separación lingüística.

| Ruta | Función / tipos de archivo | Idioma |
| --- | --- | --- |
| `admin/` | Actualización del producto; puede contener cargas traducidas. | S, parcialmente |
| `admin/driver/` | Controladores de actualización: `.drv`. | — |
| `admin/import/` | DataMerge: actualización de datos semilla. | — |
| `admin/odf/` | Definiciones de objetos: `.odf`. | — |
| `admin/sql/` | Actualización SQL*Plus; creación PL/SQL: `.pkh`, `.pkb`, `.pls`. | — |
| `bin/` | Concurrentes, programas C y scripts shell. | — |
| `forms/` | Formularios ejecutables: `.fmx`. | S |
| `help/` | Fuentes de ayuda online. | S |
| `html/` | HTML, JavaScript y JSP. | — |
| `include/` | Cabeceras C: `.h`. | — |
| `java/` | JAR y dependencias Java; copias en `AF_JLIB`. | — |
| `lib/` | Reenlace: objetos `.o/.OBJ`, bibliotecas `.a/.DLL`, reglas `.mk`. | — |
| `log/`, `out/` | Logs y salidas; `.mgr` del gestor, `.req` del proceso. | — |
| `media/` | Imágenes; R12.1 especifica `.gif`. | — |
| `mesg/` | Mensajes binarios: `.msb`. | F |
| `patch/` | Parches de datos/modelo. | — |
| `reports/` | Oracle Reports: `.rdf`. | S |
| `resource/` | Bibliotecas Forms: `.pll`, copiadas a `AU_TOP`. | — |
| `sql/` | Concurrentes SQL*Plus: `.sql`. | — |

### Cómo interpretar las rutas

- `admin/sql` y `sql` tienen funciones distintas; por eso SQL aparece dos veces.
- `APPL_TOP/admin` administra el conjunto; `PROD_TOP/admin`, el producto.
- Con logs centralizados, las carpetas de producto dejan de utilizarse, salvo la excepción documentada de `FND_TOP`.
- `US` identifica inglés americano y `D`, alemán: por ejemplo, `reports/US` o `mesg/D.msb`.

Estas precisiones proceden de la [tabla 2-1 y Language Files](https://docs.oracle.com/cd/E18727_01/doc.121/e12841/T120505T120509.htm). **—** no significa independencia de NLS: comprueba la configuración del componente. En particular, no presupongas carpetas de idioma para `sql` o `bin`.

## Relación con las consultas FND

Las [consultas de FND](../consultas/FND/README.md) permiten identificar la aplicación del ejecutable, su nombre y método. Esos datos orientan la búsqueda del componente físico. La ruta depende del método: no todos los ejecutables registrados representan un archivo en `bin`.

Este README describe ubicaciones; no instala ni despliega componentes.

[Volver al inicio](../README.md)
