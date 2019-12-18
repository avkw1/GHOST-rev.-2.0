;-------------------------------------------------------------------------------
; Процедура управления светодиодом
;-------------------------------------------------------------------------------
; Z -> структура данных порта
; Вызывается из прерывания
led_proc:
    push tmp1
    push tmp2
    ldd tmp2,Z+PORT_B_LED           ; tmp1 = бит светодиода
    ldd tmp1,Z+PORT_OUT+OUT_STATE
    andi tmp1,OS_STATE_MASK         ; Выделить код состояния
    breq __lp_timer_chk             ; Переход, если выдача неактивна
    cpi tmp1,OS_DELAY34
    brlo __lp_on                    ; Включить, если CODE, D1, DIGIT, D2, ENTER
    rjmp __lp_off                   ; Выключить во время паузы D3 и D4
__lp_timer_chk:
    ldd tmp1,Z+PORT_AT_TIMER_ON     ; tmp1 = таймер включён или нет
    tst tmp1                        ; Если включён -> мигание
    breq __lp_heartbeat             ; Если выключен -> сердцебиение
;-------------------------------------------------------------------------------
; Мигание
__lp_mig:
    sbrc ledst,0                    ; \
    rjmp __lp_exit                  ;  > Если ledst кратно 4 (каждые 200 мс)
    sbrs ledst,1                    ; /
    eor outputs,tmp2                ; Инверсия бита светодиода
    rjmp __lp_exit
;-------------------------------------------------------------------------------
; "Сердцебиение" - 50 мс каждые 3 с
__lp_heartbeat:
    tst ledst
    breq __lp_off
    cpi ledst,(LEDST_MAX-1)
    brne __lp_exit
__lp_on:
    com tmp2
    and outputs,tmp2                ; Включение нулём
    rjmp __lp_exit
__lp_off:
    or outputs,tmp2                 ; Выключение единицей
__lp_exit:
    pop tmp2
    pop tmp1
    ret
