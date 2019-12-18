;-------------------------------------------------------------------------------
; Прерывание от таймера - начало выдаваемого бита Wiegand
;-------------------------------------------------------------------------------
timer_bit_start_int:
    push ssreg
    in ssreg,SREG
    sei ;>>>>>>>>>>>>>>>>>>>>>>>>>>>> Разрешить вложенные прерывания >>>>>>>>>>>
    rcall sreg_output_proc          ; Выдача во внешний регистр
    out SREG,ssreg
    pop ssreg
    reti

;-------------------------------------------------------------------------------
; Подготовка данных для выдачи (Карта 1 + PIN 1 + [Карта 2 + PIN 2])
;-------------------------------------------------------------------------------
; Z -> структура данных порта
; Флаг T: 0 - одна посылка, 1 - две посылки.
; X -> PIN 1
; Y -> PIN 2 (T = 1)
; Карта 1 копируется из in_code считывателя
; Карта 2 копируется из in_code алкотестера (T = 1)
prepare_output_proc:
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = состояние выхода
    tst tmp1
    brne prepare_output_proc        ; Ожидание завершения отправки данных
    brtc __pop_cp_pin1              ; Если T = 0, игнорировать Карту 2 и PIN 2 
    ; Копирование PIN 2
    ld tmp1,Y+
    ld tmp2,Y+
    ld tmp3,Y+
    ld tmp4,Y+
    std Z+PORT_OUT+OUT_PIN2,tmp1
    std Z+PORT_OUT+OUT_PIN2+1,tmp2
    std Z+PORT_OUT+OUT_PIN2+2,tmp3
    std Z+PORT_OUT+OUT_PIN2+3,tmp4
    ; Карта 2 (Значение от алкотестера)
    ldd tmp1,Z+PORT_AT_IN+IN_CODE   ; Загрузка кода карты
    ldd tmp2,Z+PORT_AT_IN+IN_CODE+1
    ldd tmp3,Z+PORT_AT_IN+IN_CODE+2
    ldd tmp4,Z+PORT_AT_IN+IN_CODE+3
    ldi LOOPL,6
    rcall lsl_32_proc               ; Сдвиг кода на 6 бит влево
    std Z+PORT_OUT+OUT_CODE2,tmp1   ; Сохранение кода карты
    std Z+PORT_OUT+OUT_CODE2+1,tmp2
    std Z+PORT_OUT+OUT_CODE2+2,tmp3
    std Z+PORT_OUT+OUT_CODE2+3,tmp4
__pop_cp_pin1:
    ; Копирование PIN 1
    ld tmp1,X+
    ld tmp2,X+
    ld tmp3,X+
    ld tmp4,X+
    std Z+PORT_OUT+OUT_PIN,tmp1
    std Z+PORT_OUT+OUT_PIN+1,tmp2
    std Z+PORT_OUT+OUT_PIN+2,tmp3
    std Z+PORT_OUT+OUT_PIN+3,tmp4
    ; Карта 1
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE ; Загрузка кода карты
    ldd tmp2,Z+PORT_CARD_IN+IN_CODE+1
    ldd tmp3,Z+PORT_CARD_IN+IN_CODE+2
    ldd tmp4,Z+PORT_CARD_IN+IN_CODE+3
    ldi LOOPL,6
    rcall lsl_32_proc               ; Сдвиг кода на 6 бит влево
    std Z+PORT_OUT+OUT_DATA,tmp1    ; Сохранение кода карты
    std Z+PORT_OUT+OUT_DATA+1,tmp2
    std Z+PORT_OUT+OUT_DATA+2,tmp3
    std Z+PORT_OUT+OUT_DATA+3,tmp4
    sbis GPIOR2,PB_ALGORITHM_2
    rjmp __pop_clear_card           ; Если алгоритм 1 - всегда "забывать" карту
    cpi XL,LOW(pin_vip + 4)         ; Если алгоритм 2 - проверить PIN1 == VIP ?
    breq __pop_save_card            ; Сохранить карту, если да
__pop_clear_card:
    rcall clear_card_proc           ; "Обнуление" кода карты от считывателя
