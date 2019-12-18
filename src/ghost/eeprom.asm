;-------------------------------------------------------------------------------
; Загрузка конфигурации из EEPROM
;-------------------------------------------------------------------------------
read_config_proc:
    ; Чтение EEPROM в ОЗУ
    ldi XL,LOW(ram_cfg_start)
    ldi XH,HIGH(ram_cfg_start)
    ldi ZL,ee_cfg_start
    ldi LOOPL,EE_CFG_SIZE
__rcp_ee_read_lp:
    rcall eeprom_read_byte_proc
    inc ZL
    st X+,tmp1
    dec LOOPL
    brne __rcp_ee_read_lp
    ; Перекодировка PIN-кодов
    ldi XL,LOW(pin_pass)            ; PIN-коды расположены в ОЗУ друг за другом
    ldi XH,HIGH(pin_pass)
    ldi LOOPL,16                    ; 4 PIN-кода по 4 цифры
__rcp_decode_lp:
    ld ZL,X
    tst ZL
    breq __rcp_continue             ; Если 0, то пропустить символ
    andi ZL,0x0F                    ; Младшие 4 бита
    subi ZL,-ee_key_table           ; + ee_key_table
    rcall eeprom_read_byte_proc
    st X,tmp1
__rcp_continue:
    adiw XH:XL,1
    dec LOOPL
    brne __rcp_decode_lp
    ; Загрузка кода символа ENTER
    ldi ZL,ee_key_table+(C_ENTER & 0x0F)
    rcall eeprom_read_byte_proc
    mov enter,tmp1
    ret

;------------------------------------------------------------------------------
; Чтение 1 байта EEPROM
;------------------------------------------------------------------------------
; вход: ZL -> адрес EEPROM
; выход: tmp1 - прочитанный байт
eeprom_read_byte_proc:
    EEPROM_RD
    ret
