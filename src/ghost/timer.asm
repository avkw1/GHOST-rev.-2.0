;-------------------------------------------------------------------------------
; Запуск отсчёта тайм-аута для алкотестера (x1 секунда)
;-------------------------------------------------------------------------------
; LOOPH = тайм-аут (x1 секунда) (0-127), 0 = выкл.
; Z -> структура данных порта
at_timer_start_x1_proc:
    tst LOOPH
    breq __atsp_ret                 ; Выход, если 0
    rcall mul_500_proc              ; Умножить на 500 (результат в LOOPH:LOOPL)
    clr tmp4                        ; Обнулить старший байт
    rjmp __atsp_start

;-------------------------------------------------------------------------------
; Запуск отсчёта тайм-аута для алкотестера (x5 секунд)
;-------------------------------------------------------------------------------
; tmp1 = тайм-аут (x5 секунд) (0-255), 0 = выкл.
; Z -> структура данных порта
at_timer_start_x5_proc:
    tst tmp1
    breq __atsp_ret                 ; Выход, если 0
    ; Умножение значения на 2500
    clr tmp2                        
    clr tmp3
    lsl tmp1
    rol tmp2
    lsl tmp1
    rol tmp2                        ; tmp3:tmp2:tmp1 = t x 4
    movw LOOPH:LOOPL,tmp2:tmp1
    clr tmp4                        ; tmp4:LOOPH:LOOPL = t x 4
    rcall lsl_24_proc
    rcall lsl_24_proc
    rcall lsl_24_proc
    rcall lsl_24_proc
    rcall add_24_proc               ; = t x 4 + t x 64 = t x 68
    rcall lsl_24_proc
    rcall add_24_proc               ; = t x 68 + t x 128 = t x 196
    rcall lsl_24_proc
    rcall add_24_proc               ; = t x 196 + t x 256 = t x 452
    rcall lsl_24_proc
    rcall lsl_24_proc
    rcall lsl_24_proc
    rcall add_24_proc               ; = t x 452 + t x 2048 = t x 2500
__atsp_start:
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< Прерывания запрещены <<<<<<<<<<<<<<<<<<<<<
    std Z+PORT_AT_TCNTR,LOOPL       ; Инициализация счетчика тайм-аута
    std Z+PORT_AT_TCNTR+1,LOOPH
    std Z+PORT_AT_TCNTR+2,tmp4
    ldi tmp1,1
    std Z+PORT_AT_TIMER_ON,tmp1     ; Включить отсчёт тайм-аута
__atsp_ret:
    reti ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

;-------------------------------------------------------------------------------
; Проверка тайм-аута алкотестера
;-------------------------------------------------------------------------------
; Z -> структура данных порта
; Сохранять все регистры, так как вызывается из прерывания
at_timeout_proc:
    push LOOPL
    ldd LOOPL,Z+PORT_AT_TIMER_ON    ; Проверка состояния таймера
    tst LOOPL
    breq __atp_exit                 ; Выход, если отсчёт тайм-аута выключен
__atp_dec_tcntr:
    push LOOPH
    ldd LOOPL,Z+PORT_AT_TCNTR
    ldd LOOPH,Z+PORT_AT_TCNTR+1
    sbiw LOOPH:LOOPL,1              ; Декремент счётчика времени
    std Z+PORT_AT_TCNTR,LOOPL
    std Z+PORT_AT_TCNTR+1,LOOPH
    ldd LOOPL,Z+PORT_AT_TCNTR+2
    sbc LOOPL,zero                  ; Учёт заёма из старшего байта
    std Z+PORT_AT_TCNTR+2,LOOPL
    brne __atp_poph                 ; Выход, если != 0
    ; Время вышло
    std Z+PORT_AT_TIMER_ON,zero     ; Остановить отсчёт времени
    ldd LOOPL,Z+PORT_AT_STATE       ; LOOPL = состояние алкотестера
    cpi LOOPL,AT_READY              ; Если не "Готов",
    brne __atp_breakdown            ; то выдать код неисправности
    ; Сгенерировать код тайм-аута
    ldi LOOPL,LOW(AT_TIMEOUT<<5)
    ldi LOOPH,HIGH(AT_TIMEOUT<<5)
    rjmp __atp_in_code
__atp_breakdown:
    ; Сгенерировать код неисправности
    ldi LOOPL,LOW(AT_BREAKDOWN<<5)
    ldi LOOPH,HIGH(AT_BREAKDOWN<<5)
__atp_in_code:
    std Z+PORT_AT_IN+IN_CODE,zero
    std Z+PORT_AT_IN+IN_CODE+1,LOOPL
    std Z+PORT_AT_IN+IN_CODE+2,LOOPH
    std Z+PORT_AT_IN+IN_CODE+3,zero
    ldd LOOPL,Z+PORT_AT_IN+IN_BIT   ; Бит входа алкотестера
    or incodes,LOOPL                ; Установить бит
    sbis GPIOR2,PB_NO_CARD          ; Оставить считыватель выключенным!
    std Z+PORT_CARD_IN+IN_CNTR,zero ; Включение входа считывателя
__atp_poph:
    pop LOOPH
__atp_exit:
    pop LOOPL
    ret