__pop_save_card:
    sbis GPIOR2,PB_NO_CARD          ; Оставить считыватель выключенным!
    std Z+PORT_CARD_IN+IN_CNTR,zero ; Включение входа считывателя
    rcall out_queue_add_proc        ; Добавление данных в очередь на выдачу
    ; Запуск выдачи
    ldi tmp1,W_BIT_COUNT            ; \
    std Z+PORT_OUT+OUT_CNTR,tmp1    ;  > Инициализация счётчика битов
    std Z+PORT_OUT+OUT_CNTR+1,zero  ; /
    ldi tmp1,OS_CODE                ; Код состояния конечного автомата
    bld tmp1,OS_TX2                 ; Добавить бит второй посылки
    std Z+PORT_OUT+OUT_STATE,tmp1
    ret

;-------------------------------------------------------------------------------
; Процедура конечного автомата выхода
;-------------------------------------------------------------------------------
; Z -> структура данных порта
; Сохранять все регистры, т.к. вызывается из прерывания
output_proc:
    push tmp1
    push tmp2
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = состояние
    tst tmp1
    brne __op_active
    rjmp __op_exit                  ; Выход, если выдача неактивна
;-------------------------------------------------------------------------------
__op_active:
    sbrs tmp1,0                     ; Выдача битов в нечётных состояниях
    rjmp __op_dec_cnt
    ldd tmp1,Z+PORT_OUT+OUT_DATA    ; \
    lsl tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA,tmp1    ; |
    ldd tmp1,Z+PORT_OUT+OUT_DATA+1  ; |
    rol tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA+1,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_DATA+2  ;  > Сдвиг данных на 1 бит влево
    rol tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA+2,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_DATA+3  ; |
    rol tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA+3,tmp1  ; /
    brcs __op_bit1                  ; Выдвинутый бит в флаге C
__op_bit0:
    ldd tmp1,Z+PORT_B_OUT_D0        ; Бит D0
    rjmp __op_set_bit
__op_bit1:
    ldd tmp1,Z+PORT_B_OUT_D1        ; Бит D1
__op_set_bit:
    or outputs,tmp1                 ; Установить нужный бит
__op_dec_cnt:                       ; Декремент счётчика
    ldd tmp1,Z+PORT_OUT+OUT_CNTR    ; tmp2:tmp1 = счётчик
    ldd tmp2,Z+PORT_OUT+OUT_CNTR+1
    subi tmp1,1
    sbc tmp2,zero
    std Z+PORT_OUT+OUT_CNTR,tmp1
    std Z+PORT_OUT+OUT_CNTR+1,tmp2
    breq __op_next_st
    rjmp __op_exit                  ; Выход, если счётчик != 0
;-------------------------------------------------------------------------------
__op_next_st:
    ldd tmp1,Z+PORT_OUT+OUT_STATE
    inc tmp1                        ; Переход к следующему состоянию
    std Z+PORT_OUT+OUT_STATE,tmp1
    mov tmp2,tmp1
    andi tmp2,OS_STATE_MASK         ; Выделить код состояния
    cpi tmp2,OS_DELAY1
    breq __op_delay1
    cpi tmp2,OS_DIGIT
    breq __op_digit
    cpi tmp2,OS_DELAY2
    breq __op_delay2
    cpi tmp2,OS_ENTER
    breq __op_enter
    cpi tmp2,OS_DELAY34
    brne __op_end
    rjmp __op_delay3_4
;-------------------------------------------------------------------------------
__op_end:
    sbrs tmp1,OS_TX2                ; Проверить бит OS_TX2
    rjmp __op_quit                  ; Выход, если OS_TX2 == 0
    ldd tmp1,Z+PORT_OUT+OUT_PIN2    ; \
    std Z+PORT_OUT+OUT_PIN,tmp1     ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN2+1  ; |
    std Z+PORT_OUT+OUT_PIN+1,tmp1   ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN2+2  ;  > Копирование PIN 2
    std Z+PORT_OUT+OUT_PIN+2,tmp1   ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN2+3  ; |
    std Z+PORT_OUT+OUT_PIN+3,tmp1   ; /
    ldd tmp1,Z+PORT_OUT+OUT_CODE2   ; \
    std Z+PORT_OUT+OUT_DATA,tmp1    ; |
    ldd tmp1,Z+PORT_OUT+OUT_CODE2+1 ; |
    std Z+PORT_OUT+OUT_DATA+1,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_CODE2+2 ;  > Копирование кода карты 2
    std Z+PORT_OUT+OUT_DATA+2,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_CODE2+3 ; |
    std Z+PORT_OUT+OUT_DATA+3,tmp1  ; /
    ldi tmp1,OS_CODE                ; OS_TX2 = 0
    std Z+PORT_OUT+OUT_STATE,tmp1   ; Повторный запуск выдачи кода карты
    ldi tmp1,W_BIT_COUNT            ; Счётчик битов для кода карты
    clr tmp2
    rjmp __op_st_cnt
