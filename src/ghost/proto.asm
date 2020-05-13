;-------------------------------------------------------------------------------
; ���������� ������ ��������� ������ �� RS-485
;-------------------------------------------------------------------------------
process_cmd_proc:
    lds tmp1,usart_buffer
    andi tmp1,CMD_MASK              ; tmp1 = ��� �������
    cpi tmp1,CC_QUERY
    breq __pcp_cmd_query
    cpi tmp1,CC_QACK
    breq __pcp_cmd_qack
    out UDR,polyh                   ; ������ �������� ������ ANSWER_OK
    cpi tmp1,CC_BOOTLOADER
    breq __pcp_cmd_bootloader
    cpi tmp1,CC_RESET
    breq __pcp_cmd_reset
    cpi tmp1,CC_RELAY
    breq __pcp_cmd_relay
    ret

;-------------------------------------------------------------------------------
__pcp_cmd_reset:
__pcp_cmd_bootloader:
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< ���������� ��������� <<<<<<<<<<<<<<<<<<<<<
    USART_WAIT_TX                   ; �������� ���������� ��������
    SET_RX                          ; ������������ �� ����
    ldi XL,LOW(RAMEND)              ; ������������� ��������� �����
    out SPL,XL
    ldi XL,HIGH(RAMEND)
    out SPH,XL
    sbrs tmp1,5                     ; ����������, ���� ��� ������� CC_BOOTLOADER
    rjmp start                      ; ����������� �����!
    clr outputs
    rcall sreg_output_proc          ; �������� ������� �������
    out UCSRA,zero                  ; ��������� MPCM
    ldi ZL,LOW(BOOTLDR_SFLAG_ADDRESS)
    ldi ZH,HIGH(BOOTLDR_SFLAG_ADDRESS)
    movw r5:r4,ZH:ZL                ; ������������� ������ ����� ������
    clr r3                          ; ������������� ����� ������
    rjmp BOOTLDR_JUMP_ADDRESS       ; ������� �� ����� INIT!

;-------------------------------------------------------------------------------
__pcp_cmd_relay:
    ldi ZL,LOW(port1)
    ldi ZH,HIGH(port1)
    lds LOOPH,(usart_buffer + 1)    ; LOOPH = ��������
    sbrc LOOPH,7                    ; 0 = ���� 1, 1 = ���� 2
    adiw ZH:ZL,PORT_STRUCT_SIZE
    rjmp relay_control_proc

;-------------------------------------------------------------------------------
__pcp_cmd_query:
    tst out_queue_len               ; ��������� ����� �������
    breq __pcp_q_empty              ; �������, ���� ������� �����
    rcall out_queue_fetch_proc      ; ������� �������� �� �������
    TXCIE_OFF                       ; ��������� TXC
    out UDR,LOOPH                   ; ������ �������� ������!
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    ldi tmp1,(ANSWER_LENGTH-2)      ; tmp1 = ����� ��� CRC
    mov usart_cntr,tmp1
    rcall CRC16_proc                ; ���������� CRC
    st X+,tmp1
    st X+,tmp2
    ldi tmp1,ANSWER_LENGTH
    mov usart_len,tmp1              ; usart_len = ����� ������
    mov usart_cntr,polyl            ; usart_cntr = 1
    UDRIE_ON                        ; �������� UDRE
    ret

__pcp_q_empty:
    out UDR,polyh                   ; ������ �������� ������ ANSWER_OK
    ret

;-------------------------------------------------------------------------------
__pcp_cmd_qack:
    tst out_queue_len               ; ��������� ����� �������
    breq __pcp_q_empty              ; �������, ���� ������� �����
    rcall out_queue_del_proc        ; �������� �������� �� �������
    mov tmp1,polyh
    or tmp1,out_queue_len
    out UDR,tmp1                    ; ������ �������� ������
    ret
