;-------------------------------------------------------------------------------
; �������� ������ �� RS-485
;-------------------------------------------------------------------------------

; ������������ ����� ������� ������ RS-485
.equ QUEUE_MAX_LENGTH   = 7
; ������ ������ � �������
.equ QUEUE_DATA_SIZE    = 7
; ������ �������� �������
.equ QUEUE_ELEM_SIZE    = QUEUE_DATA_SIZE + 1
; ������ ������� � ������
.equ QUEUE_SIZE         = QUEUE_MAX_LENGTH * QUEUE_ELEM_SIZE

; ������� ��� ���������� CRC16
.equ CRC16_POLY         = 0xA001
; ����������� ����� ������� (��� ����� RELAY)
.equ MIN_CMD_LENGTH     = 3
; ������������ ����� ������� (������ RELAY)
.equ MAX_CMD_LENGTH     = 4
; ����� ������ �� ������� QUERY
.equ ANSWER_LENGTH      = QUEUE_ELEM_SIZE + 2
; ������ ������ USART
.equ USART_BUFFER_SIZE  = ANSWER_LENGTH

; ����� ������
.equ ADDR_MASK          = 0x1F
; ����� ���� �������
.equ CMD_MASK           = 0xE0

; ���� ������
.equ CC_PING            = 0x00  ; \
.equ CC_BOOTLOADER      = 0x20  ;  \
.equ CC_RESET           = 0x40  ;   > ����� 3 �����
.equ CC_QUERY           = 0x60  ;  /
.equ CC_QACK            = 0x80  ; /
.equ CC_RELAY           = 0xA0  ; ����� 4 �����


; ��� ��������� ������ (��� ������)
.equ ANSWER_OK          = 0xA0

; ���� � ������ �� ������� QUERY
.equ QA_DATA_BIT        = 0     ; ��� ������� ������
.equ QA_TX2_BIT         = 1     ; ��� ������ �������
.equ QA_PORT_BIT        = 2     ; ��� ������ �����
.equ QA_LOSS_BIT        = 3     ; ��� ������ ������
