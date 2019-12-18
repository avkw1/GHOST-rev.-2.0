;-------------------------------------------------------------------------------
; Обработчик команд протокола обмена по RS-485
;-------------------------------------------------------------------------------
process_cmd_proc:
    lds tmp1,usart_buffer
    andi tmp1,CMD_MASK              ; tmp1 = код команды
    cpi tmp1,CC_QUERY
    breq __pcp_cmd_query
    cpi tmp1,CC_QACK
    breq __pcp_cmd_qack
    out UDR,polyh                   ; Запуск отправки ответа ANSWER_OK
    cpi tmp1,CC_BOOTLOADER
    breq __pcp_cmd_bootloader
    cpi tmp1,CC_RESET
    breq __pcp_cmd_reset
    cpi tmp1,CC_RELAY
    breq __pcp_cmd_relay
    ret

;-------------------------------------------------------------------------------
__pcp_cmd_reset:
__pcp_cmd_bootloader:
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< Прерывания запрещены <<<<<<<<<<<<<<<<<<<<<
    USART_WAIT_TX                   ; Ожидание завершения передачи
    SET_RX                          ; Переключение на приём
    ldi XL,LOW(RAMEND)              ; Инициализация указателя стека
    out SPL,XL
    ldi XL,HIGH(RAMEND)
    out SPH,XL
    sbrs tmp1,5                     ; Пропустить, если код команды CC_BOOTLOADER
    rjmp start                      ; Программный сброс!
    clr outputs
    rcall sreg_output_proc          ; Обнулить внешний регистр
    out UCSRA,zero                  ; Выключить MPCM
    ldi ZL,LOW(BOOTLDR_SFLAG_ADDRESS)
    ldi ZH,HIGH(BOOTLDR_SFLAG_ADDRESS)
    movw r5:r4,ZH:ZL                ; Инициализация адреса флага защиты
    clr r3                          ; Инициализация флага защиты
    rjmp BOOTLDR_JUMP_ADDRESS       ; Переход на метку INIT!

;-------------------------------------------------------------------------------
__pcp_cmd_relay:
    ldi ZL,LOW(port1)
    ldi ZH,HIGH(port1)
    lds LOOPH,(usart_buffer + 1)    ; LOOPH = параметр
    sbrc LOOPH,7                    ; 0 = реле 1, 1 = реле 2
    adiw ZH:ZL,PORT_STRUCT_SIZE
    rjmp relay_control_proc

;-------------------------------------------------------------------------------
__pcp_cmd_query:
    tst out_queue_len               ; Проверить длину очереди
    breq __pcp_q_empty              ; Переход, если очередь пуста
    rcall out_queue_fetch_proc      ; Выборка элемента из очереди
    TXCIE_OFF                       ; Выключить TXC
    out UDR,LOOPH                   ; Запуск отправки ответа!
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    ldi tmp1,(ANSWER_LENGTH-2)      ; tmp1 = длина без CRC
    mov usart_cntr,tmp1
    rcall CRC16_proc                ; Вычисление CRC
    st X+,tmp1
    st X+,tmp2
    ldi tmp1,ANSWER_LENGTH
    mov usart_len,tmp1              ; usart_len = длина фрейма
    mov usart_cntr,polyl            ; usart_cntr = 1
    UDRIE_ON                        ; Включить UDRE
    ret

__pcp_q_empty:
    out UDR,polyh                   ; Запуск отправки ответа ANSWER_OK
    ret

;-------------------------------------------------------------------------------
__pcp_cmd_qack:
    tst out_queue_len               ; Проверить длину очереди
    breq __pcp_q_empty              ; Переход, если очередь пуста
    rcall out_queue_del_proc        ; Удаление элемента из очереди
    mov tmp1,polyh
    or tmp1,out_queue_len
    out UDR,tmp1                    ; Запуск отправки ответа
    ret
