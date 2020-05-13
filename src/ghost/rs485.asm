;-------------------------------------------------------------------------------
; ���������� USART Receive Complete
;-------------------------------------------------------------------------------
rxc_int:
    push ssreg
    in ssreg,SREG
    push tmp1
    in tmp1,UDR                     ; tmp1 = �������� ����
    sbis UCSRA,MPCM                 ; ���� MPCM ��������, ��������� �����
    rjmp __ri_data_rx               ; ����� ������� � ����� ������
    ; �������� ������ �������
    push tmp1
    andi tmp1,ADDR_MASK
    cpi tmp1,ADDR_MASK              ; ����������������� �����?
    breq __ri_broadcast
    cp tmp1,r_address
__ri_broadcast:
    pop tmp1
    brne __ri_exit_int              ; ����� �� ����������, ���� ������ �����
    cbi UCSRA,MPCM                  ; ��������� MPCM
    ; ���� ������ � �����
__ri_data_rx:
    push XL
    push XH
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    add XL,usart_cntr
    adc XH,zero
    st X+,tmp1                      ; ��������� ���� � ����� �����
    ; �������� �������� ���� �������
    tst usart_cntr                  ; usart_cntr == 0 ?
    brne __ri_check_len
    ; �������� ���� �������
    andi tmp1,CMD_MASK
    cpi tmp1,CC_RELAY
    brlo __ri_check_len
    brne __ri_invalid_data          ; �����, ���� ������������ ��� �������
    inc usart_len                   ; ��������� �����, ���� ������� CC_RELAY
__ri_check_len:
    ; �������� �����
    inc usart_cntr
    cp usart_cntr,usart_len
    brlo __ri_exit
    ; �������� ����������� �����
    push tmp2
    push tmp3
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    rcall crc16_proc                ; �������� CRC, ����� �������� ������
    or tmp1,tmp2
    pop tmp3
    pop tmp2
    brne __ri_invalid_data          ; ������������, ���� ������ CRC
    ; ������� ��������
    sbr incodes,(1<<INC_RS485)      ; ��������� ��������� �������
    SET_TX                          ; ������������ �� ��������
    RXCIE_OFF                       ; ��������� RXC
    TXCIE_ON                        ; �������� TXC
    rjmp __ri_exit
__ri_invalid_data:
    ; ������������ ������������ ������
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
; ���������� USART Transmit Complete
;-------------------------------------------------------------------------------
txc_int:
    push ssreg
    in ssreg,SREG
    push tmp1
    rcall usart_reset_proc
    rjmp __ri_exit_int

;-------------------------------------------------------------------------------
; ���������� USART Data Register Empty
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
    ld tmp1,X                       ; tmp1 = ��������� ���� ��� ��������
    out UDR,tmp1
    inc usart_cntr                  ; ��������� �������� ������
    cp usart_cntr,usart_len
    brlo __ui_exit                  ; �����, ���� �� ��������� ����
    UDRIE_OFF                       ; ��������� UDRE (��� ����������)
    TXCIE_ON                        ; �������� TXC
__ui_exit:
    pop XH
    pop XL
    rjmp __ri_exit_int

;-------------------------------------------------------------------------------
; ��������� ������ USART (������� � ���������� ���������)
;-------------------------------------------------------------------------------
usart_reset_proc:
    clr usart_cntr                  ; usart_cntr = 0
    ldi tmp1,MIN_CMD_LENGTH
    mov usart_len,tmp1              ; usart_len = MIN_CMD_LENGTH
    ldi tmp1,(1<<RXCIE)|(1<<RXEN)|(1<<TXEN)|(1<<UCSZ2)
    out UCSRB,tmp1                  ; �������� RXC, ��������� TXC
    sbi UCSRA,MPCM                  ; �������� MPCM
    SET_RX                          ; ������������� �� ����
    ret

;-------------------------------------------------------------------------------
; ��������� ���������� CRC16
;-------------------------------------------------------------------------------
; ����: ������ ��������� � X -> usart_buffer
;       usart_cntr - ���������� ������
; �����: tmp2:tmp1 - ����������� �����
crc16_proc:
    ser tmp1                        ; ��������� �������� 0xFFFF
    ser tmp2

__c16_byte_lp:
    ld tmp3,X+                      ; �������� ���������� �����
    eor tmp1,tmp3                   ; CRC ^= ����
    ldi tmp3,8                      ; ������� �����

__c16_bit_lp:
    lsr tmp2                        ; ����� 16-������ CRC
    ror tmp1
    brcc __c16_next_bit             ; ���������� ��� ����� 0?
    eor tmp1,polyl
    eor tmp2,polyh

__c16_next_bit:
    dec tmp3                        ; ������� �����
    brne __c16_bit_lp

    dec usart_cntr                  ; ������� ������
    brne __c16_byte_lp
    ret

