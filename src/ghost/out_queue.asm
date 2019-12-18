;-------------------------------------------------------------------------------
; Процедура добавления данных в очередь на выдачу
;-------------------------------------------------------------------------------
; Z -> структура данных порта [сохранить]
; Флаг T: 0 - одна посылка, 1 - две посылки. [сохранить]
out_queue_add_proc:
    tst r_address                   ; Проверка адреса
    breq __gqp_ret                  ; Выход, если 0 (RS-485 выключен)
    ; Формирование заголовка ответа
    ldi LOOPH,(1<<QA_DATA_BIT)      ; Бит наличия данных
    cpi ZL,LOW(port1)
    breq __oqap_add
    sbr LOOPH,(1<<QA_PORT_BIT)      ; Бит номера порта
__oqap_add:
    brtc __queue_add_proc           ; Добавление только посылки 1
    rcall __queue_add_proc          ; Добавление посылки 1 в очередь
    sbr LOOPH,(1<<QA_TX2_BIT)       ; Бит второй посылки
    rjmp __queue_add_proc           ; Добавление посылки 2 в очередь

;-------------------------------------------------------------------------------
; Процедура выборки элемента из очереди
;-------------------------------------------------------------------------------
; Первый элемент копируется в usart_buffer
; Выход: LOOPH = заголовок ответа
out_queue_fetch_proc:
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    ldi YL,LOW(out_queue)
    ldi YH,HIGH(out_queue)
    ld LOOPH,Y+                     ; LOOPH = заголовок элемента очереди
    mov tmp1,out_queue_len
    swap tmp1                       ; Старшие 4 бита ответа - количество
    or LOOPH,tmp1                   ; ожидающих сообщений в очереди
    st X+,LOOPH                     ; Сохранить заголовок ответа
    ldi LOOPL,QUEUE_DATA_SIZE       ; LOOPL = длина данных элемента
    rjmp memcpy                     ; Копирование памяти

;-------------------------------------------------------------------------------
; Процедура удаления элемента из очереди на выдачу
;-------------------------------------------------------------------------------
; Удаляет первый элемент из очереди
out_queue_del_proc:
    dec out_queue_len               ; Декремент длины очереди
    breq __gqp_ret
    rcall __get_queue_proc          ; X -> out_queue, LOOPL = размер очереди
    movw YH:YL,XH:XL
    adiw YH:YL,QUEUE_ELEM_SIZE
    rjmp memcpy

;-------------------------------------------------------------------------------
; Процедура получения указателя и размера очереди в байтах
;-------------------------------------------------------------------------------
; Выход: X -> out_queue, LOOPL = размер в байтах
__get_queue_proc:
    ldi XL,LOW(out_queue)
    ldi XH,HIGH(out_queue)
    mov LOOPL,out_queue_len
.if (QUEUE_ELEM_SIZE == 8)
    swap LOOPL
    lsr LOOPL                       ; LOOPL = out_queue_len * QUEUE_ELEM_SIZE
.else
    .error "QUEUE_ELEM_SIZE != 8"
.endif
__gqp_ret:
    ret

;-------------------------------------------------------------------------------
; Процедура добавления одного элемента в очередь
;-------------------------------------------------------------------------------
; LOOPH = заголовок ответа [сохранить]
; Z -> структура данных порта [сохранить]
__queue_add_proc:
    ldi LOOPL,QUEUE_MAX_LENGTH
    cp out_queue_len,LOOPL          ; Проверка длины очереди
    brlo __qap_add
    rcall out_queue_del_proc        ; Удалить первый элемент из очереди
    lds tmp1,out_queue              ; \
    sbr tmp1,(1<<QA_LOSS_BIT)       ;  > Установить бит потери данных!
    sts out_queue,tmp1              ; /
    ; Добавление данных
__qap_add:
    rcall __get_queue_proc          ; X -> out_queue, LOOPL = размер очереди
    inc out_queue_len               ; Инкремент длины очереди
    add XL,LOOPL
    adc XH,zero                     ; X -> конец очереди
    st X+,LOOPH                     ; Сохранить заголовок ответа
    movw YH:YL,ZH:ZL
    adiw YH:YL,(PORT_OUT+OUT_DATA)  ; Y -> данные выдачи порта
    sbrc LOOPH,QA_TX2_BIT
    adiw YH:YL,(OUT_CODE2-OUT_DATA) ; Y -> данные выдачи порта (вторая посылка)
    ld tmp1,Y+                      ; \
    ld tmp2,Y+                      ;  \
    ld tmp3,Y+                      ;  / Загрузка кода карты
    ld tmp4,Y+                      ; /
    ldi LOOPL,1
    rcall lsl_32_proc               ; Сдвиг кода карты на 1 бит влево
    st X+,tmp2                      ; \
    st X+,tmp3                      ;  > Сохранение кода карты
    st X+,tmp4                      ; /
    ldi LOOPL,4
    rjmp memcpy                     ; Копирование PIN
