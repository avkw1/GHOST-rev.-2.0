;-------------------------------------------------------------------------------
; ��������� �� 500
;-------------------------------------------------------------------------------
; ����: LOOPH = �������� (0-127)
; �����: LOOPH:LOOPL = ���������
mul_500_proc:
    clr LOOPL
    lsl LOOPH                       ; LOOPH:LOOPL = value x 512
    mov tmp1,LOOPH
    clr tmp2
    lsl tmp1
    rol tmp2                        ; tmp2:tmp1 = value x 4
    sub LOOPL,tmp1
    sbc LOOPH,tmp2                  ; LOOPH:LOOPL = value x 508
    lsl tmp1
    rol tmp2                        ; tmp2:tmp1 = value x 8
    sub LOOPL,tmp1
    sbc LOOPH,tmp2                  ; LOOPH:LOOPL = value x 500
    ret

;-------------------------------------------------------------------------------
; ����� 24-������� �������� �� 1 ��� �����
;-------------------------------------------------------------------------------
; tmp3:tmp2:tmp1 = ��������
lsl_24_proc:
    lsl tmp1
    rol tmp2
    rol tmp3
    ret

;-------------------------------------------------------------------------------
; �������� 24-������ ��������
;-------------------------------------------------------------------------------
; tmp4:LOOPH:LOOPL = �������� 1 � �����
; tmp3:tmp2:tmp1 = �������� 2
add_24_proc:
    add LOOPL,tmp1
    adc LOOPH,tmp2
    adc tmp4,tmp3
    ret

;-------------------------------------------------------------------------------
; ��������� ������ ����� 32-������� ��������
;-------------------------------------------------------------------------------
; tmp4:tmp3:tmp2:tmp1 = ��������
; LOOPL = ���������� �������
lsl_32_proc:
    lsl tmp1
    rol tmp2
    rol tmp3
    rol tmp4
    dec LOOPL
    brne lsl_32_proc
    ret

;-------------------------------------------------------------------------------
; ��������� ����������� ������
;-------------------------------------------------------------------------------
; X -> �����
; Y -> ������ ��� �����������
; LOOPL = ���������� ������
memcpy:
    ld tmp1,Y+
    st X+,tmp1
    dec LOOPL
    brne memcpy
    ret
