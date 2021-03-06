.eseg

.org 0x00
    .db __DAY__,__MONTH__,__YEAR__  ; ���� ��������� ������
    .db 0                           ; ������� ������� ��������
    .db VERSION_MAJOR               ; ������ ��
    .db (VERSION_MINOR<<4)|VERSION_MICRO

ee_cfg_start:
ee_itest_time:  .db 1               ; ����� ����� ��� ���. (0-127 c), 0 = ����.
ee_ctest_time:  .db 10              ; ����� ����� �� ����� (0-127 �), 0 = ����.
ee_test_card:   .dd 0x008681B2      ; ��� ����� ��� ������� �����
ee_null_card:   .dd 0x008681B1      ; ��� �����, ���� ��� ����� (0 = ��� ������ ��� �����)
ee_pin_pass:    .db C_2,C_2,C_2,C_2 ; PIN ��� ��������� "�����" (1-4 �����)
ee_pin_fail:    .db C_2,C_2,C_2,C_7 ; PIN ��� ��������� "��������" (1-4 �����)
ee_pin_vip:     .db C_1,C_1,C_1,C_1 ; PIN ��� VIP (1-4 �����)
ee_pin_data:    .db C_0,0,0,0       ; PIN ��� ������ �� ����������� (1-4 �����)
ee_v_facility:  .db 67              ; ��� ����������� ��� ��������
ee_v_offset:    .dw 16000           ; �������� ��� ��������
ee_c_facility:  .db 67              ; ��� ����������� ��� ���������
ee_c_offset:    .dw 16500           ; �������� ��� ���������
ee_delay1:      .db 100             ; ����� ����� �������� ���� ����� (x2 ��)
ee_delay2:      .db 30              ; ����� ����� �������� ����� (x2 ��)
ee_delay3:      .dw 1000            ; ����� ����� ��������� (x2 ��)
ee_relay1_time: .db 10              ; ����� ������ ���� 1 (0-127 �), 0 = ����.
ee_relay2_time: .db 10              ; ����� ������ ���� 2 (0-127 �), 0 = ����.
ee_as_timeout:  .db 36              ; ����-��� ������� (0-255) (x5 c), 0 = ����.
ee_er_timeout:  .db 36              ; ����-��� ������ (0-255) (x5 c), 0 = ����.
ee_event_mask:  .db 0xFF            ; ����� ���������� ������� �����������
ee_address:     .db 0               ; ����� ������� (0-30), 0 = ��� ������ �� RS-485
ee_param_bits:  .db 0x01            ; ��������� ��������� ������
ee_card_length: .db 26              ; ���������� ����� � ����� ���� [RESERVED]
ee_key_length:  .db 8               ; ���������� ����� � �������� ���������� (4-8)
ee_event_mask2: .db 0xFC            ; ����� ���������� ������� ���������� (���� 2)
ee_card_time:   .db 10              ; ����� �������� ����� (0-127 �), 0 = ������ ����.
ee_delay4:      .dw 500             ; ����� ����� �������� ENTER (x2 ��)
ee_cfg_end:

.org 0x40
ee_key_table:                       ; ������� ����� �������� ���������� (16 ����)
    .db C_0, C_1, C_2, C_3, C_4, C_5, C_6, C_7, C_8, C_9
    .db C_CLEAR
    .db C_ENTER
    .db 0x0C
    .db C_TAMPER
    .db 0x0E
    .db 0x0F

.org 0xFF
    .db 0                           ; ���� ������ ����������

; ������ ������������ � EEPROM
.equ EE_CFG_SIZE    = ee_cfg_end-ee_cfg_start
