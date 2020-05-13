.include "tn4313def.inc"
.include "config.inc"
.include "hal.inc"
.include "proto.inc"

.def out_queue_len  = r2            ; ����� ������� �� ������
.def enter          = r3            ; ��� ������� ���������� ENTER
.def polyl          = r4            ; \ 
.def polyh          = r5            ; / ������� ��� ���������� CRC16
.def r_address      = r6            ; ����� �������
.def usart_cntr     = r7            ; ������� ������ USART
.def usart_len      = r8            ; ����� ������ USART
.def icntr          = r9            ; ������� ���������� �������
.def sregdata       = r10           ; ������� �������� �� ������� ��������
.def in_old         = r11           ; ������ ��������� ������
.def in_new         = r12           ; ����� ��������� ������
.def in_tmp         = r13           ; ��������� ������� ��� ������
.def ssreg          = r14           ; ������� ��� ���������� SREG � ����������
.def zero           = r15           ; ������ ����
.def tmp1           = r16           ; \
.def tmp2           = r17           ;  \
.def tmp3           = r18           ;  / ��������� ��������
.def tmp4           = r19           ; /
.def inbits         = r20           ; ����, ���������� �� Wiegand
.def incodes        = r21           ; ���� ����, ���������� �� Wiegand
.def outputs        = r22           ; ��������� �������
.def ledst          = r23           ; ��������� ���������
.def LOOPL          = r24           ; \
.def LOOPH          = r25           ; / ������� �����

; EEPROM
.include "eeprom.inc"
; ���
.include "ram.inc"

;-------------------------------------------------------------------------------
.cseg
.if (DEBUG_SIM != 0)
    rjmp start
.else
    rjmp 0x700                      ; ������� � ����������
.endif
.org OC1Aaddr
    rjmp timer_int
.org URXCaddr
    rjmp rxc_int
.org UDREaddr
    rjmp udre_int
.org UTXCaddr
    rjmp txc_int
.org PCIBaddr
    rjmp pin_change_int
.org OC1Baddr
    rjmp timer_bit_start_int
;-------------------------------------------------------------------------------
.org 0x020
start:
.if (DEBUG_SIM != 0)
    ldi tmp1,LOW(RAMEND)
    out SPL,tmp1
    ldi tmp1,HIGH(RAMEND)
    out SPH,tmp1
.endif
;-------------------------------------------------------------------------------
; ������������� �������� zero
    clr zero
;-------------------------------------------------------------------------------
; �������� ������������ �� EEPROM
    rcall read_config_proc
;-------------------------------------------------------------------------------
; ������������� ���������
    clr out_queue_len
    ser tmp1
    mov in_new,tmp1
    clr sregdata                    ; � �������� ������ 0
    lds tmp1,event_mask
    out GPIOR0,tmp1                 ; GPIOR0 = ����� �������
    lds tmp1,event_mask2
    out GPIOR1,tmp1                 ; GPIOR1 = ����� ������� (���� 2)
    lds tmp1,address                ; ����� �������
    andi tmp1,ADDR_MASK             ; �������� ������� ����
    mov r_address,tmp1              ; ����������� ������ � �������
    lds tmp1,param_bits
    out GPIOR2,tmp1                 ; GPIOR2 = ����-��������� ���������
    sbis GPIOR2,PB_ALGORITHM_2      ; \ ���� �������� 2 �� ������ (= 0),
    cbi GPIOR2,PB_VALUE_ONLY        ; / �������� ��� �������� ������ ��������.
    ldi tmp1,LOW(CRC16_POLY)
    mov polyl,tmp1
    ldi tmp1,HIGH(CRC16_POLY)
    mov polyh,tmp1
;-------------------------------------------------------------------------------
; ������������� ���������
    INIT_MCU
    INIT_TIMER
    INIT_USART
;-------------------------------------------------------------------------------
; ���� ��������� � ����
    lds LOOPH,itest_time            ; ����� ����� ��� ��������� �������
test:
    tst LOOPH
.if (DEBUG_SIM != 0)
    rjmp test_end
.else
    breq test_end
.endif
    rcall mul_500_proc              ; LOOPH:LOOPL = ����� ���������� �������
    ldi outputs,(1<<SRB_RELAY1)|(1<<SRB_RELAY2)
    rcall sreg_output_proc          ; ���. ���������� � ����
    TIMER_RESET                     ; ����� ������� ��� ������� �������
test_delay_lp:
    TIMER_WAIT                      ; �������� �������
    sbiw LOOPH:LOOPL,1
    brne test_delay_lp
test_end:
    ldi outputs,(1<<SRB_LED1)|(1<<SRB_LED2)
    rcall sreg_output_proc          ; ����. ���������� � ����
