.eseg

.org 0x00
    .db __DAY__,__MONTH__,__YEAR__  ; Дата последней записи
    .db 0                           ; Счётчик записей настроек
    .db VERSION_MAJOR               ; Версия ПО
    .db (VERSION_MINOR<<4)|VERSION_MICRO

ee_cfg_start:
ee_itest_time:  .db 1               ; Время теста при вкл. (0-127 c), 0 = выкл.
ee_ctest_time:  .db 10              ; Время теста по карте (0-127 с), 0 = выкл.
ee_test_card:   .dd 0x008681B2      ; Код карты для запуска теста
ee_null_card:   .dd 0x008681B1      ; Код карты, если нет карты (0 = нет выдачи без карты)
ee_pin_pass:    .db C_2,C_2,C_2,C_2 ; PIN для состояния "Норма" (1-4 цифры)
ee_pin_fail:    .db C_2,C_2,C_2,C_7 ; PIN для состояния "Алкоголь" (1-4 цифры)
ee_pin_vip:     .db C_1,C_1,C_1,C_1 ; PIN для VIP (1-4 цифры)
ee_pin_data:    .db C_0,0,0,0       ; PIN для данных от алкотестера (1-4 цифры)
ee_v_facility:  .db 67              ; Код организации для значений
ee_v_offset:    .dw 16000           ; Смещение для значений
ee_c_facility:  .db 67              ; Код организации для состояний
ee_c_offset:    .dw 16500           ; Смещение для состояний
ee_delay1:      .db 100             ; Пауза после отправки кода карты (x2 мс)
ee_delay2:      .db 30              ; Пауза после отправки цифры (x2 мс)
ee_delay3:      .dw 1000            ; Пауза между посылками (x2 мс)
ee_relay1_time: .db 10              ; Время работы реле 1 (0-127 с), 0 = выкл.
ee_relay2_time: .db 10              ; Время работы реле 2 (0-127 с), 0 = выкл.
ee_as_timeout:  .db 36              ; Тайм-аут анализа (0-255) (x5 c), 0 = выкл.
ee_er_timeout:  .db 36              ; Тайм-аут ошибки (0-255) (x5 c), 0 = выкл.
ee_event_mask:  .db 0xFF            ; Маска выдаваемых событий алкотестера
ee_address:     .db 0               ; Адрес прибора (0-30), 0 = нет обмена по RS-485
ee_param_bits:  .db 0x01            ; Параметры алгоритма работы
ee_card_length: .db 26              ; Количество битов в кодах карт [RESERVED]
ee_key_length:  .db 8               ; Количество битов в символах клавиатуры (4-8)
ee_event_mask2: .db 0xFC            ; Маска выдаваемых событий алкотестер (байт 2)
ee_card_time:   .db 10              ; Время хранения карты (0-127 с), 0 = таймер выкл.
ee_delay4:      .dw 500             ; Пауза после отправки ENTER (x2 мс)
ee_cfg_end:

.org 0x40
ee_key_table:                       ; Таблица кодов символов клавиатуры (16 байт)
    .db C_0, C_1, C_2, C_3, C_4, C_5, C_6, C_7, C_8, C_9
    .db C_CLEAR
    .db C_ENTER
    .db 0x0C
    .db C_TAMPER
    .db 0x0E
    .db 0x0F

.org 0xFF
    .db 0                           ; Флаг защиты загрузчика

; Размер конфигурации в EEPROM
.equ EE_CFG_SIZE    = ee_cfg_end-ee_cfg_start
