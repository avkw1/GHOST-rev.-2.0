;-------------------------------------------------------------------------------
; Инициализация порта
;-------------------------------------------------------------------------------
; Z -> структура данных порта
port_init_proc:
    ldi tmp1,AT_POWER_OFF           ; Начальное состояние алкотестера - выключен
    std Z+PORT_AT_STATE,tmp1
    sbis GPIOR2,PB_NO_CARD          ; Если выключена отправка кодов карт
    rjmp clear_card_proc            ; PB_NO_CARD = 0, обычная инициализация
    ldi tmp1,W_IN_DISABLED
    std Z+PORT_CARD_IN+IN_CNTR,tmp1 ; Выключить вход считывателя!
    sts null_card,tmp1              ; Включить работу без карты (null_card != 0)
    rjmp clear_card_proc            ; PB_NO_CARD = 1, загрузка null_card != 0

;-------------------------------------------------------------------------------
; Обработка полученного кода карты
;-------------------------------------------------------------------------------
; Z -> структура данных порта
card_code_proc:
    ; Сравнение с тестовой картой
    ldi XL,LOW(test_card)
    ldi XH,HIGH(test_card)
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE
    ld tmp2,X+
    cp tmp1,tmp2
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+1
    ld tmp2,X+
    cpc tmp1,tmp2
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+2
    ld tmp2,X+
    cpc tmp1,tmp2
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+3
    ld tmp2,X+
    cpc tmp1,tmp2
    brne __ccp_no_test
    ; Запуск теста по карте
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< Запрет прерываний <<<<<<<<<<<<<<<<<<<<<<<<
    ldi tmp1,LOW(RAMEND)            ; Инициализация стека
    out SPL,tmp1
    ldi tmp1,HIGH(RAMEND)
    out SPH,tmp1
    lds LOOPH,ctest_time            ; LOOPH = время теста по карте
    rjmp test                       ; Переход к тесту
;-------------------------------------------------------------------------------
__ccp_no_test:
    ldd tmp1,Z+PORT_AT_STATE        ; tmp1 = состояние алкотестера
    sbic GPIOR2,PB_ALGORITHM_2
    rjmp __ccp_alg_2                ; Переход, если включен алгоритм 2
    cpi tmp1,AT_ANALYSIS            ; Если анализ
    breq __ccp_analysis
    cpi tmp1,AT_PASS                ; Если норма
    breq __ccp_ret
    cpi tmp1,AT_FAIL                ; Если алкоголь
    breq __ccp_ret
__ccp_send_vip:
    ldi XL,LOW(pin_vip)             ; PIN 1 -> VIP
    ldi XH,HIGH(pin_vip)
    clt                             ; T = 0 (Не отправлять 2-ю пару!)
    rjmp prepare_output_proc        ; Отправка
;-------------------------------------------------------------------------------
__ccp_alg_2:
    cpi tmp1,AT_READY               ; Если не "Готов", 
    brne __ccp_send_vip             ; пропустить запуск таймера
    lds LOOPH,card_time             ; LOOPH = время тайм-аута карты
    rcall at_timer_start_x1_proc    ; Запуск таймера, если состояние "Готов"
    rjmp __ccp_send_vip             ; Отправить код карты как VIP
;-------------------------------------------------------------------------------
__ccp_analysis:
    ldi tmp1,W_IN_DISABLED
    sbic GPIOR2,PB_SINGLE_CARD      ; Если PB_SINGLE_CARD = 1, 
    std Z+PORT_CARD_IN+IN_CNTR,tmp1 ; выключить вход считывателя
__ccp_ret:
    ret                             ; Возврат из процедуры

