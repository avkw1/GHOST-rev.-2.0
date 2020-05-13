;-------------------------------------------------------------------------------
; ��������� ���������� ����
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
; LOOPH = �������� - ����� ��������� ���� (1-126 �),
;                  - 0, ���� ��������� ����,
;                  - 127, ���� ��������� �� ������.
relay_control_proc:
    andi LOOPH,0x7F                 ; �������� ������� ��� ���������
    breq relay_off                  ; ��������� ����, ���� 0
    cpi LOOPH,0x7F                  ; �������� � 127
    brlo relay_on                   ; �������� ���� �� 1 - 126 �.
    clr LOOPL
    clr LOOPH
    rjmp relay_inf_on               ; �������� ���� �� ������
relay_off:
    ldd LOOPH,Z+PORT_B_RELAY        ; LOOPH = ��� ����
    com LOOPH
    and outputs,LOOPH               ; ��������� ����
    ret

;-------------------------------------------------------------------------------
; ��������� ��������� ����
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
; ��������� tmp3, tmp4
relay_on_proc:
    lds LOOPH,relay1_time
    cpi ZL,LOW(port1)
    breq __ronp_set_time
    lds LOOPH,relay2_time
__ronp_set_time:
    tst LOOPH                       ; ���� ����� = 0,
    breq __ronp_ret                 ; �� �� �������� ����
relay_on:
    rcall mul_500_proc              ; �������� �� 500
relay_inf_on:
    cli ;<<<<<<<<<<<<<<<<<<<<<<<<<<<< ���������� ��������� <<<<<<<<<<<<<<<<<<<<<
    std Z+PORT_RELAY_TCNTR,LOOPL    ; ������������� ��������
    std Z+PORT_RELAY_TCNTR+1,LOOPH
    ldd LOOPL,Z+PORT_B_RELAY        ; LOOPL = ��� ����
    or outputs,LOOPL                ; ���������� ��� ����
__ronp_ret:
    reti ;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

;-------------------------------------------------------------------------------
; ��������� ���������� ����
;-------------------------------------------------------------------------------
; Z -> ��������� ������ �����
; ��������� ��������, �.�. ���������� �� ����������
relay_off_proc:
    push LOOPL
    push LOOPH
    ldd LOOPH,Z+PORT_B_RELAY        ; LOOPH = ��� ����
    mov LOOPL,outputs
    and LOOPL,LOOPH                 ; ���������, �������� ���� ��� ���
    breq __rofp_exit                ; �����, ���� ���������
    ldd LOOPL,Z+PORT_RELAY_TCNTR
    ldd LOOPH,Z+PORT_RELAY_TCNTR+1
    sbiw LOOPH:LOOPL,0              ; �������� LOOP �� ����
    breq __rofp_exit                ; �����, ���� 0 (��������� ���� �� ������)
    sbiw LOOPH:LOOPL,1              ; ��������� ��������
    std Z+PORT_RELAY_TCNTR,LOOPL
    std Z+PORT_RELAY_TCNTR+1,LOOPH
    brne __rofp_exit
    ldd LOOPH,Z+PORT_B_RELAY
    eor outputs,LOOPH               ; ��������� ����
__rofp_exit:
    pop LOOPH
    pop LOOPL
    ret
