Realizar el *porting* (adaptación) de un controlador para un display LCD basándose en máquinas de estado (statecharts) es una de las mejores prácticas en sistemas embebidos. Al evitar funciones bloqueantes (como los clásicos `delay()`), permites que el microcontrolador atienda otras tareas mientras el LCD procesa la información.

Aquí tienes una guía estructurada paso a paso para tu Trabajo Práctico, cubriendo la configuración del sistema, el modelado y la implementación en C.

---

## 1. System Setup (Capa de Abstracción de Hardware)

Para que tu código sea **portable** (fácil de migrar de un Arduino a un STM32, PIC o ESP32), debes separar completamente la lógica de control del hardware específico. Esto se logra creando una capa de abstracción (HAL - Hardware Abstraction Layer).

En lugar de escribir en registros específicos (ej. `PORTB |= (1<<2)`), debes definir macros o funciones genéricas (punteros a función) en un archivo `lcd_hal.h`:

```c
// lcd_hal.h - Interfaz a implementar en el microcontrolador destino
void LCD_HAL_InitPins(void);
void LCD_HAL_SetRS(uint8_t state);
void LCD_HAL_SetEN(uint8_t state);
void LCD_HAL_WriteDataBus(uint8_t data); // Para modo de 4 u 8 bits
uint32_t LCD_HAL_GetTickMs(void);        // Temporizador del sistema (millis)

```

Al hacer esto, cuando cambies de microcontrolador, **solo reescribirás estas 5 funciones**; el resto de tu máquina de estados quedará intacto.

---

## 2. Modeling (Statechart)

El controlador HD44780 de los displays LCD requiere secuencias de inicialización y tiempos de espera de ejecución muy precisos (por ejemplo, esperar 2ms después de enviar el comando de borrar pantalla).

Para modelar esto sin bloquear el procesador, definimos los siguientes estados principales:

* `STATE_UNINIT`: Estado inicial al encender.
* `STATE_INIT_SEQ`: Ejecuta la secuencia de encendido (esperas de 15ms, 4ms, etc.).
* `STATE_IDLE`: Listo para recibir nuevos caracteres o comandos.
* `STATE_SENDING`: Alternando el pin EN (Enable) para enviar un nibble o byte.
* `STATE_BUSY_WAIT`: Esperando que pase el tiempo requerido por el comando anterior.

Para ayudarte a visualizar cómo fluye la lógica ante distintos eventos, aquí tienes un simulador interactivo de la máquina de estados:

---

## 3. C Coding (Implementación del Puerto)

A continuación, tienes la estructura principal del código C que implementa el statechart utilizando un enfoque *no bloqueante* (basado en polling periódico).

```c
// lcd_fsm.h
typedef enum {
    LCD_STATE_UNINIT,
    LCD_STATE_INIT_SEQ,
    LCD_STATE_IDLE,
    LCD_STATE_SENDING_CMD,
    LCD_STATE_SENDING_DATA,
    LCD_STATE_WAIT_DELAY
} LCD_State_t;

void LCD_Init(void);
void LCD_Update(void); // Se llama periódicamente en el loop principal
void LCD_PrintChar(char c);

// lcd_fsm.c
#include "lcd_fsm.h"
#include "lcd_hal.h"

static LCD_State_t current_state = LCD_STATE_UNINIT;
static LCD_State_t next_state = LCD_STATE_UNINIT;
static uint32_t wait_timestamp = 0;
static uint32_t wait_duration = 0;
static uint8_t pending_data = 0;

void LCD_Update(void) {
    uint32_t current_time = LCD_HAL_GetTickMs();

    switch (current_state) {
        case LCD_STATE_UNINIT:
            // Espera inicial de seguridad al dar energía
            wait_timestamp = current_time;
            wait_duration = 50; 
            next_state = LCD_STATE_INIT_SEQ;
            current_state = LCD_STATE_WAIT_DELAY;
            break;

        case LCD_STATE_INIT_SEQ:
            // Aquí iría la secuencia de inicialización (ej. 0x33, 0x32, 0x28...)
            // Por simplicidad, asumimos que terminó
            current_state = LCD_STATE_IDLE;
            break;

        case LCD_STATE_IDLE:
            // Esperando eventos externos (llamadas a LCD_PrintChar)
            break;

        case LCD_STATE_SENDING_DATA:
            LCD_HAL_SetRS(1);
            LCD_HAL_WriteDataBus(pending_data);
            
            // Pulso de Enable
            LCD_HAL_SetEN(1);
            // Pequeña espera (usualmente microsegundos, manejable sin FSM o con timer hardware)
            LCD_HAL_SetEN(0);

            // Demora requerida por el LCD para procesar (ej. 1 ms)
            wait_timestamp = current_time;
            wait_duration = 1;
            next_state = LCD_STATE_IDLE;
            current_state = LCD_STATE_WAIT_DELAY;
            break;

        case LCD_STATE_WAIT_DELAY:
            if ((current_time - wait_timestamp) >= wait_duration) {
                current_state = next_state; // El tiempo expiró, avanza
            }
            break;
            
        default:
            current_state = LCD_STATE_UNINIT;
            break;
    }
}

void LCD_PrintChar(char c) {
    if (current_state == LCD_STATE_IDLE) {
        pending_data = c;
        current_state = LCD_STATE_SENDING_DATA;
    }
    // Nota: en un sistema real, aquí implementarías un buffer circular (FIFO)
    // para encolar varios caracteres si el estado no es IDLE.
}

```

> **Nota clave:** La función `LCD_Update()` debe ser llamada constantemente desde el bucle infinito `while(1)` de tu función `main()`. Al no tener demoras bloqueantes, el loop corre a máxima velocidad.
