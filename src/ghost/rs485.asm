;-------------------------------------------------------------------------------
; Прерывание USART Receive Complete
;-------------------------------------------------------------------------------
rxc_int:
    push ssreg
    in ssreg,SREG
    push tmp1
    in tmp1,UDR                     ; tmp1 = принятый байт
    sbis UCSRA,MPCM                 ; Если MPCM выключен, проверить адрес
    rjmp __ri_data_rx               ; Иначе переход к приёму данных
    ; Проверка адреса прибора
    push tmp1
    andi tmp1,ADDR_MASK
    cpi tmp1,ADDR_MASK              ; Широковещательный адрес?
    breq __ri_broadcast
    cp tmp1,r_address
__ri_broadcast:
    pop tmp1
    brne __ri_exit_int              ; Выход из прерывания, если другой адрес
    cbi UCSRA,MPCM                  ; Выключить MPCM
    ; Приём данных в буфер
__ri_data_rx:
    push XL
    push XH
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    add XL,usart_cntr
    adc XH,zero
    st X+,tmp1                      ; Сохранить байт в буфер порта
    ; Проверка смещения кода команды
    tst usart_cntr                  ; usart_cntr == 0 ?
    brne __ri_check_len
    ; Проверка кода команды
    andi tmp1,CMD_MASK
    cpi tmp1,CC_RELAY
    brlo __ri_check_len
    brne __ri_invalid_data          ; Выход, если некорректный код команды
    inc usart_len                   ; Инкремент длины, если команда CC_RELAY
__ri_check_len:
    ; Проверка длины
    inc usart_cntr
    cp usart_cntr,usart_len
    brlo __ri_exit
    ; Проверка контрольной суммы
    push tmp2
    push tmp3
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    rcall crc16_proc                ; Проверка CRC, сброс счетчика байтов
    or tmp1,tmp2
    pop tmp3
    pop tmp2
    brne __ri_invalid_data          ; Игнорировать, если ошибка CRC
    ; Команда получена
    sbr incodes,(1<<INC_RS485)      ; Назначить обработку команды
    SET_TX                          ; Переключение на передачу
    RXCIE_OFF                       ; Выключить RXC
    TXCIE_ON                        ; Включить TXC
    rjmp __ri_exit
__ri_invalid_data:
    ; Игнорировать некорректные данные
    rcall usart_reset_proc
__ri_exit:
    pop XH
    pop XL
__ri_exit_int:
    pop tmp1
    out SREG,ssreg
    pop ssreg
    reti

;-------------------------------------------------------------------------------
; Прерывание USART Transmit Complete
;-------------------------------------------------------------------------------
txc_int:
    push ssreg
    in ssreg,SREG
    push tmp1
    rcall usart_reset_proc
    rjmp __ri_exit_int

;-------------------------------------------------------------------------------
; Прерывание USART Data Register Empty
;-------------------------------------------------------------------------------
udre_int:
    push ssreg
    in ssreg,SREG
    push tmp1
    push XL
    push XH
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    add XL,usart_cntr
    adc XH,zero
    ld tmp1,X                       ; tmp1 = следующий байт для отправки
    out UDR,tmp1
    inc usart_cntr                  ; Инкремент счётчика байтов
    cp usart_cntr,usart_len
    brlo __ui_exit                  ; Выход, если не последний байт
    UDRIE_OFF                       ; Выключить UDRE (это прерывание)
    TXCIE_ON                        ; Включить TXC
__ui_exit:
    pop XH
    pop XL
    rjmp __ri_exit_int

;-------------------------------------------------------------------------------
; Процедура сброса USART (возврат к начальному состоянию)
;-------------------------------------------------------------------------------
usart_reset_proc:
    clr usart_cntr                  ; usart_cntr = 0
    ldi tmp1,MIN_CMD_LENGTH
    mov usart_len,tmp1              ; usart_len = MIN_CMD_LENGTH
    ldi tmp1,(1<<RXCIE)|(1<<RXEN)|(1<<TXEN)|(1<<UCSZ2)
    out UCSRB,tmp1                  ; Включить RXC, выключить TXC
    sbi UCSRA,MPCM                  ; Включить MPCM
    SET_RX                          ; Переключиться на приём
    ret

;-------------------------------------------------------------------------------
; Процедура вычисления CRC16
;-------------------------------------------------------------------------------
; вход: Данные находятся в X -> usart_buffer
;       usart_cntr - количество байтов
; выход: tmp2:tmp1 - контрольная сумма
crc16_proc:
    ser tmp1                        ; Начальное значение 0xFFFF
    ser tmp2

__c16_byte_lp:
    ld tmp3,X+                      ; Загрузка очередного байта
    eor tmp1,tmp3                   ; CRC ^= байт
    ldi tmp3,8                      ; Счётчик битов

__c16_bit_lp:
    lsr tmp2                        ; Сдвиг 16-битной CRC
    ror tmp1
    brcc __c16_next_bit             ; Выдвинутый бит равен 0?
    eor tmp1,polyl
    eor tmp2,polyh

__c16_next_bit:
    dec tmp3                        ; Счётчик битов
    brne __c16_bit_lp

    dec usart_cntr                  ; Счётчик байтов
    brne __c16_byte_lp
    ret

