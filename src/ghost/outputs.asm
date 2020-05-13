;-------------------------------------------------------------------------------
; ���������� �� ������� - ������ ����������� ���� Wiegand
;-------------------------------------------------------------------------------
timer_bit_start_int:
    push ssreg
    in ssreg,SREG
    sei ;>>>>>>>>>>>>>>>>>>>>>>>>>>>> ��������� ��������� ���������� >>>>>>>>>>>
    rcall sreg_output_proc          ; ������ �� ������� �������
    out SREG,ssreg
    pop ssreg
    reti

;-------------------------------------------------------------------------------
; ���������� ������ ��� ������ (����� 1 + PIN 1 + [����� 2 + PIN 2])
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
; ���� T: 0 - ���� �������, 1 - ��� �������.
; X -> PIN 1
; Y -> PIN 2 (T = 1)
; ����� 1 ���������� �� in_code �����������
; ����� 2 ���������� �� in_code ����������� (T = 1)
prepare_output_proc:
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = ��������� ������
    tst tmp1
    brne prepare_output_proc        ; �������� ���������� �������� ������
    brtc __pop_cp_pin1              ; ���� T = 0, ������������ ����� 2 � PIN 2 
    ; ����������� PIN 2
    ld tmp1,Y+
    ld tmp2,Y+
    ld tmp3,Y+
    ld tmp4,Y+
    std Z+PORT_OUT+OUT_PIN2,tmp1
    std Z+PORT_OUT+OUT_PIN2+1,tmp2
    std Z+PORT_OUT+OUT_PIN2+2,tmp3
    std Z+PORT_OUT+OUT_PIN2+3,tmp4
    ; ����� 2 (�������� �� �����������)
    ldd tmp1,Z+PORT_AT_IN+IN_CODE   ; �������� ���� �����
    ldd tmp2,Z+PORT_AT_IN+IN_CODE+1
    ldd tmp3,Z+PORT_AT_IN+IN_CODE+2
    ldd tmp4,Z+PORT_AT_IN+IN_CODE+3
    ldi LOOPL,6
    rcall lsl_32_proc               ; ����� ���� �� 6 ��� �����
    std Z+PORT_OUT+OUT_CODE2,tmp1   ; ���������� ���� �����
    std Z+PORT_OUT+OUT_CODE2+1,tmp2
    std Z+PORT_OUT+OUT_CODE2+2,tmp3
    std Z+PORT_OUT+OUT_CODE2+3,tmp4
__pop_cp_pin1:
    ; ����������� PIN 1
    ld tmp1,X+
    ld tmp2,X+
    ld tmp3,X+
    ld tmp4,X+
    std Z+PORT_OUT+OUT_PIN,tmp1
    std Z+PORT_OUT+OUT_PIN+1,tmp2
    std Z+PORT_OUT+OUT_PIN+2,tmp3
    std Z+PORT_OUT+OUT_PIN+3,tmp4
    ; ����� 1
    ldd tmp1,Z+PORT_CARD_IN+IN_CODE ; �������� ���� �����
    ldd tmp2,Z+PORT_CARD_IN+IN_CODE+1
    ldd tmp3,Z+PORT_CARD_IN+IN_CODE+2
    ldd tmp4,Z+PORT_CARD_IN+IN_CODE+3
    ldi LOOPL,6
    rcall lsl_32_proc               ; ����� ���� �� 6 ��� �����
    std Z+PORT_OUT+OUT_DATA,tmp1    ; ���������� ���� �����
    std Z+PORT_OUT+OUT_DATA+1,tmp2
    std Z+PORT_OUT+OUT_DATA+2,tmp3
    std Z+PORT_OUT+OUT_DATA+3,tmp4
    sbis GPIOR2,PB_ALGORITHM_2
    rjmp __pop_clear_card           ; ���� �������� 1 - ������ "��������" �����
    cpi XL,LOW(pin_vip + 4)         ; ���� �������� 2 - ��������� PIN1 == VIP ?
    breq __pop_save_card            ; ��������� �����, ���� ��
__pop_clear_card:
    rcall clear_card_proc           ; "���������" ���� ����� �� �����������
