# AWS Pentesting Labs: Acceso Inicial

¡Bienvenido a la serie de laboratorios de pentesting en AWS! Este repositorio está diseñado para simular los pasos iniciales que un pentester podría tomar al obtener acceso a una cuenta de AWS. A través de estos 10 laboratorios, exploraremos diversas técnicas y herramientas para identificar y explotar configuraciones inseguras.

## Índice de Laboratorios

1.  **[Descubrimiento de ID de Cuenta a través de Aplicación Web](lab1/README.md)**:
    * Explotación de configuraciones inseguras en aplicaciones web y buckets S3 públicos para obtener el ID de la cuenta.
2.  **[Enumeración de Usuarios IAM](lab2-iam-enumeration/README.md)**:
    * Técnicas para enumerar usuarios y roles de IAM y comprender la estructura de permisos.
3.  **[Escalamiento de Privilegios con Roles IAM](lab3-iam-role-escalation/README.md)**:
    * Explotación de roles IAM con permisos excesivos para escalar privilegios.
4.  **[Acceso a Snapshots Públicos de EBS y RDS](lab4-public-snapshots/README.md)**:
    * Búsqueda y análisis de snapshots públicos en busca de credenciales y datos sensibles.
5.  **[Explotación de Buckets S3 Inseguros](lab5-s3-exploitation/README.md)**:
    * Técnicas para identificar y explotar buckets S3 con configuraciones de acceso inseguras.
6.  **[Acceso a Instancias EC2 a través de Metadatos](lab6-ec2-metadata/README.md)**:
    * Ataques a instancias EC2 para acceder a metadatos y obtener credenciales temporales.
7.  **[Manipulación de Funciones Lambda](lab7-lambda-exploitation/README.md)**:
    * Identificación y explotación de vulnerabilidades en funciones Lambda.
8.  **[Ataques a API Gateway](lab8-api-gateway-attacks/README.md)**:
    * Técnicas de pentesting para API Gateway, incluyendo ataques de inyección y autenticación.
9.  **[Análisis de Logs de CloudTrail](lab9-cloudtrail-analysis/README.md)**:
    * Análisis de registros de CloudTrail para identificar actividades sospechosas y patrones de ataque.
10. **[Ataques a Contenedores ECR y ECS](lab10-container-attacks/README.md)**:
    * Explotación de vulnerabilidades en contenedores ECR y ECS.

## Requisitos Generales

* Cuenta de AWS para fines de prueba.
* AWS CLI configurado.
* Conocimientos básicos de seguridad en la nube y pentesting.
* Las herramientas necesarias para cada laboratorio serán especificadas en su respectivo README.md.

## Consideraciones Importantes

* Estos laboratorios deben ser realizados en entornos de prueba propios.
* No realices pentesting en cuentas de AWS sin autorización.
* Siempre cumple con las políticas de AWS y las leyes aplicables.

## Contribución

Si tienes sugerencias, mejoras o quieres contribuir con nuevos laboratorios, ¡eres bienvenido! Abre un issue o envía un pull request.

¡Disfruta aprendiendo y mejorando tus habilidades de pentesting en AWS!