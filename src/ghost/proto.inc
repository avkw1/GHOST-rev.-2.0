;-------------------------------------------------------------------------------
; Протокол обмена по RS-485
;-------------------------------------------------------------------------------

; Максимальная длина очереди выдачи RS-485
.equ QUEUE_MAX_LENGTH   = 7
; Размер данных в очереди
.equ QUEUE_DATA_SIZE    = 7
; Размер элемента очереди
.equ QUEUE_ELEM_SIZE    = QUEUE_DATA_SIZE + 1
; Размер очереди в байтах
.equ QUEUE_SIZE         = QUEUE_MAX_LENGTH * QUEUE_ELEM_SIZE

; Полином для вычисления CRC16
.equ CRC16_POLY         = 0xA001
; Минимальная длина команды (все кроме RELAY)
.equ MIN_CMD_LENGTH     = 3
; Максимальная длина команды (только RELAY)
.equ MAX_CMD_LENGTH     = 4
; Длина ответа на команду QUERY
.equ ANSWER_LENGTH      = QUEUE_ELEM_SIZE + 2
; Размер буфера USART
.equ USART_BUFFER_SIZE  = ANSWER_LENGTH

; Маска адреса
.equ ADDR_MASK          = 0x1F
; Маска кода команды
.equ CMD_MASK           = 0xE0

; Коды команд
.equ CC_PING            = 0x00  ; \
.equ CC_BOOTLOADER      = 0x20  ;  \
.equ CC_RESET           = 0x40  ;   > Длина 3 байта
.equ CC_QUERY           = 0x60  ;  /
.equ CC_QACK            = 0x80  ; /
.equ CC_RELAY           = 0xA0  ; Длина 4 байта


; Код короткого ответа (без данных)
.equ ANSWER_OK          = 0xA0

; Биты в ответе на команду QUERY
.equ QA_DATA_BIT        = 0     ; Бит наличия данных
.equ QA_TX2_BIT         = 1     ; Бит второй посылки
.equ QA_PORT_BIT        = 2     ; Бит номера порта
.equ QA_LOSS_BIT        = 3     ; Бит потери данных