;-------------------------------------------------------------------------------
; Обработка данных от алкотестера
;-------------------------------------------------------------------------------
; Z -> структура данных порта
alcotester_code_proc:
    ldd tmp1,Z+PORT_AT_IN+IN_CODE   ; Загрузка полученного кода
    ldd tmp2,Z+PORT_AT_IN+IN_CODE+1
    ldd tmp3,Z+PORT_AT_IN+IN_CODE+2
    ldd tmp4,Z+PORT_AT_IN+IN_CODE+3
    lsr tmp4                        ; Сдвиг на 1 бит вправо
    ror tmp3
    ror tmp2
    ror tmp1
    eor tmp1,tmp3
    eor tmp2,tmp3
    movw tmp4:tmp3,tmp2:tmp1        ; tmp4:tmp3 = код:цифра1:цифра2:цифра3
    swap tmp2
    andi tmp2,0x0F                  ; tmp2 = код состояния
    std Z+PORT_AT_STATE,tmp2        ; Сохранить новое состояние алкотестера
    std Z+PORT_AT_TIMER_ON,zero     ; Остановить отсчёт времени!
    ; Выбор действия по коду состояния
    cpi tmp2,AT_POWER_ON            ; Включение
    brne __acp_2
    sbis GPIOR0,EM_POWER_ON         ; Проверить, разрешена ли выдача события
    ret                             ; Выход, если нет
    rjmp __acp_state                ; Выдача только кода состояния
;-------------------------------------------------------------------------------
__acp_2:
    cpi tmp2,AT_POWER_OFF           ; Выключение кнопкой
    brne __acp_3
    sbis GPIOR0,EM_POWER_OFF
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_3:
    cpi tmp2,AT_AUTO_POWER_OFF      ; Автоматическое выключение
    brne __acp_4
    sbis GPIOR0,EM_AUTO_POWER_OFF
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_4:
    cpi tmp2,AT_READY               ; Готов
    brne __acp_5
    sbis GPIOR1,EM2_READY
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_5:
    cpi tmp2,AT_ERROR               ; Ошибка (недостаточный выдох)
    brne __acp_6
    lds tmp1,er_timeout             ; tmp1 = тайм-аут для ошибки
    rcall at_timer_start_x5_proc    ; Запуск отсчёта времени
    sbis GPIOR0,EM_ERROR
    ret
    ldi tmp2,AT_ERROR               ; Восстановить tmp2!
    rjmp __acp_state                ; Выдача кода состояния
;-------------------------------------------------------------------------------
__acp_6:
    cpi tmp2,AT_ANALYSIS            ; Анализ
    brne __acp_7
    lds tmp1,as_timeout             ; tmp1 = тайм-аут для анализа
    rcall at_timer_start_x5_proc    ; Запуск отсчёта времени
    sbic GPIOR2,PB_ALGORITHM_2      ; Если алгоритм 2,
    rjmp __acp_6_alg2               ; то переход
    sbis GPIOR1,EM2_ANALYSIS
    ret
    ldi tmp2,AT_ANALYSIS            ; Восстановить tmp2
    rjmp __acp_state                ; Выдача кода состояния

__acp_6_alg2:
    ldi tmp1,W_IN_DISABLED          ; Для алгоритма 2
    std Z+PORT_CARD_IN+IN_CNTR,tmp1 ; Выключить вход считывателя
    ret                             ; Выход (бит EM2_ANALYSIS игнорируется)
;-------------------------------------------------------------------------------
__acp_7:
    cpi tmp2,AT_PASS                ; Норма
    set                             ; T = 1
    brne __acp_8
    ldi XL,LOW(pin_pass)            ; PIN 1 -> pin_pass
    ldi XH,HIGH(pin_pass)
    sbis GPIOR0,EM_PASS             ; Бит разрешения выдачи показаний "Норма"
    clt                             ; Не отправлять 2-ю пару, если бит = 0
    rjmp __acp_8_pin2_data
;-------------------------------------------------------------------------------
__acp_8:
    cpi tmp2,AT_FAIL                ; Алкоголь
    brne __acp_9
    rcall relay_on_proc             ; Включить реле!
    ldi XL,LOW(pin_fail)            ; PIN 1 -> pin_fail
    ldi XH,HIGH(pin_fail)
    sbis GPIOR0,EM_FAIL             ; Бит разрешения выдачи показаний "Алкоголь"
    clt                             ; Не отправлять 2-ю пару, если бит = 0
__acp_8_pin2_data:
    ldi YL,LOW(pin_data)            ; PIN 2 -> pin_data
    ldi YH,HIGH(pin_data)
    rjmp __acp_card_value
