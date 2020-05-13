;-------------------------------------------------------------------------------
; ��������� ���������� �����������
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
; ���������� �� ����������
led_proc:
    push tmp1
    push tmp2
    ldd tmp2,Z+PORT_B_LED           ; tmp1 = ��� ����������
    ldd tmp1,Z+PORT_OUT+OUT_STATE
    andi tmp1,OS_STATE_MASK         ; �������� ��� ���������
    breq __lp_timer_chk             ; �������, ���� ������ ���������
    cpi tmp1,OS_DELAY34
    brlo __lp_on                    ; ��������, ���� CODE, D1, DIGIT, D2, ENTER
    rjmp __lp_off                   ; ��������� �� ����� ����� D3 � D4
__lp_timer_chk:
    ldd tmp1,Z+PORT_AT_TIMER_ON     ; tmp1 = ������ ������� ��� ���
    tst tmp1                        ; ���� ������� -> �������
    breq __lp_heartbeat             ; ���� �������� -> ������������
;-------------------------------------------------------------------------------
; �������
__lp_mig:
    sbrc ledst,0                    ; \
    rjmp __lp_exit                  ;  > ���� ledst ������ 4 (������ 200 ��)
    sbrs ledst,1                    ; /
    eor outputs,tmp2                ; �������� ���� ����������
    rjmp __lp_exit
;-------------------------------------------------------------------------------
; "������������" - 50 �� ������ 3 �
__lp_heartbeat:
    tst ledst
    breq __lp_off
    cpi ledst,(LEDST_MAX-1)
    brne __lp_exit
__lp_on:
    com tmp2
    and outputs,tmp2                ; ��������� ����
    rjmp __lp_exit
__lp_off:
    or outputs,tmp2                 ; ���������� ��������
__lp_exit:
    pop tmp2
    pop tmp1
    ret
