;-------------------------------------------------------------------------------
; Процедура управления реле
;-------------------------------------------------------------------------------
; Z -> структура данных порта
; LOOPH = параметр - время включения реле (1-126 с),
;                  - 0, если выключить реле,
;                  - 127, если включение до сброса.
relay_control_proc:
    andi LOOPH,0x7F                 ; Сбросить старший бит параметра
    breq relay_off                  ; Выключить реле, если 0
    cpi LOOPH,0x7F                  ; Сравнить с 127
    brlo relay_on                   ; Включить реле на 1 - 126 с.
    clr LOOPL
    clr LOOPH
    rjmp relay_inf_on               ; Включить реле до сброса
relay_off:
    ldd LOOPH,Z+PORT_B_RELAY        ; LOOPH = бит реле
    com LOOPH
    and outputs,LOOPH               ; Выключить реле
    ret

;-------------------------------------------------------------------------------
; Процедура включения реле
;-------------------------------------------------------------------------------
; Z -> структура данных порта
; Сохранить tmp3, tmp4
relay_on_proc:
    lds LOOPH,relay1_time
    cpi ZL,LOW(port1)
    breq __ronp_set_time
    lds LOOPH,relay2_time
__ronp_set_time:
    tst LOOPH                       ; Если время = 0,
    breq __ronp_ret                 ; то не включать реле
relay_on:
    rcall mul_500_proc              ; Умножить на 500
relay_inf_on:
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< Прерывания запрещены <<<<<<<<<<<<<<<<<<<<<
    std Z+PORT_RELAY_TCNTR,LOOPL    ; Инициализация счетчика
    std Z+PORT_RELAY_TCNTR+1,LOOPH
    ldd LOOPL,Z+PORT_B_RELAY        ; LOOPL = бит реле
    or outputs,LOOPL                ; Установить бит реле
__ronp_ret:
    reti ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

;-------------------------------------------------------------------------------
; Процедура выключения реле
;-------------------------------------------------------------------------------
; Z -> структура данных порта
; Сохранять регистры, т.к. вызывается из прерывания
relay_off_proc:
    push LOOPL
    push LOOPH
    ldd LOOPH,Z+PORT_B_RELAY        ; LOOPH = бит реле
    mov LOOPL,outputs
    and LOOPL,LOOPH                 ; Проверить, включено реле или нет
    breq __rofp_exit                ; Выход, если выключено
    ldd LOOPL,Z+PORT_RELAY_TCNTR
    ldd LOOPH,Z+PORT_RELAY_TCNTR+1
    sbiw LOOPH:LOOPL,0              ; Проверка LOOP на ноль
    breq __rofp_exit                ; Выход, если 0 (включение реле до сброса)
    sbiw LOOPH:LOOPL,1              ; Декремент счётчика
    std Z+PORT_RELAY_TCNTR,LOOPL
    std Z+PORT_RELAY_TCNTR+1,LOOPH
    brne __rofp_exit
    ldd LOOPH,Z+PORT_B_RELAY
    eor outputs,LOOPH               ; Выключить реле
__rofp_exit:
    pop LOOPH
    pop LOOPL
    ret