;-------------------------------------------------------------------------------
__acp_9:
    cpi tmp2,AT_STANDBY_MODE        ; Режим ожидания
    brne __acp_10
    sbis GPIOR0,EM_STANDBY_MODE
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_10:
    cpi tmp2,AT_BREAKDOWN           ; Неисправность
    brne __acp_11
    sbis GPIOR0,EM_BREAKDOWN
__acp_ret:
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_11:
    cpi tmp2,AT_TIMEOUT             ; Тайм-аут
    brne __acp_ret
    ldi tmp1,AT_READY
    std Z+PORT_AT_STATE,tmp1        ; Заменить на код "Готов"
    ; ... и выдать код "Тайм-аут"
;-------------------------------------------------------------------------------
; Выдача только кода состояния алкотестера
; tmp2 = код состояния
__acp_state:
    rcall code_to_card_proc         ; Преобразование кода состояния в код карты
    ldi XL,LOW(pin_data)            ; PIN 1 -> pin_data
    ldi XH,HIGH(pin_data)
    clt                             ; T = 0 (Не отправлять 2-ю пару!)
    rjmp prepare_output_proc        ; Отправка

;-------------------------------------------------------------------------------
; Выдача кода карты и значения
; tmp4:tmp3 = код:цифра1:цифра2:цифра3
; X -> PIN 1, Y -> PIN 2
; T: 0 - не отправлять значение, 1 - отправлять значение
__acp_card_value:
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE ; Проверка на код карты 0
    cp tmp1,zero
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+1
    cpc tmp1,zero
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+2
    cpc tmp1,zero
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+3
    cpc tmp1,zero                   ; Может быть только если null_card = 0 
    breq __acp_no_output            ; и не получен код карты => выход
    brtc __acp_no_value             ; Если T = 0, то переход
    mov tmp1,tmp4
    andi tmp1,0x0F                  ; tmp1 = старшая цифра
    mov tmp2,tmp3
    swap tmp2
    andi tmp2,0x0F                  ; tmp2 = вторая цифра
    andi tmp3,0x0F                  ; tmp3 = третья цифра
    push XL
    push XH
    movw XH:XL,ZH:ZL
    adiw XH:XL,PORT_AT_IN+IN_CODE
    sbis GPIOR2,PB_NO_CARD          ; Если выключена отправка кодов карт
    sbic GPIOR2,PB_VALUE_ONLY       ; или код карты не повторяется (алгоритм 2)
    sbiw XH:XL,PORT_AT_IN-PORT_CARD_IN  ; Записать на место кода карты
    rcall value_to_card_proc        ; Преобразование значения в код карты
    set                             ; Восстановить T = 1
    pop XH
    pop XL                          ; X -> PIN 1, Y -> PIN 2
    sbis GPIOR2,PB_NO_CARD          ; Если выключена отправка кодов карт
    sbic GPIOR2,PB_VALUE_ONLY       ; или код карты не повторяется (алгоритм 2)
    rjmp __acp_value_only           ; Отправить только значение от алкотестера
    rjmp prepare_output_proc        ; Отправка (карта + PIN 1, значение + PIN 2)

__acp_value_only:
    movw XH:XL,YH:YL                ; PIN 1 = PIN 2
    clt                             ; Не отправлять 2-ю пару!
    rjmp prepare_output_proc        ; Отправка (значение + PIN 2)

__acp_no_value:
    sbis GPIOR2,PB_NO_CARD          ; Если выключена отправка кодов карт
    sbic GPIOR2,PB_VALUE_ONLY       ; или код карты не повторяется (алгоритм 2)
    rjmp __acp_no_output            ; Выход - нечего отправлять.
    rjmp prepare_output_proc        ; Отправка (карта + PIN 1)

__acp_no_output:
    sbis GPIOR2,PB_NO_CARD          ; Оставить считыватель выключенным!
    std Z+PORT_CARD_IN+IN_CNTR,zero ; Включение входа считывателя
    ret

