.dseg

ram_data_start:
;---------- Порт 1 -------------------------------------------------------------
port1:
; Вход 1 - считыватель
in1data:        .BYTE 4             ; Принятые биты (wiegand-26)
in1cntr:        .BYTE 1             ; Счётчик битов (0xFF = вход выключен)
in1tcntr:       .BYTE 1             ; Счётчик времени до следующего бита
in1code:        .BYTE 4             ; Полученный код карты
in1bit:         .BYTE 1             ; Бит, устанавливаемый в регистре incodes
; Вход 2 - алкотестер
in2data:        .BYTE 4
in2cntr:        .BYTE 1
in2tcntr:       .BYTE 1
in2code:        .BYTE 4
in2bit:         .BYTE 1
; Выход 1
out1state:      .BYTE 1             ; Состояние выхода
out1cntr:       .BYTE 2             ; Счётчик битов/Счётчик паузы
out1data:       .BYTE 4             ; Данные для выдачи/Код карты 1
out1pin:        .BYTE 4             ; PIN 1
out1code2:      .BYTE 4             ; Код карты 2
out1pin2:       .BYTE 4             ; PIN 2
; Реле и алкотестер
relay1tcntr:    .BYTE 2             ; Счётчик времени реле 1
at1state:       .BYTE 1             ; Состояние алкотестера 1
at1timer_on:    .BYTE 1             ; Включён таймер алкотестера 1
at1tcntr:       .BYTE 3             ; Счётчик тайм-аута алкотестера 1
; Биты
b_out1d0:       .BYTE 1
b_out1d1:       .BYTE 1
b_relay1:       .BYTE 1
b_led1:         .BYTE 1

;---------- Порт 2 -------------------------------------------------------------
port2:
; Вход 3 - считыватель
in3data:        .BYTE 4
in3cntr:        .BYTE 1
in3tcntr:       .BYTE 1
in3code:        .BYTE 4
in3bit:         .BYTE 1
; Вход 4 - алкотестер
in4data:        .BYTE 4
in4cntr:        .BYTE 1
in4tcntr:       .BYTE 1
in4code:        .BYTE 4
in4bit:         .BYTE 1
; Выход 2
out2state:      .BYTE 1
out2cntr:       .BYTE 2
out2data:       .BYTE 4
out2pin:        .BYTE 4
out2code2:      .BYTE 4
out2pin2:       .BYTE 4
; Реле и алкотестер
relay2tcntr:    .BYTE 2
at2state:       .BYTE 1
at2timer_on:    .BYTE 1
at2tcntr:       .BYTE 3
; Биты
b_out2d0:       .BYTE 1
b_out2d1:       .BYTE 1
b_relay2:       .BYTE 1
b_led2:         .BYTE 1

;-------------------------------------------------------------------------------
ram_data_end:
ram_cfg_start:
;---------- Конфигурация из EEPROM ---------------------------------------------
itest_time:     .BYTE 1
ctest_time:     .BYTE 1
test_card:      .BYTE 4
null_card:      .BYTE 4
pin_pass:       .BYTE 4
pin_fail:       .BYTE 4
pin_vip:        .BYTE 4
pin_data:       .BYTE 4
v_facility:     .BYTE 1
v_offset:       .BYTE 2
c_facility:     .BYTE 1
c_offset:       .BYTE 2
delay1:         .BYTE 1
delay2:         .BYTE 1
delay3:         .BYTE 2
relay1_time:    .BYTE 1
relay2_time:    .BYTE 1
as_timeout:     .BYTE 1
er_timeout:     .BYTE 1
event_mask:     .BYTE 1
address:        .BYTE 1
param_bits:     .BYTE 1
card_length:    .BYTE 1
key_length:     .BYTE 1
event_mask2:    .BYTE 1
card_time:      .BYTE 1
delay4:         .BYTE 2
;-------------------------------------------------------------------------------
ram_cfg_end:

;---------- Буферы (не инициализируются) ---------------------------------------
usart_buffer:   .BYTE USART_BUFFER_SIZE
out_queue:      .BYTE QUEUE_SIZE
;-------------------------------------------------------------------------------

; Размер данных в ОЗУ (переменные)
.equ RAM_DATA_SIZE      = ram_data_end-ram_data_start

; Смещения данных структуры входа
.equ IN_DATA            = in1data-port1
.equ IN_CNTR            = in1cntr-port1
.equ IN_TCNTR           = in1tcntr-port1
.equ IN_CODE            = in1code-port1
.equ IN_BIT             = in1bit-port1

; Смещения данных структуры выхода
.equ OUT_STATE          = 0
.equ OUT_CNTR           = out1cntr-out1state
.equ OUT_DATA           = out1data-out1state
.equ OUT_PIN            = out1pin-out1state
.equ OUT_CODE2          = out1code2-out1state
.equ OUT_PIN2           = out1pin2-out1state

; Смещения данных структуры порта
.equ PORT_CARD_IN       = in1data-port1
.equ PORT_AT_IN         = in2data-port1
.equ PORT_OUT           = out1state-port1
.equ PORT_RELAY_TCNTR   = relay1tcntr-port1
.equ PORT_AT_STATE      = at1state-port1
.equ PORT_AT_TIMER_ON   = at1timer_on-port1
.equ PORT_AT_TCNTR      = at1tcntr-port1
.equ PORT_B_OUT_D0      = b_out1d0-port1
.equ PORT_B_OUT_D1      = b_out1d1-port1
.equ PORT_B_RELAY       = b_relay1-port1
.equ PORT_B_LED         = b_led1-port1

; Размер структуры порта
.equ PORT_STRUCT_SIZE   = port2-port1