__pop_save_card:
    sbis GPIOR2,PB_NO_CARD          ; �������� ����������� �����������!
    std Z+PORT_CARD_IN+IN_CNTR,zero ; ��������� ����� �����������
    rcall out_queue_add_proc        ; ���������� ������ � ������� �� ������
    ; ������ ������
    ldi tmp1,W_BIT_COUNT            ; \
    std Z+PORT_OUT+OUT_CNTR,tmp1    ;  > ������������� �������� �����
    std Z+PORT_OUT+OUT_CNTR+1,zero  ; /
    ldi tmp1,OS_CODE                ; ��� ��������� ��������� ��������
    bld tmp1,OS_TX2                 ; �������� ��� ������ �������
    std Z+PORT_OUT+OUT_STATE,tmp1
    ret

;-------------------------------------------------------------------------------
; ��������� ��������� �������� ������
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
; ��������� ��� ��������, �.�. ���������� �� ����������
output_proc:
    push tmp1
    push tmp2
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = ���������
    tst tmp1
    brne __op_active
    rjmp __op_exit                  ; �����, ���� ������ ���������
;-------------------------------------------------------------------------------
__op_active:
    sbrs tmp1,0                     ; ������ ����� � �������� ����������
    rjmp __op_dec_cnt
    ldd tmp1,Z+PORT_OUT+OUT_DATA    ; \
    lsl tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA,tmp1    ; |
    ldd tmp1,Z+PORT_OUT+OUT_DATA+1  ; |
    rol tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA+1,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_DATA+2  ;  > ����� ������ �� 1 ��� �����
    rol tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA+2,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_DATA+3  ; |
    rol tmp1                        ; |
    std Z+PORT_OUT+OUT_DATA+3,tmp1  ; /
    brcs __op_bit1                  ; ���������� ��� � ����� C
__op_bit0:
    ldd tmp1,Z+PORT_B_OUT_D0        ; ��� D0
    rjmp __op_set_bit
__op_bit1:
    ldd tmp1,Z+PORT_B_OUT_D1        ; ��� D1
__op_set_bit:
    or outputs,tmp1                 ; ���������� ������ ���
__op_dec_cnt:                       ; ��������� ��������
    ldd tmp1,Z+PORT_OUT+OUT_CNTR    ; tmp2:tmp1 = �������
    ldd tmp2,Z+PORT_OUT+OUT_CNTR+1
    subi tmp1,1
    sbc tmp2,zero
    std Z+PORT_OUT+OUT_CNTR,tmp1
    std Z+PORT_OUT+OUT_CNTR+1,tmp2
    breq __op_next_st
    rjmp __op_exit                  ; �����, ���� ������� != 0
;-------------------------------------------------------------------------------
__op_next_st:
    ldd tmp1,Z+PORT_OUT+OUT_STATE
    inc tmp1                        ; ������� � ���������� ���������
    std Z+PORT_OUT+OUT_STATE,tmp1
    mov tmp2,tmp1
    andi tmp2,OS_STATE_MASK         ; �������� ��� ���������
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
    sbrs tmp1,OS_TX2                ; ��������� ��� OS_TX2
    rjmp __op_quit                  ; �����, ���� OS_TX2 == 0
    ldd tmp1,Z+PORT_OUT+OUT_PIN2    ; \
    std Z+PORT_OUT+OUT_PIN,tmp1     ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN2+1  ; |
    std Z+PORT_OUT+OUT_PIN+1,tmp1   ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN2+2  ;  > ����������� PIN 2
    std Z+PORT_OUT+OUT_PIN+2,tmp1   ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN2+3  ; |
    std Z+PORT_OUT+OUT_PIN+3,tmp1   ; /
    ldd tmp1,Z+PORT_OUT+OUT_CODE2   ; \
    std Z+PORT_OUT+OUT_DATA,tmp1    ; |
    ldd tmp1,Z+PORT_OUT+OUT_CODE2+1 ; |
    std Z+PORT_OUT+OUT_DATA+1,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_CODE2+2 ;  > ����������� ���� ����� 2
    std Z+PORT_OUT+OUT_DATA+2,tmp1  ; |
    ldd tmp1,Z+PORT_OUT+OUT_CODE2+3 ; |
    std Z+PORT_OUT+OUT_DATA+3,tmp1  ; /
    ldi tmp1,OS_CODE                ; OS_TX2 = 0
    std Z+PORT_OUT+OUT_STATE,tmp1   ; ��������� ������ ������ ���� �����
    ldi tmp1,W_BIT_COUNT            ; ������� ����� ��� ���� �����
    clr tmp2
    rjmp __op_st_cnt