;-------------------------------------------------------------------------------
; ������� ���������� � ���
    ldi XL,LOW(ram_data_start)
    ldi XH,HIGH(ram_data_start)
    ldi LOOPL,RAM_DATA_SIZE
ram_clr_lp:
    st X+,zero
    dec LOOPL
    brne ram_clr_lp
;-------------------------------------------------------------------------------
; ������� ��������� ���������
    clr inbits
    clr incodes
    clr icntr
    clr ledst
;-------------------------------------------------------------------------------
; ������������� ������
    ldi ZL,LOW(port1)
    ldi ZH,HIGH(port1)
    rcall port_init_proc
    ldi tmp1,(1<<INC_CARD1)
    std Z+PORT_CARD_IN+IN_BIT,tmp1
    ldi tmp1,(1<<INC_AT1)
    std Z+PORT_AT_IN+IN_BIT,tmp1
    ldi tmp1,(1<<SRB_OUT1D0)
    std Z+PORT_B_OUT_D0,tmp1
    ldi tmp1,(1<<SRB_OUT1D1)
    std Z+PORT_B_OUT_D1,tmp1
    ldi tmp1,(1<<SRB_RELAY1)
    std Z+PORT_B_RELAY,tmp1
    ldi tmp1,(1<<SRB_LED1)
    std Z+PORT_B_LED,tmp1
    adiw ZH:ZL,PORT_STRUCT_SIZE
    rcall port_init_proc
    ldi tmp1,(1<<INC_CARD2)
    std Z+PORT_CARD_IN+IN_BIT,tmp1
    ldi tmp1,(1<<INC_AT2)
    std Z+PORT_AT_IN+IN_BIT,tmp1
    ldi tmp1,(1<<SRB_OUT2D0)
    std Z+PORT_B_OUT_D0,tmp1
    ldi tmp1,(1<<SRB_OUT2D1)
    std Z+PORT_B_OUT_D1,tmp1
    ldi tmp1,(1<<SRB_RELAY2)
    std Z+PORT_B_RELAY,tmp1
    ldi tmp1,(1<<SRB_LED2)
    std Z+PORT_B_LED,tmp1

    sei ;>>>>>>>>>>>>>>>>>>>>>>>>>>>> ��������� ���������� >>>>>>>>>>>>>>>>>>>>>

main_loop:
    sleep
    tst inbits
    breq in_codes

;-------------------------------------------------------------------------------
; ��������� ���������� �����
in_bit0:
    ldi ZL,LOW(in1data)             ; ���� 1
    ldi ZH,HIGH(in1data)
    sbrs inbits,IN1_D0              ; ��������� ��� D0
    rjmp in_bit1
    cbr inbits,(1<<IN1_D0)          ; �������� ��� D0
    rcall input_bit_0_proc          ; �������� 0 � ������ ����� 1
in_bit1:
    sbrs inbits,IN1_D1              ; ��������� ��� D1
    rjmp in_bit2
    cbr inbits,(1<<IN1_D1)          ; �������� ��� D1
    rcall input_bit_1_proc          ; �������� 1 � ������ ����� 1
in_bit2:
    adiw ZH:ZL,(in2data-in1data)    ; ���� 2
    sbrs inbits,IN2_D0
    rjmp in_bit3
    cbr inbits,(1<<IN2_D0)
    rcall input_bit_0_proc
in_bit3:
    sbrs inbits,IN2_D1
    rjmp in_bit4
    cbr inbits,(1<<IN2_D1)
    rcall input_bit_1_proc
in_bit4:
    adiw ZH:ZL,(in3data-in2data)    ; ���� 3
    sbrs inbits,IN3_D0
    rjmp in_bit5
    cbr inbits,(1<<IN3_D0)
    rcall input_bit_0_proc
in_bit5:
    sbrs inbits,IN3_D1
    rjmp in_bit6
    cbr inbits,(1<<IN3_D1)
    rcall input_bit_1_proc
in_bit6:
    adiw ZH:ZL,(in4data-in3data)    ; ���� 4
    sbrs inbits,IN4_D0
    rjmp in_bit7
    cbr inbits,(1<<IN4_D0)
    rcall input_bit_0_proc
in_bit7:
    sbrs inbits,IN4_D1
    rjmp in_codes
    cbr inbits,(1<<IN4_D1)
    rcall input_bit_1_proc

;-------------------------------------------------------------------------------
; ��������� ���������� �����
in_codes:
    tst incodes                     ; ���� ��� �������� �����,
    breq main_loop                  ; ������� � ������ ��������� �����

in_code_rs485:
    sbrs incodes,INC_RS485
    rjmp in_code_c1
    cbr incodes,(1<<INC_RS485)
    rcall process_cmd_proc          ; ���������� ������� ��������� RS-485
