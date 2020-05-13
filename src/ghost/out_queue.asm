;-------------------------------------------------------------------------------
; ��������� ���������� ������ � ������� �� ������
;-------------------------------------------------------------------------------
; Z -> ��������� ������ ����� [���������]
; ���� T: 0 - ���� �������, 1 - ��� �������. [���������]
out_queue_add_proc:
    tst r_address                   ; �������� ������
    breq __gqp_ret                  ; �����, ���� 0 (RS-485 ��������)
    ; ������������ ��������� ������
    ldi LOOPH,(1<<QA_DATA_BIT)      ; ��� ������� ������
    cpi ZL,LOW(port1)
    breq __oqap_add
    sbr LOOPH,(1<<QA_PORT_BIT)      ; ��� ������ �����
__oqap_add:
    brtc __queue_add_proc           ; ���������� ������ ������� 1
    rcall __queue_add_proc          ; ���������� ������� 1 � �������
    sbr LOOPH,(1<<QA_TX2_BIT)       ; ��� ������ �������
    rjmp __queue_add_proc           ; ���������� ������� 2 � �������

;-------------------------------------------------------------------------------
; ��������� ������� �������� �� �������
;-------------------------------------------------------------------------------
; ������ ������� ���������� � usart_buffer
; �����: LOOPH = ��������� ������
out_queue_fetch_proc:
    ldi XL,LOW(usart_buffer)
    ldi XH,HIGH(usart_buffer)
    ldi YL,LOW(out_queue)
    ldi YH,HIGH(out_queue)
    ld LOOPH,Y+                     ; LOOPH = ��������� �������� �������
    mov tmp1,out_queue_len
    swap tmp1                       ; ������� 4 ���� ������ - ����������
    or LOOPH,tmp1                   ; ��������� ��������� � �������
    st X+,LOOPH                     ; ��������� ��������� ������
    ldi LOOPL,QUEUE_DATA_SIZE       ; LOOPL = ����� ������ ��������
    rjmp memcpy                     ; ����������� ������

;-------------------------------------------------------------------------------
; ��������� �������� �������� �� ������� �� ������
;-------------------------------------------------------------------------------
; ������� ������ ������� �� �������
out_queue_del_proc:
    dec out_queue_len               ; ��������� ����� �������
    breq __gqp_ret
    rcall __get_queue_proc          ; X -> out_queue, LOOPL = ������ �������
    movw YH:YL,XH:XL
    adiw YH:YL,QUEUE_ELEM_SIZE
    rjmp memcpy

;-------------------------------------------------------------------------------
; ��������� ��������� ��������� � ������� ������� � ������
;-------------------------------------------------------------------------------
; �����: X -> out_queue, LOOPL = ������ � ������
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
; ��������� ���������� ������ �������� � �������
;-------------------------------------------------------------------------------
; LOOPH = ��������� ������ [���������]
; Z -> ��������� ������ ����� [���������]
__queue_add_proc:
    ldi LOOPL,QUEUE_MAX_LENGTH
    cp out_queue_len,LOOPL          ; �������� ����� �������
    brlo __qap_add
    rcall out_queue_del_proc        ; ������� ������ ������� �� �������
    lds tmp1,out_queue              ; \
    sbr tmp1,(1<<QA_LOSS_BIT)       ;  > ���������� ��� ������ ������!
    sts out_queue,tmp1              ; /
    ; ���������� ������
__qap_add:
    rcall __get_queue_proc          ; X -> out_queue, LOOPL = ������ �������
    inc out_queue_len               ; ��������� ����� �������
    add XL,LOOPL
    adc XH,zero                     ; X -> ����� �������
    st X+,LOOPH                     ; ��������� ��������� ������
    movw YH:YL,ZH:ZL
    adiw YH:YL,(PORT_OUT+OUT_DATA)  ; Y -> ������ ������ �����
    sbrc LOOPH,QA_TX2_BIT
    adiw YH:YL,(OUT_CODE2-OUT_DATA) ; Y -> ������ ������ ����� (������ �������)
    ld tmp1,Y+                      ; \
    ld tmp2,Y+                      ;  \
    ld tmp3,Y+                      ;  / �������� ���� �����
    ld tmp4,Y+                      ; /
    ldi LOOPL,1
    rcall lsl_32_proc               ; ����� ���� ����� �� 1 ��� �����
    st X+,tmp2                      ; \
    st X+,tmp3                      ;  > ���������� ���� �����
    st X+,tmp4                      ; /
    ldi LOOPL,4
    rjmp memcpy                     ; ����������� PIN
