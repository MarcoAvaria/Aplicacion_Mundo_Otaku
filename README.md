flutter emulators --delete-all
flutter emulators --launch Pixel_3a_API_34_extension_level_7_x86_64
flutter emulators --launch Realme_X3_SuperZoom_API_31

# Nest - TesloShop Backend

## Development
1. Tener corriendo el servicio de Docker (Docker Desktop o Docker Deamon)
2. Clonar el archivo __.env.template__ y renombrar la copia a __.env__
3. Levantar los servicios con el comando
```
docker compose up -d
```
4. Llenar la base de datos con data temporal:

    http://localhost:3000/api/seed

5. Documentación de los endpoints disponibles:

    http://localhost:3000/api



# Extra
Si desean saber más sobre docker y cómo se construyó esta imagen, esto es parte de mi curso de Nest y Docker:

[Cursos sobre Docker](https://fernando-herrera.com/#/search/docker)

[Imagen en DockerHub](https://hub.docker.com/repository/docker/klerith/flutter-backend-teslo-shop/general)
