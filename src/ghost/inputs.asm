;-------------------------------------------------------------------------------
; Прерывание по изменению состояния входов
;-------------------------------------------------------------------------------
pin_change_int:
    push ssreg
    in ssreg,SREG
    mov in_old,in_new
    in in_tmp,INS_PIN               ; Чтение состояния входов
    mov in_new,in_tmp
    eor in_tmp,in_old
    and in_tmp,in_old
    or inbits,in_tmp                ; Уст. 1, если бит изменился 1->0
    out SREG,ssreg
    pop ssreg
    reti

;-------------------------------------------------------------------------------
; Обработка полученного бита 0
;-------------------------------------------------------------------------------
input_bit_0_proc:
    clc                             ; С = 0
    rjmp input_bit_proc

;-------------------------------------------------------------------------------
; Обработка полученного бита 1
;-------------------------------------------------------------------------------
input_bit_1_proc:
    sec                             ; С = 1

;-------------------------------------------------------------------------------
; Обработка полученного бита
;-------------------------------------------------------------------------------
; флаг C = значение бита
; Z -> структура данных входа
input_bit_proc:
    ldd tmp1,Z+IN_DATA
    ldd tmp2,Z+IN_DATA+1
    ldd tmp3,Z+IN_DATA+2
    ldd tmp4,Z+IN_DATA+3
    rol tmp1                        ; Добавление бита и сдвиг кода влево
    rol tmp2
    rol tmp3
    rol tmp4
    std Z+IN_DATA,tmp1
    std Z+IN_DATA+1,tmp2
    std Z+IN_DATA+2,tmp3
    std Z+IN_DATA+3,tmp4
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< Прерывания запрещены <<<<<<<<<<<<<<<<<<<<<
    ldi LOOPL,W_BIT_TIMEOUT
    std Z+IN_TCNTR,LOOPL            ; Перезапуск счётчика тайм-аута
    ldd LOOPL,Z+IN_CNTR
    inc LOOPL                       ; Инкремент счётчика битов
    cpse LOOPL,zero                 ; Проверка на W_IN_DISABLED
    std Z+IN_CNTR,LOOPL             ; Пропускается, если вход выключен
    sei ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    cpi LOOPL,W_BIT_COUNT
    brlo __ibp_ret                  ; Выход, если не последний бит
;-------------------------------------------------------------------------------
; Код получен полностью
    std Z+IN_CNTR,zero              ; Обнулить счётчик битов
    andi tmp4,0x03                  ; Обнулить неиспользуемые биты
    ; Проверить, обработан ли предыдущий код
    ldd LOOPH,Z+IN_BIT              ; Бит получения кода
    mov LOOPL,incodes
    and LOOPL,LOOPH                 ; Проверить бит в incodes
    brne __ibp_ret                  ; Выход, если предыдущий код не обработан
;-------------------------------------------------------------------------------
; Контроль чётности
    sbrc tmp4,1                     ; Байт 3: биты 0-1
    inc LOOPL
    sbrc tmp4,0
    inc LOOPL
    sbrc tmp3,7                     ; Байт 2: биты 2-9
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
    sbrc tmp2,7                     ; Байт 1: биты 10-12
    inc LOOPL
    sbrc tmp2,6
    inc LOOPL
    sbrc tmp2,5
    inc LOOPL
    sbrc LOOPL,0                    ; Должно быть чётное количество единиц
__ibp_ret:
    ret                             ; Выход, если нечётное
    sbrc tmp2,4                     ; Байт 1: биты 13-17
    inc LOOPL
    sbrc tmp2,3
    inc LOOPL
    sbrc tmp2,2
    inc LOOPL
    sbrc tmp2,1
    inc LOOPL
    sbrc tmp2,0
    inc LOOPL
    sbrc tmp1,7                     ; Байт 0: биты 18-25
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
    sbrc tmp1,0
    inc LOOPL
    sbrs LOOPL,0                    ; Должно быть нечётное количество единиц
    ret                             ; Выход, если чётное
;-------------------------------------------------------------------------------
; Сохранение полученного кода
    std Z+IN_CODE,tmp1
    std Z+IN_CODE+1,tmp2
    std Z+IN_CODE+2,tmp3
    std Z+IN_CODE+3,tmp4
    or incodes,LOOPH                ; Установить бит получения кода
    ret

;-------------------------------------------------------------------------------
; Проверка тайм-аута приёма бита
;-------------------------------------------------------------------------------
; Z -> структура данных входа
; Сохранять все регистры, так как вызывается из прерывания
input_timeout_proc:
    push tmp1
    ldd tmp1,Z+IN_CNTR
    cp zero,tmp1                    ; Проверить счётчик битов
    brge __itp_exit                 ; Выход, если 0 или W_IN_DISABLED (-1)
    ldd tmp1,Z+IN_TCNTR             ; \
    dec tmp1                        ;  > Декремент счётчика времени
    std Z+IN_TCNTR,tmp1             ; /
    brne __itp_exit                 ; Выход, если != 0
    std Z+IN_CNTR,zero              ; Сброс счётчика битов, если время вышло
__itp_exit:
    pop tmp1
    ret

;-------------------------------------------------------------------------------
; "Обнуление" кода карты от считывателя
;-------------------------------------------------------------------------------
; Процедура копирует null_card в in_code считывателя
; Z -> структура данных порта
clear_card_proc:
    ldi XL,LOW(null_card)
    ldi XH,HIGH(null_card)
    ld tmp1,X+
    std Z+PORT_CARD_IN+IN_CODE,tmp1
    ld tmp1,X+
    std Z+PORT_CARD_IN+IN_CODE+1,tmp1
    ld tmp1,X+
    std Z+PORT_CARD_IN+IN_CODE+2,tmp1
    ld tmp1,X+
    std Z+PORT_CARD_IN+IN_CODE+3,tmp1
    ret