in_code_c1:
    ldi ZL,LOW(port1)
    ldi ZH,HIGH(port1)
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = ��������� ������ 1
    tst tmp1                        ; ���� ������ ������ �������,
    brne in_code_c2                 ; �� �������� ��������� �������� �����.
    sbrs incodes,INC_CARD1          ; ��������� ���
    rjmp in_code_at1
    cbr incodes,(1<<INC_CARD1)      ; �������� ���
    rcall card_code_proc            ; ���������� ��� �����
in_code_at1:
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = ��������� ������ 1
    tst tmp1                        ; ���� ������ ������ �������,
    brne in_code_c2                 ; �� �������� ��������� �������� �����.
    sbrs incodes,INC_AT1
    rjmp in_code_c2
    cbr incodes,(1<<INC_AT1)
    rcall alcotester_code_proc      ; ���������� ������ �� �����������
in_code_c2:
    adiw ZH:ZL,PORT_STRUCT_SIZE
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = ��������� ������ 2
    tst tmp1                        ; ���� ������ ������ �������,
    brne rjmp_main_loop             ; �� �������� ��������� �������� �����.
    sbrs incodes,INC_CARD2
    rjmp in_code_at2
    cbr incodes,(1<<INC_CARD2)
    rcall card_code_proc            ; ���������� ��� �����
in_code_at2:
    ldd tmp1,Z+PORT_OUT+OUT_STATE   ; tmp1 = ��������� ������ 2
    tst tmp1                        ; ���� ������ ������ �������,
    brne rjmp_main_loop             ; �� �������� ��������� �������� �����.
    sbrs incodes,INC_AT2
    rjmp main_loop
    cbr incodes,(1<<INC_AT2)
    rcall alcotester_code_proc      ; ���������� ������ �� �����������
rjmp_main_loop:
    rjmp main_loop

;-------------------------------------------------------------------------------
; ���������� �� �������
;-------------------------------------------------------------------------------
timer_int:
    push ssreg
    in ssreg,SREG
    sei ;>>>>>>>>>>>>>>>>>>>>>>>>>>>> ��������� ��������� ���������� >>>>>>>>>>>
    push ZL
    push ZH
    cbr outputs,(1<<SRB_OUT1D0)|(1<<SRB_OUT1D1)|(1<<SRB_OUT2D0)|(1<<SRB_OUT2D1)
    rcall sreg_output_proc          ; ����� ��������� D0 � D1 �� ����� �������
    ; ���� 1
    ldi ZL,LOW(port1)
    ldi ZH,HIGH(port1)
    rcall input_timeout_proc        ; �������� ����-���� ����� 1
    rcall at_timeout_proc           ; �������� ����-���� ����������� 1
    rcall output_proc               ; ��������� ������ 1
    rcall relay_off_proc            ; ��������� ���������� ���� 1
    adiw ZH:ZL,(in2data-port1)
    rcall input_timeout_proc        ; �������� ����-���� ����� 2
    ; ���� 2
    adiw ZH:ZL,(port2-in2data)
    rcall input_timeout_proc        ; �������� ����-���� ����� 3
    rcall at_timeout_proc           ; �������� ����-���� ����������� 2
    rcall output_proc               ; ��������� ������ 2
    rcall relay_off_proc            ; ��������� ���������� ���� 2
    adiw ZH:ZL,(in4data-port2)
    rcall input_timeout_proc        ; �������� ����-���� ����� 4
    ; ���������
    inc icntr                       ; icntr++
    ldi ZL,ICNTR_MAX
    cp icntr,ZL
    brlo __t2mi_exit
    clr icntr                       ; icntr = 0
    inc ledst                       ; ledst++
    cpi ledst,LEDST_MAX
    brlo __t2mi_leds
    clr ledst                       ; ledst = 0
__t2mi_leds:
    ldi ZL,LOW(port1)
    ldi ZH,HIGH(port1)
    rcall led_proc                  ; ��������� 1
    adiw ZH:ZL,PORT_STRUCT_SIZE
    rcall led_proc                  ; ��������� 2
__t2mi_exit:
    pop ZH
    pop ZL
    out SREG,ssreg
    pop ssreg
    reti

;-------------------------------------------------------------------------------
; ��������� ������ � �����������
;-------------------------------------------------------------------------------
.include "eeprom.asm"
.include "inputs.asm"
.include "logic.asm"
.include "timer.asm"
.include "outputs.asm"
.include "relay.asm"
.include "leds.asm"
.include "rs485.asm"
.include "proto.asm"
.include "out_queue.asm"
.include "util.asm"

;-------------------------------------------------------------------------------
; ���������
;-------------------------------------------------------------------------------
.if (BOARD_REV == 0)
    .include "tbootloader_ghost_tb.inc"
.else
    .include "tbootloader_ghost.inc"
.endif

.exit
