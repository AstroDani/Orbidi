Esta solución se compone de 3 proyectos
ApiFastApi: Proyecto con un ejemplo de una aplicación en FastAPI que consulta la versión a una base de datos
pruebaTecnicaOrbidiImage: Proyecto que crea un repositorio de ECR, esto es necesario debido a que si se intenta crear la infraestructura sin tener una imagen subida al repositorio se pueden generar problemas en el despliegue
pruebaTecnicaOrbidi: Proyecto que crea la infraestructura requerida

Como se cumplen los requisitos?

Seguridad: Los roles de IAM tienen la mínima cantidad de permisos necesarios, los grupos de seguridad solo permiten el acceso desde los componentes de la aplicación que requieren acceso, el RDS y el EC2/ECS se encuentran en subnets privadas, con acceso a internet desde un NAT Gateway, solo el ALB permite acceso desde internet, si se quisiera mas seguridad se podría crear un dominio, certificado y cloudfront con un dominio custom, haciendo que el ALB solo permita conexiones desde el Cloudfront.

Escalabilidad: Las instancias de EC2 están en un grupo de autoescalado, las tareas de ECS están en un servicio que se puede configurar en autoescalado usando como métrica las peticiones del ALB, el ALB escala automáticamente, el RDS es serverless y escala automáticamente.

Parámetros de conexión: El RDS genera automáticamente sus parámetros de conexión, los cuales se pueden consultar como outputs de Terraform, para propósitos de seguridad se estableció que la contraseña del usuario maestro debería ser generada automáticamente y estar guardada de forma segura en SSM como un SecureString, insertando el valor en ValueFrom a ECS, este procedimiento se puede realizar en el resto de parámetros de la conexión.

Instrucciones de despliegue
1. Entrar al proyecto pruebaTecnicaOrbidiImage y ejecutar el script deploy.sh
2. Entrar al proyecto ApiFastApi y ejecutar el script deploy.sh
3. Entrar al proyecto pruebatecnicaOrbidi y ejecutar el script deploy.sh

En los 3 casos este script puede en un futuro usarse en un pipeline (ej GitHub Actions) para automatizar el despliegue.