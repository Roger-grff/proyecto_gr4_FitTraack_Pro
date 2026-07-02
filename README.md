# 🏃 FitTrack Pro
### Registro Deportivo con GPS

> Proyecto Final - Desarrollo de Aplicaciones Móviles  
> Escuela de Formación de Tecnólogos - EPN

---

# 📖 Descripción

**FitTrack Pro** es una aplicación móvil desarrollada en **Flutter** que permite a los usuarios registrar y monitorear sus actividades deportivas utilizando el GPS del dispositivo.

La aplicación registra recorridos en tiempo real, calcula estadísticas básicas como distancia y tiempo, almacena la información en la nube y permite consultar el historial de actividades. Además, integra servicios externos para enriquecer la experiencia del usuario.

El objetivo es desarrollar un **MVP (Minimum Viable Product)** funcional, intuitivo y publicado en una tienda de aplicaciones.

---

# 🎯 Objetivo General

Desarrollar una aplicación móvil que permita registrar recorridos deportivos mediante GPS, almacenar la información en la nube y visualizar estadísticas del usuario.

---

# 🎯 Objetivos Específicos

- Implementar autenticación de usuarios.
- Registrar actividades deportivas mediante GPS.
- Almacenar recorridos en Firebase.
- Consumir APIs externas.
- Visualizar historial y estadísticas.
- Publicar la aplicación en una tienda.
- Obtener usuarios reales antes de la defensa.

---

# 👥 Roles del Sistema

## 👤 Usuario

El usuario podrá:

- Registrarse.
- Iniciar sesión.
- Editar su perfil.
- Iniciar recorridos deportivos.
- Pausar recorridos.
- Finalizar recorridos.
- Visualizar el mapa.
- Consultar historial.
- Consultar estadísticas.
- Editar actividades.
- Eliminar actividades.

---

## 👨‍💼 Administrador

El administrador podrá:

- Administrar usuarios.
- Visualizar todas las actividades.
- Eliminar actividades.
- Eliminar usuarios.
- Consultar estadísticas generales.
- Supervisar el funcionamiento del sistema.

---

# 📱 Navegación del Sistema

```
Splash
   │
Login / Registro
   │
Home
 │
 ├── 🏠 Principal
 ├── 📊 Historial
 ├── 👤 Perfil
 └── ⚙ Configuración
```

---

# 📲 Pantallas del Sistema

## 🚀 Splash

Pantalla inicial de carga.

### Funcionalidades

- Mostrar logo.
- Verificar sesión.
- Redirigir al Login o Home.

---

## 🔐 Login

Permite autenticarse.

### Funcionalidades

- Iniciar sesión.
- Recuperar contraseña.
- Acceder al registro.

---

## 📝 Registro

Permite crear una nueva cuenta.

### Información solicitada

- Nombre
- Correo
- Contraseña

---

# 🏠 Home

El Home contiene la navegación principal mediante un **Bottom Navigation Bar**.

Tabs disponibles:

- Principal
- Historial
- Perfil
- Configuración

---

# 🏃 Principal

Es la pantalla principal de entrenamiento.

## Contenido

- Google Maps
- Ubicación actual
- Distancia recorrida
- Tiempo transcurrido
- Calorías estimadas
- Elevación
- Botón Iniciar
- Botón Pausar
- Botón Finalizar

### Funcionalidades

- Obtener ubicación GPS.
- Registrar recorrido.
- Dibujar la ruta.
- Calcular distancia.
- Calcular tiempo.
- Consultar elevación.
- Guardar recorrido.

---

# 📊 Historial

Muestra todas las actividades realizadas.

Cada actividad mostrará:

- Fecha
- Distancia
- Tiempo
- Tipo de actividad
- Calorías

### Funcionalidades

- Consultar actividades.
- Editar actividad.
- Eliminar actividad.
- Ver detalle.

---

# 📍 Detalle del Recorrido

Información completa de una actividad.

### Contenido

- Mapa
- Ruta
- Tiempo
- Distancia
- Velocidad promedio
- Elevación
- Calorías

---

