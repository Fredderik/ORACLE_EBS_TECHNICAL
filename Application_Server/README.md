# Servidor de aplicaciones — Oracle EBS R12

Esta sección documenta el sistema de archivos del servidor de aplicaciones desde la perspectiva del desarrollador. Comienza con la ubicación de scripts, ejecutables y reportes; posteriormente podrá incluir despliegue y diagnóstico.

Los árboles son esquemas orientativos para UNIX/Linux, no un inventario de una instalación concreta. Las rutas dependen de la configuración y del nodo.

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

Ejemplo parcial para FND; cada producto utiliza los subdirectorios que necesita:

```text
$APPL_TOP/
└── fnd/
    └── 12.0.0/                   ← FND_TOP
        ├── sql/
        ├── bin/
        ├── reports/
        │   ├── US/
        │   └── <idioma_instalado>/
        ├── forms/
        │   ├── US/
        │   └── <idioma_instalado>/
        ├── mesg/
        │   ├── US.msb
        │   └── <idioma>.msb
        ├── resource/
        └── admin/
            └── sql/
```

El nombre `12.0.0` del directorio de producto puede mantenerse en R12.1 y R12.2; no identifica por sí solo la versión exacta instalada. [Oracle EBS Concepts, R12.2](https://docs.oracle.com/cd/E26401_01/doc.122/e22949/T120505T120509.htm).

## Directorios e idioma

| Ruta dentro de PROD_TOP | Uso habitual | Organización por idioma |
| --- | --- | --- |
| `sql/` | Scripts SQL*Plus para concurrentes. | No se divide normalmente por idioma. |
| `bin/` | Ejecutables y scripts de shell. | No se divide normalmente por idioma. |
| `reports/<idioma>/` | Definiciones Oracle Reports, por ejemplo `.rdf`. | Sí: subdirectorios por idioma. |
| `forms/<idioma>/` | Formularios compilados `.fmx`. | Sí: subdirectorios por idioma. |
| `mesg/` | Mensajes binarios `.msb`. | Idioma en el nombre del archivo. |
| `resource/` | Bibliotecas de Oracle Forms `.pll`. | Generalmente compartidas. |
| `admin/sql/` | Scripts de mantenimiento y creación de objetos PL/SQL. | Normalmente sin separación por idioma. |

`US` representa inglés americano; los demás códigos corresponden a idiomas instalados. Una carpeta sin división por idioma no implica que su código sea independiente de NLS. La organización anterior se basa en [Oracle EBS Concepts — Product Directories y Language Files](https://docs.oracle.com/cd/E18727_01/doc.121/e12841/T120505T120509.htm).

## Relación con las consultas FND

Las [consultas de FND](../Queries/FND/README.md) permiten identificar la aplicación del ejecutable, su nombre y método. Esos datos orientan la búsqueda del componente físico. La ruta depende del método: no todos los ejecutables registrados representan un archivo en `bin`.

Este README describe ubicaciones; no instala ni despliega componentes.

[Volver al inicio](../README.md)
