; Версия ПО
.equ VERSION_MAJOR      = 1
.equ VERSION_MINOR      = 9
.equ VERSION_MICRO      = 0

; Отладка
.equ DEBUG_SIM          = 0         ; Для запуска в симуляторе

; Версия печатной платы
; 0 - тестовая плата
; 1 - версия 1
; 2 - версия 2 (с 8-контактными разъемами)
.equ BOARD_REV          = 2

; Тактовая частота
.equ FOSC               = 4000000

; Скорость USART
.equ BAUDRATE           = 19200
.equ UBRR_VALUE         = FOSC/16/BAUDRATE-1

; Входы Wiegand
.equ INS_PORT           = PORTB
.equ INS_PIN            = PINB
.equ INS_DDR            = DDRB

; Переключение направления передачи RS-485
.equ DIRSW_DDR          = DDRD
.equ DIRSW_PORT         = PORTD
.equ DIRSW_BIT          = 2

; Подключение регистра 74HCT595
.equ SREG_PORT          = PORTD
.if (BOARD_REV == 0)
    .equ SREG_BIT_DATA  = 5
    .equ SREG_BIT_CLK   = 4
    .equ SREG_BIT_CP    = 3
.else
    .equ SREG_BIT_DATA  = 3
    .equ SREG_BIT_CLK   = 5
    .equ SREG_BIT_CP    = 4
.endif

; Биты входов
.if (BOARD_REV < 2)
    .equ IN1_D0         = 0
    .equ IN1_D1         = 1
    .equ IN2_D0         = 2
    .equ IN2_D1         = 3
    .equ IN3_D0         = 4
    .equ IN3_D1         = 5
    .equ IN4_D0         = 6
    .equ IN4_D1         = 7
.else
    .equ IN1_D0         = 0
    .equ IN1_D1         = 1
    .equ IN2_D0         = 7
    .equ IN2_D1         = 6
    .equ IN3_D0         = 4
    .equ IN3_D1         = 5
    .equ IN4_D0         = 3
    .equ IN4_D1         = 2
.endif

; Биты принятых кодов
.equ INC_CARD1          = 0
.equ INC_AT1            = 1
.equ INC_CARD2          = 2
.equ INC_AT2            = 3
.equ INC_RS485          = 4

; Биты во регистре 74HCT595
.equ SRB_LED1           = 0         ; Включается нулём
.equ SRB_LED2           = 1         ; Включается нулём
.equ SRB_OUT1D0         = 2
.equ SRB_OUT1D1         = 3
.equ SRB_OUT2D0         = 4
.equ SRB_OUT2D1         = 5
.equ SRB_RELAY1         = 6
.equ SRB_RELAY2         = 7

; Количество битов в кадре Wiegand
.equ W_BIT_COUNT        = 26
; Тайм-аут ожидания следующего бита (-1) (x2 мс)
.equ W_BIT_TIMEOUT      = 3         ; 4...6 мс
; Количество битов = вход выключен
.equ W_IN_DISABLED      = 0xFF

; Значения для таймера
.equ OCR1A_VALUE        = FOSC/1000*2/8-1       ; 2 мс
.equ OCR1B_VALUE        = FOSC/1000000*1800/8   ; 1800 мкс

; Делитель частоты таймера для индикации
.equ ICNTR_MAX          = 25        ; Период = 50 мс
; Количество состояний индикации
.equ LEDST_MAX          = 60        ; Период = 3 с

; Состояние выхода Wiegand
.equ OS_OFF             = 0x00      ; Выход неактивен (байт равен 0)
.equ OS_STATE_MASK      = 0x07      ; Маска кода состояния (3 бита)
.equ OS_TX2             = 7         ; Бит второй посылки

; Коды состояний конечного автомата
.equ OS_CODE            = 1         ; Выдача кода карты (26 бит)
.equ OS_DELAY1          = 2         ; Пауза после выдачи кода карты
.equ OS_DIGIT           = 3         ; Выдача цифры (8 бит)
.equ OS_DELAY2          = 4         ; Пауза после выдачи цифры
.equ OS_ENTER           = 5         ; Выдача символа ENTER (8 бит)
.equ OS_DELAY34         = 6         ; Пауза после выдачи символа ENTER
.equ OS_END             = 7         ; Завершение выдачи

; Коды символов клавиатуры (по умолчанию)
.equ C_0                = 0x60
.equ C_1                = 0xE1
.equ C_2                = 0xE2
.equ C_3                = 0x63
.equ C_4                = 0xE4
.equ C_5                = 0x65
.equ C_6                = 0x66
.equ C_7                = 0xE7
.equ C_8                = 0xE8
.equ C_9                = 0x69
.equ C_CLEAR            = 0x6A
.equ C_ENTER            = 0xEB
.equ C_TAMPER           = 0xED

; Состояния алкотестера
.equ AT_POWER_ON        = 0x01      ; Включение
.equ AT_POWER_OFF       = 0x02      ; Выключение
.equ AT_AUTO_POWER_OFF  = 0x03      ; Автовыключение
.equ AT_READY           = 0x04      ; Готов
.equ AT_ERROR           = 0x05      ; Ошибка/недостаточный выдох
.equ AT_ANALYSIS        = 0x06      ; Анализ
.equ AT_PASS            = 0x07      ; Норма
.equ AT_FAIL            = 0x08      ; Алкоголь
.equ AT_STANDBY_MODE    = 0x09      ; Режим ожидания (не реализован в алкотестере)
.equ AT_BREAKDOWN       = 0x0A      ; Неисправность (не выдаётся алкотестером)
.equ AT_TIMEOUT         = 0x0B      ; Тайм-аут карты (не выдаётся алкотестером)

; Биты маски выдаваемых событий алкотестера
.equ EM_POWER_ON        = 0
.equ EM_POWER_OFF       = 1
.equ EM_AUTO_POWER_OFF  = 2
.equ EM_ERROR           = 3
.equ EM_PASS            = 4
.equ EM_FAIL            = 5
.equ EM_STANDBY_MODE    = 6
.equ EM_BREAKDOWN       = 7

; Биты маски выдаваемых событий алкотестера (байт 2)
.equ EM2_READY          = 0
.equ EM2_ANALYSIS       = 1
.equ EM2_TIMEOUT        = 2         ; Значение бита игнорируется!
                                    ; Код состояния выдаётся, если алгоритм 2.

; Биты - параметры алгоритма работы
.equ PB_SINGLE_CARD     = 0         ; Запоминать только первую карту
.equ PB_NO_CARD         = 1         ; Не отправлять коды карт (выключение считывателей)
.equ PB_ALGORITHM_2     = 2         ; Алгоритм 2 (карта перед анализом)
.equ PB_VALUE_ONLY      = 3         ; Отправлять только значение от алкотестера,
                                    ; карта не отправляется повторно (для алгоритма 2).
; Адрес флага защиты загрузчика
.equ BOOTLDR_SFLAG_ADDRESS  = 0xFF
; Адрес для прыжка в загрузчик (метка init)
.equ BOOTLDR_JUMP_ADDRESS   = 0x714
