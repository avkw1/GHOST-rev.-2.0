;-------------------------------------------------------------------------------
; �������� ������������ �� EEPROM
;-------------------------------------------------------------------------------
read_config_proc:
    ; ������ EEPROM � ���
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
    ; ������������� PIN-�����
    ldi XL,LOW(pin_pass)            ; PIN-���� ����������� � ��� ���� �� ������
    ldi XH,HIGH(pin_pass)
    ldi LOOPL,16                    ; 4 PIN-���� �� 4 �����
__rcp_decode_lp:
    ld ZL,X
    tst ZL
    breq __rcp_continue             ; ���� 0, �� ���������� ������
    andi ZL,0x0F                    ; ������� 4 ����
    subi ZL,-ee_key_table           ; + ee_key_table
    rcall eeprom_read_byte_proc
    st X,tmp1
__rcp_continue:
    adiw XH:XL,1
    dec LOOPL
    brne __rcp_decode_lp
    ; �������� ���� ������� ENTER
    ldi ZL,ee_key_table+(C_ENTER & 0x0F)
    rcall eeprom_read_byte_proc
    mov enter,tmp1
    ret

;------------------------------------------------------------------------------
; ������ 1 ����� EEPROM
;------------------------------------------------------------------------------
; ����: ZL -> ����� EEPROM
; �����: tmp1 - ����������� ����
eeprom_read_byte_proc:
    EEPROM_RD
    ret
