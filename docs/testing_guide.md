# Guía de Pruebas en Dispositivo Real

Esta guía explica cómo instalar y probar la aplicación en tu celular para verificar los billetes de la Serie B.

## Requisitos Previos

1. Tener el celular conectado a tu computadora vía USB.
2. Tener habilitado el **Modo de Depuración USB** (en Android) o haber confiado en el equipo (en iOS).
3. Tener Flutter instalado en tu sistema.

## Pasos para Ejecutar

1. Abre una terminal en la carpeta raíz del proyecto.
2. Verifica que tu dispositivo sea detectado:
   ```bash
   flutter devices
   ```
3. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Cómo Probar la Detección

Para verificar que la aplicación funciona correctamente, puedes apuntar la cámara a los siguientes números de serie (puedes escribirlos en un papel o verlos en otra pantalla):

### Casos de Prueba (Billetes Inválidos - Serie B)

| Denominación | Número de Serie para Probar | Resultado Esperado     |
| :----------- | :-------------------------- | :--------------------- |
| **Bs 10**    | `77100005`                  | Alerta Roja (Inválido) |
| **Bs 10**    | `109400010`                 | Alerta Roja (Inválido) |
| **Bs 20**    | `87280200`                  | Alerta Roja (Inválido) |
| **Bs 20**    | `120500100`                 | Alerta Roja (Inválido) |
| **Bs 50**    | `67250050`                  | Alerta Roja (Inválido) |
| **Bs 50**    | `76310050`                  | Alerta Roja (Inválido) |

### Casos de Billetes Válidos

Cualquier número fuera de los rangos oficiales (ej. `00000001`) debería mostrar el indicador **Verde (Válido)**.

## Consejos para el Escaneo

- **Iluminación:** Asegúrate de tener buena luz sobre el billete.
- **Enfoque:** Mantén el número de serie dentro del recuadro blanco central.
- **Confirmación:** El sistema esperará 3 frames de lectura idéntica para confirmar. Si el número no se detecta de inmediato, mueve ligeramente el celular para ayudar al enfoque.
- **Vibración:** El celular vibrará cuando se detecte un billete inválido.
