Realizar el *porting* (adaptación) de un controlador para un display LCD basándose en máquinas de estado (statecharts) es una de las mejores prácticas en sistemas embebidos. Al evitar funciones bloqueantes (como los clásicos `delay()`), permites que el microcontrolador atienda otras tareas mientras el LCD procesa la información.

<img width="2048" height="1365" alt="image" src="https://github.com/user-attachments/assets/a8e3ba9d-2003-4dd6-8f10-9a198c52cb35" />
<sub> Display LCD 16x2 estándar. Fuente: LexaAdams / Getty Images </sub>
<br/>
<br/>
Aquí tienes una guía estructurada paso a paso para tu Trabajo Práctico, cubriendo la configuración del sistema, el modelado y la implementación en C.


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



## 2. Modeling (Statechart)

El controlador HD44780 de los displays LCD requiere secuencias de inicialización y tiempos de espera de ejecución muy precisos (por ejemplo, esperar 2ms después de enviar el comando de borrar pantalla).

Para modelar esto sin bloquear el procesador, definimos los siguientes estados principales:

* `STATE_UNINIT`: Estado inicial al encender.
* `STATE_INIT_SEQ`: Ejecuta la secuencia de encendido (esperas de 15ms, 4ms, etc.).
* `STATE_IDLE`: Listo para recibir nuevos caracteres o comandos.
* `STATE_SENDING`: Alternando el pin EN (Enable) para enviar un nibble o byte.
* `STATE_BUSY_WAIT`: Esperando que pase el tiempo requerido por el comando anterior.

Para ayudarte a visualizar cómo fluye la lógica ante distintos eventos, aquí tienes un simulador interactivo de la máquina de estados:

<img width="1416" height="1334" alt="image" src="https://github.com/user-attachments/assets/2721f708-0c65-4071-9bdd-2581a5887e6c" />


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

<br/>
<br/>
El sistema implementa una arquitectura basada en eventos (Event-Triggered System) utilizando un planificador de tareas cooperativo sin sistema operativo (bare-metal).

### Análisis de los archivos de código fuente

* **`app.c`**: Implementa el planificador principal. Define la lista de tareas (`task_test` y `task_display`), las inicializa mediante `app_init()` y las ejecuta periódicamente en el bucle principal `app_update()`. También contabiliza métricas de ejecución, como el número de ejecuciones, y los tiempos de ejecución actual, mejor y peor (LET, BCET, WCET).


* **`app_it.c`**: Contiene las rutinas de servicio de interrupción (ISR) del microcontrolador. Incrementa la variable `g_app_tick_cnt` en cada interrupción del temporizador del sistema (SysTick) a través del callback `HAL_SYSTICK_Callback`, gestionando así el tiempo base de la aplicación.


* **`systick.c`**: Proporciona la función `systick_delay_us`, la cual genera demoras bloqueantes (busy-waiting) precisas en microsegundos monitoreando directamente los registros del hardware del SysTick.


* **`display.h` y `display.c**`: Conforman la capa de abstracción de hardware y el controlador de bajo nivel para el display LCD. `displayInit` envía las secuencias de inicialización en modo de 4 u 8 bits. Las funciones `displayCharPositionWrite` y `displayStringWrite` controlan directamente los pines GPIO (RS, RW, EN y el bus de datos) para enviar instrucciones o caracteres al LCD.


* **`task_display_interface.c`**: Funciona como la API pública para interactuar con la tarea del display. Implementa `put_event_task_display`, que copia un mensaje de texto dentro de un buffer de memoria interno (`ddram`), establece el evento a `EV_DSP_UPDATE` y activa una bandera (`flag = true`) para notificar a la máquina de estados que hay nueva información pendiente de ser mostrada.


* **`task_test_attribute.h`**: Define la estructura de datos interna `task_test_dta_t`, declarando las variables `tick` y `counter` necesarias para el estado de la tarea de prueba.


* **`task_test.c`**: Es la tarea de aplicación o prueba. En `task_test_init`, inicializa sus variables y envía un texto de presentación estático ("LCD Display Test", " Porting C code ") mediante la interfaz del display. Posteriormente, se actualiza llamando a su statechart.


* **`task_display.c`**: Es la tarea dedicada a refrescar el LCD mediante una máquina de estados no bloqueante. En `task_display_init`, inicializa el hardware del display en modo de 4 bits y realiza una primera escritura del buffer `ddram` en las filas 0 y 1.



### Comportamiento de `void task_test_statechart(void)`

Esta función actúa como el núcleo cíclico de la tarea de prueba, ejecutándose periódicamente cada vez que el planificador llama a `task_test_update()`:

* Incrementa el contador interno `counter` en cada única iteración.


* Decrementa la variable temporizadora `tick` siempre que su valor sea mayor que `DEL_TEST_XX_MIN` (0).


* Cuando `tick` alcanza 0, reinicia su valor asignándole la constante `DEL_TEST_XX_MAX` para comenzar un nuevo ciclo de demora.


* En ese instante de reinicio de tiempo, envía a la interfaz del display la cadena predeterminada "Test Nro: ******" posicionándola al inicio de la fila 1.


* Inmediatamente después, calcula el número actual del test dividiendo `counter` entre `DEL_TEST_XX_MAX`, convierte este valor a texto y lo envía a la columna 10 de la fila 1, sobrescribiendo los asteriscos de la instrucción previa.



### Comportamiento de `void task_display_statechart(void)`

Esta función procesa el vaciado de los buffers de texto al hardware real basándose en una máquina de estados finitos que previene el uso de código secuencial bloqueante a nivel de aplicación superior:

* Inicia su ciclo en el estado por defecto `ST_DSP_IDLE`.


* Mientras se encuentra en `ST_DSP_IDLE`, monitorea constantemente las variables de notificación; si `flag` equivale a `true` y el evento es `EV_DSP_UPDATE`, realiza la transición hacia el estado `ST_DSP_UPDATE`.


* Al ingresar al estado `ST_DSP_UPDATE`, desactiva inmediatamente la bandera estableciendo `flag = false`.


* Posiciona el cursor físico en la fila 0, columna 0 usando el driver subyacente y escribe la cadena de texto completa almacenada en el buffer `ddram[0]`.


* Repite el procedimiento posicionando el cursor en la fila 1, columna 0 e imprimiendo el contenido de `ddram[1]`.


* Al finalizar la transferencia de datos, retorna el estado actual de la máquina a `ST_DSP_IDLE` para aguardar futuras actualizaciones.



## Tabla task_dta_list()

| task_dta_listt[0] | |  | | 
| :--- | :---: | :---: | ---: |
| NOE [ms] | 42804 | 128054 | 250794 |
| LET [ms] | 2 | 2 | 2 |
| BCET [ms] | 2 | 2 | 2 |
| WCET [ms] | 36 | 37 | 37 |

| task_dta_listt[1] |  | | |
| :--- | :---: | :---: | ---: |
| NOE [ms] | 42804 | 128054 | 250794 |
| LET [ms] | 2 | 2 | 2 |
| BCET [ms] | 2 | 2 | 2 |
| WCET [ms] | 6207 | 6207 | 6207 |










