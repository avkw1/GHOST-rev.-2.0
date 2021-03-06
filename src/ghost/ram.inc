.dseg

ram_data_start:
;---------- ���� 1 -------------------------------------------------------------
port1:
; ���� 1 - �����������
in1data:        .BYTE 4             ; �������� ���� (wiegand-26)
in1cntr:        .BYTE 1             ; ������� ����� (0xFF = ���� ��������)
in1tcntr:       .BYTE 1             ; ������� ������� �� ���������� ����
in1code:        .BYTE 4             ; ���������� ��� �����
in1bit:         .BYTE 1             ; ���, ��������������� � �������� incodes
; ���� 2 - ����������
in2data:        .BYTE 4
in2cntr:        .BYTE 1
in2tcntr:       .BYTE 1
in2code:        .BYTE 4
in2bit:         .BYTE 1
; ����� 1
out1state:      .BYTE 1             ; ��������� ������
out1cntr:       .BYTE 2             ; ������� �����/������� �����
out1data:       .BYTE 4             ; ������ ��� ������/��� ����� 1
out1pin:        .BYTE 4             ; PIN 1
out1code2:      .BYTE 4             ; ��� ����� 2
out1pin2:       .BYTE 4             ; PIN 2
; ���� � ����������
relay1tcntr:    .BYTE 2             ; ������� ������� ���� 1
at1state:       .BYTE 1             ; ��������� ����������� 1
at1timer_on:    .BYTE 1             ; ������� ������ ����������� 1
at1tcntr:       .BYTE 3             ; ������� ����-���� ����������� 1
; ����
b_out1d0:       .BYTE 1
b_out1d1:       .BYTE 1
b_relay1:       .BYTE 1
b_led1:         .BYTE 1

;---------- ���� 2 -------------------------------------------------------------
port2:
; ���� 3 - �����������
in3data:        .BYTE 4
in3cntr:        .BYTE 1
in3tcntr:       .BYTE 1
in3code:        .BYTE 4
in3bit:         .BYTE 1
; ���� 4 - ����������
in4data:        .BYTE 4
in4cntr:        .BYTE 1
in4tcntr:       .BYTE 1
in4code:        .BYTE 4
in4bit:         .BYTE 1
; ����� 2
out2state:      .BYTE 1
out2cntr:       .BYTE 2
out2data:       .BYTE 4
out2pin:        .BYTE 4
out2code2:      .BYTE 4
out2pin2:       .BYTE 4
; ���� � ����������
relay2tcntr:    .BYTE 2
at2state:       .BYTE 1
at2timer_on:    .BYTE 1
at2tcntr:       .BYTE 3
; ����
b_out2d0:       .BYTE 1
b_out2d1:       .BYTE 1
b_relay2:       .BYTE 1
b_led2:         .BYTE 1

;-------------------------------------------------------------------------------
ram_data_end:
ram_cfg_start:
;---------- ������������ �� EEPROM ---------------------------------------------
itest_time:     .BYTE 1
ctest_time:     .BYTE 1
test_card:      .BYTE 4
null_card:      .BYTE 4
pin_pass:       .BYTE 4
pin_fail:       .BYTE 4
pin_vip:        .BYTE 4
pin_data:       .BYTE 4
v_facility:     .BYTE 1
v_offset:       .BYTE 2
c_facility:     .BYTE 1
c_offset:       .BYTE 2
delay1:         .BYTE 1
delay2:         .BYTE 1
delay3:         .BYTE 2
relay1_time:    .BYTE 1
relay2_time:    .BYTE 1
as_timeout:     .BYTE 1
er_timeout:     .BYTE 1
event_mask:     .BYTE 1
address:        .BYTE 1
param_bits:     .BYTE 1
card_length:    .BYTE 1
key_length:     .BYTE 1
event_mask2:    .BYTE 1
card_time:      .BYTE 1
delay4:         .BYTE 2
;-------------------------------------------------------------------------------
ram_cfg_end:

;---------- ������ (�� ����������������) ---------------------------------------
usart_buffer:   .BYTE USART_BUFFER_SIZE
out_queue:      .BYTE QUEUE_SIZE
;-------------------------------------------------------------------------------

; ������ ������ � ��� (����������)
.equ RAM_DATA_SIZE      = ram_data_end-ram_data_start

; �������� ������ ��������� �����
.equ IN_DATA            = in1data-port1
.equ IN_CNTR            = in1cntr-port1
.equ IN_TCNTR           = in1tcntr-port1
.equ IN_CODE            = in1code-port1
.equ IN_BIT             = in1bit-port1

; �������� ������ ��������� ������
.equ OUT_STATE          = 0
.equ OUT_CNTR           = out1cntr-out1state
.equ OUT_DATA           = out1data-out1state
.equ OUT_PIN            = out1pin-out1state
.equ OUT_CODE2          = out1code2-out1state
.equ OUT_PIN2           = out1pin2-out1state

; �������� ������ ��������� �����
.equ PORT_CARD_IN       = in1data-port1
.equ PORT_AT_IN         = in2data-port1
.equ PORT_OUT           = out1state-port1
.equ PORT_RELAY_TCNTR   = relay1tcntr-port1
.equ PORT_AT_STATE      = at1state-port1
.equ PORT_AT_TIMER_ON   = at1timer_on-port1
.equ PORT_AT_TCNTR      = at1tcntr-port1
.equ PORT_B_OUT_D0      = b_out1d0-port1
.equ PORT_B_OUT_D1      = b_out1d1-port1
.equ PORT_B_RELAY       = b_relay1-port1
.equ PORT_B_LED         = b_led1-port1

; ������ ��������� �����
.equ PORT_STRUCT_SIZE   = port2-port1
