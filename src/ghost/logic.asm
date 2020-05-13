;-------------------------------------------------------------------------------
; ������������� �����
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
port_init_proc:
    ldi tmp1,AT_POWER_OFF           ; ��������� ��������� ����������� - ��������
    std Z+PORT_AT_STATE,tmp1
    sbis GPIOR2,PB_NO_CARD          ; ���� ��������� �������� ����� ����
    rjmp clear_card_proc            ; PB_NO_CARD = 0, ������� �������������
    ldi tmp1,W_IN_DISABLED
    std Z+PORT_CARD_IN+IN_CNTR,tmp1 ; ��������� ���� �����������!
    sts null_card,tmp1              ; �������� ������ ��� ����� (null_card != 0)
    rjmp clear_card_proc            ; PB_NO_CARD = 1, �������� null_card != 0

;-------------------------------------------------------------------------------
; ��������� ����������� ���� �����
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
card_code_proc:
    ; ��������� � �������� ������
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
    ; ������ ����� �� �����
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< ������ ���������� <<<<<<<<<<<<<<<<<<<<<<<<
    ldi tmp1,LOW(RAMEND)            ; ������������� �����
    out SPL,tmp1
    ldi tmp1,HIGH(RAMEND)
    out SPH,tmp1
    lds LOOPH,ctest_time            ; LOOPH = ����� ����� �� �����
    rjmp test                       ; ������� � �����
;-------------------------------------------------------------------------------
__ccp_no_test:
    ldd tmp1,Z+PORT_AT_STATE        ; tmp1 = ��������� �����������
    sbic GPIOR2,PB_ALGORITHM_2
    rjmp __ccp_alg_2                ; �������, ���� ������� �������� 2
    cpi tmp1,AT_ANALYSIS            ; ���� ������
    breq __ccp_analysis
    cpi tmp1,AT_PASS                ; ���� �����
    breq __ccp_ret
    cpi tmp1,AT_FAIL                ; ���� ��������
    breq __ccp_ret
__ccp_send_vip:
    ldi XL,LOW(pin_vip)             ; PIN 1 -> VIP
    ldi XH,HIGH(pin_vip)
    clt                             ; T = 0 (�� ���������� 2-� ����!)
    rjmp prepare_output_proc        ; ��������
;-------------------------------------------------------------------------------
__ccp_alg_2:
    cpi tmp1,AT_READY               ; ���� �� "�����", 
    brne __ccp_send_vip             ; ���������� ������ �������
    lds LOOPH,card_time             ; LOOPH = ����� ����-���� �����
    rcall at_timer_start_x1_proc    ; ������ �������, ���� ��������� "�����"
    rjmp __ccp_send_vip             ; ��������� ��� ����� ��� VIP
;-------------------------------------------------------------------------------
__ccp_analysis:
    ldi tmp1,W_IN_DISABLED
    sbic GPIOR2,PB_SINGLE_CARD      ; ���� PB_SINGLE_CARD = 1, 
    std Z+PORT_CARD_IN+IN_CNTR,tmp1 ; ��������� ���� �����������
__ccp_ret:
    ret                             ; ������� �� ���������

;-------------------------------------------------------------------------------
; ��������� ������ �� �����������
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
alcotester_code_proc:
    ldd tmp1,Z+PORT_AT_IN+IN_CODE   ; �������� ����������� ����
    ldd tmp2,Z+PORT_AT_IN+IN_CODE+1
    ldd tmp3,Z+PORT_AT_IN+IN_CODE+2
    ldd tmp4,Z+PORT_AT_IN+IN_CODE+3
    lsr tmp4                        ; ����� �� 1 ��� ������
    ror tmp3
    ror tmp2
    ror tmp1
    eor tmp1,tmp3
    eor tmp2,tmp3
    movw tmp4:tmp3,tmp2:tmp1        ; tmp4:tmp3 = ���:�����1:�����2:�����3
    swap tmp2
    andi tmp2,0x0F                  ; tmp2 = ��� ���������
    std Z+PORT_AT_STATE,tmp2        ; ��������� ����� ��������� �����������
    std Z+PORT_AT_TIMER_ON,zero     ; ���������� ������ �������!
    ; ����� �������� �� ���� ���������
    cpi tmp2,AT_POWER_ON            ; ���������
    brne __acp_2
    sbis GPIOR0,EM_POWER_ON         ; ���������, ��������� �� ������ �������
    ret                             ; �����, ���� ���
    rjmp __acp_state                ; ������ ������ ���� ���������
;-------------------------------------------------------------------------------
__acp_2:
    cpi tmp2,AT_POWER_OFF           ; ���������� �������
    brne __acp_3
    sbis GPIOR0,EM_POWER_OFF
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_3:
    cpi tmp2,AT_AUTO_POWER_OFF      ; �������������� ����������
    brne __acp_4
    sbis GPIOR0,EM_AUTO_POWER_OFF
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_4:
    cpi tmp2,AT_READY               ; �����
    brne __acp_5
    sbis GPIOR1,EM2_READY
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_5:
    cpi tmp2,AT_ERROR               ; ������ (������������� �����)
    brne __acp_6
    lds tmp1,er_timeout             ; tmp1 = ����-��� ��� ������
    rcall at_timer_start_x5_proc    ; ������ ������� �������
    sbis GPIOR0,EM_ERROR
    ret
    ldi tmp2,AT_ERROR               ; ������������ tmp2!
    rjmp __acp_state                ; ������ ���� ���������
;-------------------------------------------------------------------------------
__acp_6:
    cpi tmp2,AT_ANALYSIS            ; ������
    brne __acp_7
    lds tmp1,as_timeout             ; tmp1 = ����-��� ��� �������
    rcall at_timer_start_x5_proc    ; ������ ������� �������
    sbic GPIOR2,PB_ALGORITHM_2      ; ���� �������� 2,
    rjmp __acp_6_alg2               ; �� �������
    sbis GPIOR1,EM2_ANALYSIS
    ret
    ldi tmp2,AT_ANALYSIS            ; ������������ tmp2
    rjmp __acp_state                ; ������ ���� ���������

__acp_6_alg2:
    ldi tmp1,W_IN_DISABLED          ; ��� ��������� 2
    std Z+PORT_CARD_IN+IN_CNTR,tmp1 ; ��������� ���� �����������
    ret                             ; ����� (��� EM2_ANALYSIS ������������)
;-------------------------------------------------------------------------------
__acp_7:
    cpi tmp2,AT_PASS                ; �����
    set                             ; T = 1
    brne __acp_8
    ldi XL,LOW(pin_pass)            ; PIN 1 -> pin_pass
    ldi XH,HIGH(pin_pass)
    sbis GPIOR0,EM_PASS             ; ��� ���������� ������ ��������� "�����"
    clt                             ; �� ���������� 2-� ����, ���� ��� = 0
    rjmp __acp_8_pin2_data
;-------------------------------------------------------------------------------
__acp_8:
    cpi tmp2,AT_FAIL                ; ��������
    brne __acp_9
    rcall relay_on_proc             ; �������� ����!
    ldi XL,LOW(pin_fail)            ; PIN 1 -> pin_fail
    ldi XH,HIGH(pin_fail)
    sbis GPIOR0,EM_FAIL             ; ��� ���������� ������ ��������� "��������"
    clt                             ; �� ���������� 2-� ����, ���� ��� = 0
__acp_8_pin2_data:
    ldi YL,LOW(pin_data)            ; PIN 2 -> pin_data
    ldi YH,HIGH(pin_data)
    rjmp __acp_card_value
;-------------------------------------------------------------------------------
__acp_9:
    cpi tmp2,AT_STANDBY_MODE        ; ����� ��������
    brne __acp_10
    sbis GPIOR0,EM_STANDBY_MODE
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_10:
    cpi tmp2,AT_BREAKDOWN           ; �������������
    brne __acp_11
    sbis GPIOR0,EM_BREAKDOWN
__acp_ret:
    ret
    rjmp __acp_state
;-------------------------------------------------------------------------------
__acp_11:
    cpi tmp2,AT_TIMEOUT             ; ����-���
    brne __acp_ret
    ldi tmp1,AT_READY
    std Z+PORT_AT_STATE,tmp1        ; �������� �� ��� "�����"
    ; ... � ������ ��� "����-���"
;-------------------------------------------------------------------------------
; ������ ������ ���� ��������� �����������
; tmp2 = ��� ���������
__acp_state:
    rcall code_to_card_proc         ; �������������� ���� ��������� � ��� �����
    ldi XL,LOW(pin_data)            ; PIN 1 -> pin_data
    ldi XH,HIGH(pin_data)
    clt                             ; T = 0 (�� ���������� 2-� ����!)
    rjmp prepare_output_proc        ; ��������

;-------------------------------------------------------------------------------
; ������ ���� ����� � ��������
; tmp4:tmp3 = ���:�����1:�����2:�����3
; X -> PIN 1, Y -> PIN 2
; T: 0 - �� ���������� ��������, 1 - ���������� ��������
__acp_card_value:
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE ; �������� �� ��� ����� 0
    cp tmp1,zero
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+1
    cpc tmp1,zero
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+2
    cpc tmp1,zero
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE+3
    cpc tmp1,zero                   ; ����� ���� ������ ���� null_card = 0 
    breq __acp_no_output            ; � �� ������� ��� ����� => �����
    brtc __acp_no_value             ; ���� T = 0, �� �������
    mov tmp1,tmp4
    andi tmp1,0x0F                  ; tmp1 = ������� �����
    mov tmp2,tmp3
    swap tmp2
    andi tmp2,0x0F                  ; tmp2 = ������ �����
    andi tmp3,0x0F                  ; tmp3 = ������ �����
    push XL
    push XH
    movw XH:XL,ZH:ZL
    adiw XH:XL,PORT_AT_IN+IN_CODE
    sbis GPIOR2,PB_NO_CARD          ; ���� ��������� �������� ����� ����
    sbic GPIOR2,PB_VALUE_ONLY       ; ��� ��� ����� �� ����������� (�������� 2)
    sbiw XH:XL,PORT_AT_IN-PORT_CARD_IN  ; �������� �� ����� ���� �����
    rcall value_to_card_proc        ; �������������� �������� � ��� �����
    set                             ; ������������ T = 1
    pop XH
    pop XL                          ; X -> PIN 1, Y -> PIN 2
    sbis GPIOR2,PB_NO_CARD          ; ���� ��������� �������� ����� ����
    sbic GPIOR2,PB_VALUE_ONLY       ; ��� ��� ����� �� ����������� (�������� 2)
    rjmp __acp_value_only           ; ��������� ������ �������� �� �����������
    rjmp prepare_output_proc        ; �������� (����� + PIN 1, �������� + PIN 2)

__acp_value_only:
    movw XH:XL,YH:YL                ; PIN 1 = PIN 2
    clt                             ; �� ���������� 2-� ����!
    rjmp prepare_output_proc        ; �������� (�������� + PIN 2)

__acp_no_value:
    sbis GPIOR2,PB_NO_CARD          ; ���� ��������� �������� ����� ����
    sbic GPIOR2,PB_VALUE_ONLY       ; ��� ��� ����� �� ����������� (�������� 2)
    rjmp __acp_no_output            ; ����� - ������ ����������.
    rjmp prepare_output_proc        ; �������� (����� + PIN 1)

__acp_no_output:
    sbis GPIOR2,PB_NO_CARD          ; �������� ����������� �����������!
    std Z+PORT_CARD_IN+IN_CNTR,zero ; ��������� ����� �����������
    ret

;-------------------------------------------------------------------------------
; �������������� ���� ��������� � ��� �����
;-------------------------------------------------------------------------------
; tmp2 = ��� ���������
; Z -> ��������� ������ �����
; �������� ����� ������������ ������ ���� �� �����������. ������� 6 ��� = 0.
code_to_card_proc:
    mov LOOPL,tmp2
    clr LOOPH
    lds tmp1,c_offset               ; �������� ��� ���� ���������
    lds tmp2,(c_offset+1)
    add tmp1,LOOPL
    adc tmp2,LOOPH
    lds tmp3,c_facility             ; ��� ����������� ��� ���� ���������
    movw XH:XL,ZH:ZL
    adiw XH:XL,PORT_CARD_IN+IN_CODE
    rjmp __vtcp_shift

;-------------------------------------------------------------------------------
; �������������� �������� �� ����������� � ��� �����
;-------------------------------------------------------------------------------
; tmp1,tmp2,tmp3 = ����� (������� � tmp1)
; X -> ����� ��� ������ ���� �����
; Z -> ��������� ������ �����
value_to_card_proc:
    ; �������������� ���� � �������� �������� 
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
    ; ���������� �������� � ���� �����������
__vtcp_add_offset:
    lds tmp1,v_offset               ; �������� ��� ��������
    lds tmp2,(v_offset+1)
    add tmp1,LOOPL
    adc tmp2,LOOPH
    lds tmp3,v_facility             ; ��� ����������� ��� ��������
__vtcp_shift:
    clr tmp4                        ; tmp4 = 0
    lsl tmp1                        ; \
    rol tmp2                        ;  \
    rol tmp3                        ;  / ����� �� 1 ��� �����
    rol tmp4                        ; /
    ; ���������� ����� ��������
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
    bld tmp4,1                      ; ���������� ���� ����������
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
    bld tmp1,0                      ; ���������� ���� ��������
    ; ���������� ��������������� ���� �����
    st X+,tmp1
    st X+,tmp2
    st X+,tmp3
    st X+,tmp4
    ret