;-------------------------------------------------------------------------------
__op_quit:
    std Z+PORT_OUT+OUT_STATE,zero   ; Завершение выдачи
    rjmp __op_exit
;-------------------------------------------------------------------------------
__op_delay1:
    ldd tmp2,Z+PORT_OUT+OUT_PIN     ; Код первой цифры PIN-кода
    tst tmp2                        ; Если 0, то PIN-код выключен
    breq __op_no_pin
    lds tmp1,delay1                 ; Пауза после кода карты
    clr tmp2
    rjmp __op_st_cnt                ; Сохранить счетчик и выйти
;-------------------------------------------------------------------------------
__op_no_pin:                        ; tmp1 = состояние
    subi tmp1,(OS_DELAY1-OS_DELAY34); Перейти к паузе после ENTER
    std Z+PORT_OUT+OUT_STATE,tmp1
    rjmp __op_delay3_4
;-------------------------------------------------------------------------------
__op_digit:
    ldd tmp1,Z+PORT_OUT+OUT_PIN     ; Код цифры
    std Z+PORT_OUT+OUT_DATA+3,tmp1  ; в старший байт данных выдачи
    ldd tmp1,Z+PORT_OUT+OUT_PIN+1   ; \
    std Z+PORT_OUT+OUT_PIN,tmp1     ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN+2   ; |
    std Z+PORT_OUT+OUT_PIN+1,tmp1   ;  > Сдвиг PIN на 1 байт влево
    ldd tmp1,Z+PORT_OUT+OUT_PIN+3   ; |
    std Z+PORT_OUT+OUT_PIN+2,tmp1   ; |
    std Z+PORT_OUT+OUT_PIN+3,zero   ; /
    rjmp __op_st_key_len
;-------------------------------------------------------------------------------
__op_delay2:
    lds tmp1,delay2                 ; Пауза после цифры
    clr tmp2
    rjmp __op_st_cnt
;-------------------------------------------------------------------------------
__op_enter:
    ldd tmp2,Z+PORT_OUT+OUT_PIN     ; Проверить, есть ли ещё цифры на выдачу
    tst tmp2
    breq __op_pin_end
    subi tmp1,(OS_ENTER-OS_DIGIT)   ; Перейти к выдаче следующей цифры
    std Z+PORT_OUT+OUT_STATE,tmp1
    rjmp __op_digit
;-------------------------------------------------------------------------------
__op_pin_end:
    std Z+PORT_OUT+OUT_DATA+3,enter ; Символ ENTER в старший байт выдачи данных
__op_st_key_len:
    lds tmp1,key_length             ; Количество бит в символах цифр и ENTER
    clr tmp2
    rjmp __op_st_cnt
;-------------------------------------------------------------------------------
__op_delay3_4:                      ; tmp1 = состояние
    sbrs tmp1,OS_TX2                ; Проверить бит второй посылки
    rjmp __op_delay4
    lds tmp1,delay3                 ; Пауза между посылками
    lds tmp2,(delay3+1)
    rjmp __op_st_cnt
__op_delay4:
    lds tmp1,delay4                 ; Пауза после отправки ENTER
    lds tmp2,(delay4+1)
__op_st_cnt:
    std Z+PORT_OUT+OUT_CNTR,tmp1
    std Z+PORT_OUT+OUT_CNTR+1,tmp2
__op_exit:
    pop tmp2
    pop tmp1
    ret

;-------------------------------------------------------------------------------
; Выдача во внешний регистр
;-------------------------------------------------------------------------------
; outputs = значение для выдачи
; sregdata = текущее значение во внешнем регистре
sreg_output_proc:                   ; Время выполнения 80 тактов = 20 мкс
    cp outputs,sregdata             ; Если нет изменений,
    breq __sop_ret                  ; то выход из процедуры
    mov sregdata,outputs
    sbrc sregdata,7
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbrc sregdata,6
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbrc sregdata,5
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbrc sregdata,4
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbrc sregdata,3
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbrc sregdata,2
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbrc sregdata,1
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbrc sregdata,0
    sbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_CLK
    cbi SREG_PORT,SREG_BIT_DATA
    sbi SREG_PORT,SREG_BIT_CP
    cbi SREG_PORT,SREG_BIT_CP
__sop_ret:
    ret