;-------------------------------------------------------------------------------
; Преобразование кода состояния в код карты
;-------------------------------------------------------------------------------
; tmp2 = код состояния
; Z -> структура данных порта
; Значение карты записывается вместо кода от считывателя. Старшие 6 бит = 0.
code_to_card_proc:
    mov LOOPL,tmp2
    clr LOOPH
    lds tmp1,c_offset               ; Смещение для кода состояния
    lds tmp2,(c_offset+1)
    add tmp1,LOOPL
    adc tmp2,LOOPH
    lds tmp3,c_facility             ; Код организации для кода состояния
    movw XH:XL,ZH:ZL
    adiw XH:XL,PORT_CARD_IN+IN_CODE
    rjmp __vtcp_shift

;-------------------------------------------------------------------------------
; Преобразование значения от алкотестера в код карты
;-------------------------------------------------------------------------------
; tmp1,tmp2,tmp3 = цифры (старшая в tmp1)
; X -> адрес для записи кода карты
; Z -> структура данных порта
value_to_card_proc:
    ; Преобразование цифр в двоичное значение 
    mov LOOPL,tmp1
    clr LOOPH                       ; LOOPH:LOOPL = d1
    add LOOPL,tmp1
    add LOOPL,tmp1                  ; LOOPL = 3 x d1
    lsl LOOPL
    lsl LOOPL
    lsl LOOPL                       ; LOOPL = 24 x d1
    add LOOPL,tmp1                  ; LOOPL = 25 x d1
    lsl LOOPL
    rol LOOPH
    lsl LOOPL
    rol LOOPH                       ; LOOPH:LOOPL = 100 x d1
    mov tmp1,tmp2                   ; tmp1 = d2
    lsl tmp1
    lsl tmp1                        ; tmp1 = 4 x d2
    add tmp1,tmp2                   ; tmp1 = 5 x d2
    lsl tmp1                        ; tmp1 = 10 x d2
    add LOOPL,tmp1
    adc LOOPH,zero                  ; LOOPH:LOOPL = 100 x d1 + 10 x d2
    add LOOPL,tmp3
    adc LOOPH,zero                  ; LOOPH:LOOPL = 100 x d1 + 10 x d2 + d3
    ; Добавление смещения и кода организации
__vtcp_add_offset:
    lds tmp1,v_offset               ; Смещение для значения
    lds tmp2,(v_offset+1)
    add tmp1,LOOPL
    adc tmp2,LOOPH
    lds tmp3,v_facility             ; Код организации для значения
__vtcp_shift:
    clr tmp4                        ; tmp4 = 0
    lsl tmp1                        ; \
    rol tmp2                        ;  \
    rol tmp3                        ;  / Сдвиг на 1 бит влево
    rol tmp4                        ; /
    ; Добавление битов чётности
    clr LOOPL
    sbrc tmp4,0
    inc LOOPL
    sbrc tmp3,7
    inc LOOPL
    sbrc tmp3,6
    inc LOOPL
    sbrc tmp3,5
    inc LOOPL
    sbrc tmp3,4
    inc LOOPL
    sbrc tmp3,3
    inc LOOPL
    sbrc tmp3,2
    inc LOOPL
    sbrc tmp3,1
    inc LOOPL
    sbrc tmp3,0
    inc LOOPL
    sbrc tmp2,7
    inc LOOPL
    sbrc tmp2,6
    inc LOOPL
    sbrc tmp2,5
    inc LOOPL
    bst LOOPL,0
    bld tmp4,1                      ; Сохранение бита нечётности
    ldi LOOPL,1
    sbrc tmp2,4
    inc LOOPL
    sbrc tmp2,3
    inc LOOPL
    sbrc tmp2,2
    inc LOOPL
    sbrc tmp2,1
    inc LOOPL
    sbrc tmp2,0
    inc LOOPL
    sbrc tmp1,7
    inc LOOPL
    sbrc tmp1,6
    inc LOOPL
    sbrc tmp1,5
    inc LOOPL
    sbrc tmp1,4
    inc LOOPL
    sbrc tmp1,3
    inc LOOPL
    sbrc tmp1,2
    inc LOOPL
    sbrc tmp1,1
    inc LOOPL
    bst LOOPL,0
    bld tmp1,0                      ; Сохранение бита чётности
    ; Сохранение сформированного кода карты
    st X+,tmp1
    st X+,tmp2
    st X+,tmp3
    st X+,tmp4
    ret