;-------------------------------------------------------------------------------
__op_quit:
    std Z+PORT_OUT+OUT_STATE,zero   ; ���������� ������
    rjmp __op_exit
;-------------------------------------------------------------------------------
__op_delay1:
    ldd tmp2,Z+PORT_OUT+OUT_PIN     ; ��� ������ ����� PIN-����
    tst tmp2                        ; ���� 0, �� PIN-��� ��������
    breq __op_no_pin
    lds tmp1,delay1                 ; ����� ����� ���� �����
    clr tmp2
    rjmp __op_st_cnt                ; ��������� ������� � �����
;-------------------------------------------------------------------------------
__op_no_pin:                        ; tmp1 = ���������
    subi tmp1,(OS_DELAY1-OS_DELAY34); ������� � ����� ����� ENTER
    std Z+PORT_OUT+OUT_STATE,tmp1
    rjmp __op_delay3_4
;-------------------------------------------------------------------------------
__op_digit:
    ldd tmp1,Z+PORT_OUT+OUT_PIN     ; ��� �����
    std Z+PORT_OUT+OUT_DATA+3,tmp1  ; � ������� ���� ������ ������
    ldd tmp1,Z+PORT_OUT+OUT_PIN+1   ; \
    std Z+PORT_OUT+OUT_PIN,tmp1     ; |
    ldd tmp1,Z+PORT_OUT+OUT_PIN+2   ; |
    std Z+PORT_OUT+OUT_PIN+1,tmp1   ;  > ����� PIN �� 1 ���� �����
    ldd tmp1,Z+PORT_OUT+OUT_PIN+3   ; |
    std Z+PORT_OUT+OUT_PIN+2,tmp1   ; |
    std Z+PORT_OUT+OUT_PIN+3,zero   ; /
    rjmp __op_st_key_len
;-------------------------------------------------------------------------------
__op_delay2:
    lds tmp1,delay2                 ; ����� ����� �����
    clr tmp2
    rjmp __op_st_cnt
;-------------------------------------------------------------------------------
__op_enter:
    ldd tmp2,Z+PORT_OUT+OUT_PIN     ; ���������, ���� �� ��� ����� �� ������
    tst tmp2
    breq __op_pin_end
    subi tmp1,(OS_ENTER-OS_DIGIT)   ; ������� � ������ ��������� �����
    std Z+PORT_OUT+OUT_STATE,tmp1
    rjmp __op_digit
;-------------------------------------------------------------------------------
__op_pin_end:
    std Z+PORT_OUT+OUT_DATA+3,enter ; ������ ENTER � ������� ���� ������ ������
__op_st_key_len:
    lds tmp1,key_length             ; ���������� ��� � �������� ���� � ENTER
    clr tmp2
    rjmp __op_st_cnt
;-------------------------------------------------------------------------------
__op_delay3_4:                      ; tmp1 = ���������
    sbrs tmp1,OS_TX2                ; ��������� ��� ������ �������
    rjmp __op_delay4
    lds tmp1,delay3                 ; ����� ����� ���������
    lds tmp2,(delay3+1)
    rjmp __op_st_cnt
__op_delay4:
    lds tmp1,delay4                 ; ����� ����� �������� ENTER
    lds tmp2,(delay4+1)
__op_st_cnt:
    std Z+PORT_OUT+OUT_CNTR,tmp1
    std Z+PORT_OUT+OUT_CNTR+1,tmp2
__op_exit:
    pop tmp2
    pop tmp1
    ret

;-------------------------------------------------------------------------------
; ������ �� ������� �������
;-------------------------------------------------------------------------------
; outputs = �������� ��� ������
; sregdata = ������� �������� �� ������� ��������
sreg_output_proc:                   ; ����� ���������� 80 ������ = 20 ���
    cp outputs,sregdata             ; ���� ��� ���������,
    breq __sop_ret                  ; �� ����� �� ���������
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
