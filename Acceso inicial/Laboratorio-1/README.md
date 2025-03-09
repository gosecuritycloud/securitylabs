# Laboratorio: Descubrimiento de ID de Cuenta AWS a través de Aplicación Web

Este laboratorio demuestra cómo un atacante puede descubrir el ID de una cuenta de AWS aprovechando configuraciones inseguras en una aplicación web expuesta públicamente.

## Descripción General

El objetivo principal es simular un escenario donde un atacante, mediante el reconocimiento de puertos y la identificación de buckets S3 públicos con información sensible, puede obtener el ID de la cuenta AWS objetivo y potencialmente acceder a snapshots de EBS o RDS públicos con credenciales incrustadas.

## Requisitos Previos

* Una cuenta de AWS con credenciales de CLI configuradas.
* `nmap` instalado en tu sistema.
* Conocimientos básicos de AWS CLI y servicios como S3, EC2, EBS y RDS.

## Pasos

1.  **Reconocimiento de Puertos con Nmap**:
    * Ejecuta `nmap` contra la aplicación web para identificar puertos abiertos y servicios expuestos.
    * Ejemplo: `nmap -sV <dirección_IP_o_dominio>`

2.  **Identificación de Buckets S3 Públicos**:
    * Busca buckets S3 que puedan contener información sensible o estática de la aplicación.
    * Presta especial atención a archivos como `.pem` (claves privadas) o archivos de configuración.
    * Verifica si el acceso a estos buckets es público.

3.  **Configuración de Roles en la Cuenta del Atacante**:
    * En la cuenta AWS del atacante, configura un rol IAM que permita asumir privilegios suficientes para utilizar herramientas como `s3-account-id-discovery`.
    * Alternativamente, puedes ejecutar la herramienta en una instancia EC2 con un rol IAM preconfigurado.

4.  **Descubrimiento del ID de la Cuenta AWS**:
    * Utiliza una herramienta como `s3-account-id-discovery` para identificar el ID de la cuenta AWS objetivo a través de los buckets S3 públicos.

5.  **Búsqueda de Snapshots Públicos de EBS y RDS**:
    * Utiliza la AWS CLI para buscar snapshots públicos de EBS y RDS pertenecientes al ID de la cuenta objetivo.
    * Comando de ejemplo:
        ```bash
        aws ec2 describe-snapshots --owner-ids <ID_de_la_cuenta> --filters Name=public,Values=true
        aws rds describe-db-snapshots --include-public --db-snapshot-identifier <ID_de_la_cuenta>
        ```

6.  **Análisis de Snapshots**:
    * Si se encuentran snapshots públicos, analízalos en busca de posibles credenciales de AWS o información sensible.

## Herramientas Recomendadas

* `nmap`: Para reconocimiento de puertos y servicios.
* `awscli`: Para interactuar con los servicios de AWS desde la línea de comandos.
* `s3-account-id-discovery`: Herramienta para descubrir el ID de una cuenta AWS a través de buckets S3 públicos.

## Consideraciones de Seguridad

* Este laboratorio se realiza con fines educativos y de seguridad.
* No realices estas actividades en sistemas o cuentas que no te pertenezcan sin autorización.
* Asegura siempre la configuración de tus buckets S3 y snapshots para evitar la exposición de información sensible.

## Contribución

Las contribuciones son bienvenidas. Si tienes sugerencias o mejoras, por favor, abre un issue o envía un pull request.