# 🛠️ Swift Thread Synchronization Demo (SwiftUI)

![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-16.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-007ACC?style=for-the-badge&logo=swift&logoColor=white)

Aplicación interactiva en **SwiftUI** diseñada para simular **50 hilos concurrentes** ejecutándose en paralelo sobre un recurso compartido (`balance`). 

El objetivo del proyecto es comparar visualmente la aparición de **Race Conditions (Condiciones de Carrera)** en código no protegido versus las distintas soluciones de sincronización disponibles en el ecosistema de Swift.

---

## 📖 Artículo Completo en el Blog

Este repositorio forma parte de la guía detallada sobre concurrencia y sincronización de hilos en iOS.

👉 **[Leer artículo completo: Sincronización en Swift: De NSLock a Actores y OSAllocatedUnfairLock](https://blog.maxovandodev.dev/blog/03-sincronizaci%C3%B3n-en-swift-de-nslock-a-actores-y-osallocatedunfairlock/)**

---

## 🧪 Métodos Simulados en el Proyecto

Cada prueba lanza **50 hilos independientes**, intentando depositar $10 en la cuenta (`Resultado Esperado: $500`).

| Método | Tipo / Framework | Resultado | Descripción |
| :--- | :--- | :---: | :--- |
| **0. Unsafe** | Sin protección | ❌ **Error (< $500)** | Demuestra la colisión de hilos y la pérdida masiva de datos por accesos concurrentes no atómicos. |
| **1. NSLock** | `Foundation` | ✅ **$500** | Exclusión mutua (*Mutex*) tradicional mediante hilos POSIX. |
| **2. Actor** | `Swift Concurrency` | ✅ **$500** | Aisle de estado mutable garantizado por el compilador en tiempo de compilación. |
| **3. DispatchQueue** | `GCD` | ✅ **$500** | Sincronización manual mediante una cola serial (`queue.async`). |
| **4. OSAllocatedUnfairLock** | `os` (iOS 16+) | ✅ **$500** | Bloqueo de bajo nivel y alto rendimiento, libre del overhead de Objective-C. |

---

## 📸 Capturas e Interfaz

La aplicación incluye:
* **Tarjeta de estado dinámica:** Muestra en tiempo real si el resultado coincide con los **$500 esperados** o si hubo corrupción de datos (marcado en rojo).
* **Consola de logs en tiempo real:** Captura la marca de tiempo exacta (milisegundos) y la dirección de memoria del hilo ejecutor (`Thread-0x...`) para auditar el orden de llegada.

## 📸 Demostración en Vivo

![SwiftUI Concurrency Demo](https://media.giphy.com/media/qJprDLEUC0KrKFd89m/giphy.gif)

---

## 🚀 Requisitos e Instalación

* **Xcode:** 15.0 o superior.
* **iOS:** 16.0+ (Requerido para `OSAllocatedUnfairLock`).
* **Swift:** 5.9+

### Clonar el repositorio:
```bash
git clone https://github.com/MaxOvandoDev/ios-lock-example.git
cd ios-lock-example
open ios-lock-example.xcodeproj
```

## 👨‍💻 Autor
* Maximiliano Ovando Ramírez

* Blog: blog.maxovandodev.dev

* GitHub: @MaxOvandoDev