# 👤 Perfil

Información del usuario.

### Contenido

- Foto
- Nombre
- Correo
- Fecha de registro

### Funcionalidades

- Editar perfil.
- Cambiar fotografía.
- Cambiar contraseña.
- Ver estadísticas personales.

---

# ⚙ Configuración

Opciones generales.

### Funcionalidades

- Cambiar tema.
- Modo oscuro.
- Idioma.
- Permisos.
- Notificaciones.
- Acerca de.
- Cerrar sesión.

---

# 📈 Estadísticas

Visualización de métricas deportivas.

### Información

- Distancia total.
- Tiempo acumulado.
- Calorías.
- Elevación promedio.
- Actividades realizadas.

---

# 🗄 Base de Datos

## Usuarios

```text
uid
nombre
correo
foto
fechaRegistro
rol
```

---

## Actividades

```text
idActividad
uidUsuario
fecha
horaInicio
horaFin
distancia
duracion
velocidadPromedio
calorias
elevacion
rutaGPS
```

---

# ⚙ Funcionalidades Principales

## Autenticación

- Registro
- Login
- Logout

---

## GPS

- Obtener ubicación.
- Registrar recorrido.
- Mostrar Google Maps.

---

## CRUD

Crear actividades.

Consultar actividades.

Editar actividades.

Eliminar actividades.

---

## API Externa

Consumo de:

- Google Maps API
- Google Elevation API

---

## Firebase

- Authentication
- Firestore
- Storage

---

# 🛠 Tecnologías

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Google Maps Flutter
- Google Elevation API
- Geolocator
- Provider

---

# 📂 Arquitectura

```
lib/
│
├── core/
│
├── models/
│
├── services/
│
├── repositories/
│
├── providers/
│
├── screens/
│   ├── auth/
│   ├── home/
│   ├── history/
│   ├── profile/
│   ├── settings/
│
├── widgets/
│
├── utils/
│
└── main.dart
```

---

# 👨‍💻 Distribución del Equipo

## Integrante 1

### Autenticación

- Login
- Registro
- Perfil
- Firebase Authentication

---

## Integrante 2

### GPS

- Google Maps
- Geolocalización
- Distancia
- Tiempo
- Ruta

---

## Integrante 3

### Base de Datos

- Firestore
- CRUD
- Historial

---

## Integrante 4

### APIs

- Google Elevation API
- Estadísticas
- Dashboard

---

## Integrante 5

### UI/UX

- Diseño
- Navegación
- Configuración
- Publicación
- README
- APK
- AAB

---

# 📌 Requerimientos Funcionales

- Registro de usuarios.
- Inicio de sesión.
- Gestión del perfil.
- Registro de recorridos.
- Uso del GPS.
- Almacenamiento en la nube.
- CRUD de actividades.
- Historial.
- Consumo de APIs.
- Estadísticas.
- Publicación en tienda.

---

# 🔒 Requerimientos No Funcionales

- Flutter.
- Firebase.
- Google Maps.
- API REST.
- Android.
- GitHub.
- README.
- APK.
- AAB.
- Publicación en Google Play.

---

# 🚀 Mejoras Propuestas

- 🌙 Modo oscuro.
- 📊 Dashboard con gráficas.
- 🏆 Sistema de logros.
- 🎯 Metas deportivas.
- 🌦 Consulta del clima.
- 🔔 Notificaciones.
- 📍 Compartir recorrido.
- 📱 Diseño responsive.

---

# 📷 Capturas de Pantalla

## Splash

> Agregar captura

---

## Login

> Agregar captura

---

## Home

> Agregar captura

---

## Principal

> Agregar captura

---

## Historial

> Agregar captura

---

## Perfil

> Agregar captura

---

## Configuración

> Agregar captura

---

# 📹 Video de Demostración

Agregar enlace del video.

---

# 📥 Descarga

APK

AAB

Google Play

---

# 👨‍🎓 Autores

Proyecto desarrollado para la asignatura **Desarrollo de Aplicaciones Móviles**.

Escuela Politécnica Nacional - ESFOT
