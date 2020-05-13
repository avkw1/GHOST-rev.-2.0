;-------------------------------------------------------------------------------
; ���������� �� ��������� ��������� ������
;-------------------------------------------------------------------------------
pin_change_int:
    push ssreg
    in ssreg,SREG
    mov in_old,in_new
    in in_tmp,INS_PIN               ; ������ ��������� ������
    mov in_new,in_tmp
    eor in_tmp,in_old
    and in_tmp,in_old
    or inbits,in_tmp                ; ���. 1, ���� ��� ��������� 1->0
    out SREG,ssreg
    pop ssreg
    reti

;-------------------------------------------------------------------------------
; ��������� ����������� ���� 0
;-------------------------------------------------------------------------------
input_bit_0_proc:
    clc                             ; � = 0
    rjmp input_bit_proc

;-------------------------------------------------------------------------------
; ��������� ����������� ���� 1
;-------------------------------------------------------------------------------
input_bit_1_proc:
    sec                             ; � = 1

;-------------------------------------------------------------------------------
; ��������� ����������� ����
;-------------------------------------------------------------------------------
; ���� C = �������� ����
; Z -> ��������� ������ �����
input_bit_proc:
    ldd tmp1,Z+IN_DATA
    ldd tmp2,Z+IN_DATA+1
    ldd tmp3,Z+IN_DATA+2
    ldd tmp4,Z+IN_DATA+3
    rol tmp1                        ; ���������� ���� � ����� ���� �����
    rol tmp2
    rol tmp3
    rol tmp4
    std Z+IN_DATA,tmp1
    std Z+IN_DATA+1,tmp2
    std Z+IN_DATA+2,tmp3
    std Z+IN_DATA+3,tmp4
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< ���������� ��������� <<<<<<<<<<<<<<<<<<<<<
    ldi LOOPL,W_BIT_TIMEOUT
    std Z+IN_TCNTR,LOOPL            ; ���������� �������� ����-����
    ldd LOOPL,Z+IN_CNTR
    inc LOOPL                       ; ��������� �������� �����
    cpse LOOPL,zero                 ; �������� �� W_IN_DISABLED
    std Z+IN_CNTR,LOOPL             ; ������������, ���� ���� ��������
    sei ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    cpi LOOPL,W_BIT_COUNT
    brlo __ibp_ret                  ; �����, ���� �� ��������� ���
;-------------------------------------------------------------------------------
; ��� ������� ���������
    std Z+IN_CNTR,zero              ; �������� ������� �����
    andi tmp4,0x03                  ; �������� �������������� ����
    ; ���������, ��������� �� ���������� ���
    ldd LOOPH,Z+IN_BIT              ; ��� ��������� ����
    mov LOOPL,incodes
    and LOOPL,LOOPH                 ; ��������� ��� � incodes
    brne __ibp_ret                  ; �����, ���� ���������� ��� �� ���������
;-------------------------------------------------------------------------------
; �������� ��������
    sbrc tmp4,1                     ; ���� 3: ���� 0-1
    inc LOOPL
    sbrc tmp4,0
    inc LOOPL
    sbrc tmp3,7                     ; ���� 2: ���� 2-9
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
    sbrc tmp2,7                     ; ���� 1: ���� 10-12
    inc LOOPL
    sbrc tmp2,6
    inc LOOPL
    sbrc tmp2,5
    inc LOOPL
    sbrc LOOPL,0                    ; ������ ���� ������ ���������� ������
__ibp_ret:
    ret                             ; �����, ���� ��������
    sbrc tmp2,4                     ; ���� 1: ���� 13-17
    inc LOOPL
    sbrc tmp2,3
    inc LOOPL
    sbrc tmp2,2
    inc LOOPL
    sbrc tmp2,1
    inc LOOPL
    sbrc tmp2,0
    inc LOOPL
    sbrc tmp1,7                     ; ���� 0: ���� 18-25
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
    sbrs LOOPL,0                    ; ������ ���� �������� ���������� ������
    ret                             ; �����, ���� ������
;-------------------------------------------------------------------------------
; ���������� ����������� ����
    std Z+IN_CODE,tmp1
    std Z+IN_CODE+1,tmp2
    std Z+IN_CODE+2,tmp3
    std Z+IN_CODE+3,tmp4
    or incodes,LOOPH                ; ���������� ��� ��������� ����
    ret

;-------------------------------------------------------------------------------
; �������� ����-���� ����� ����
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
; ��������� ��� ��������, ��� ��� ���������� �� ����������
input_timeout_proc:
    push tmp1
    ldd tmp1,Z+IN_CNTR
    cp zero,tmp1                    ; ��������� ������� �����
    brge __itp_exit                 ; �����, ���� 0 ��� W_IN_DISABLED (-1)
    ldd tmp1,Z+IN_TCNTR             ; \
    dec tmp1                        ;  > ��������� �������� �������
    std Z+IN_TCNTR,tmp1             ; /
    brne __itp_exit                 ; �����, ���� != 0
    std Z+IN_CNTR,zero              ; ����� �������� �����, ���� ����� �����
__itp_exit:
    pop tmp1
    ret

;-------------------------------------------------------------------------------
; "���������" ���� ����� �� �����������
;-------------------------------------------------------------------------------
; ��������� �������� null_card � in_code �����������
; Z -> ��������� ������ �����
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
