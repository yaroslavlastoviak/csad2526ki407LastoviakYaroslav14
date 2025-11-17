module i2c_tx #(
    // Дільник системної частоти для отримання частоти SCL.
    // Формула: CLK_DIV = (System_CLK_Freq / I2C_SCL_Freq) / 2
    // Наприклад, для 50 MHz clk та 100 kHz SCL: (50,000,000 / 100,000) / 2 = 250
    parameter CLK_DIV = 250
)(
    // --- Порти ---
    input  wire        clk,       // Системний тактовий сигнал
    input  wire        rstn,      // Сигнал асинхронного скидання (активний низький)
    input  wire        start_tx,  // Запустити передачу (один імпульс)
    input  wire [6:0]  addr,      // 7-бітна адреса Slave
    input  wire [7:0]  data_in,   // 8-бітні дані для передачі
    output reg         busy,      // Вихідний прапор, '1' коли транзакція активна
    output reg         ack_error, // '1' якщо Slave не відповів (NACK)
    output reg         done,      // '1' на один такт, коли транзакція успішно завершена
    inout  wire        sda,       // Лінія даних I2C
    output reg         scl        // Лінія тактування I2C
);

    // --- Внутрішні сигнали для керування лінією SDA ---
    reg sda_o;  // Регістр для керування виходом SDA
    reg sda_oe; // Регістр для ввімкнення/вимкнення виходу SDA (Output Enable)
    // sda_oe=1 -> Master керує лінією; sda_oe=0 -> Master "відпускає" лінію (Hi-Z)
    assign sda = sda_oe ? sda_o : 1'bz;
    wire sda_i = sda; // Вхідний сигнал з лінії SDA

    // --- FSM стани ---
    localparam IDLE       = 4'd0;
    localparam START_A    = 4'd1;
    localparam START_B    = 4'd2;
    localparam SEND_BYTE  = 4'd3;
    localparam WAIT_ACK   = 4'd4;
    localparam STOP_A     = 4'd5;
    localparam STOP_B     = 4'd6;
    localparam STOP_C     = 4'd7;

    // --- Регістри FSM та лічильники ---
    reg [3:0] state, next_state;   // Поточний та наступний стани FSM
    reg [15:0] clk_cnt;            // Лічильник для дільника частоти SCL
    reg [3:0] bit_cnt;             // Лічильник переданих біт
    reg [7:0] shift_reg;           // Регістр зсуву для адреси та даних
    reg send_data_stage;           // '0' - відправляємо адресу, '1' - відправляємо дані

    // ========================================================================
    // --- Генератор тактового сигналу SCL ---
    // ========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_cnt <= 0;
            scl <= 1;
        end else begin
            if (state == IDLE) begin
                clk_cnt <= 0;
                scl <= 1; // У стані спокою SCL завжди високий
            end else begin
                // Лічильник генерує меандр (50% заповнення) для SCL
                if (clk_cnt == (CLK_DIV * 2) - 1) begin
                    clk_cnt <= 0;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end

                if (clk_cnt >= CLK_DIV) begin
                    scl <= 0; // Друга половина періоду - SCL низький
                end else begin
                    scl <= 1; // Перша половина періоду - SCL високий
                end
            end
        end
    end

    // ========================================================================
    // --- Основна логіка FSM та керування сигналами ---
    // ========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Скидання всіх регістрів
            state <= IDLE;
            busy <= 0;
            done <= 0;
            ack_error <= 0;
            sda_o <= 1;
            sda_oe <= 1;
            bit_cnt <= 0;
            shift_reg <= 0;
            send_data_stage <= 0;
        end else begin
            // За замовчуванням вимикаємо 'done' після одного такту
            if (done) done <= 0;

            state <= next_state; // Оновлюємо стан

            // Послідовна логіка, що виконується в кожному стані
            case (state)
                IDLE: begin
                    if (start_tx) begin
                        busy <= 1;
                        ack_error <= 0;
                        // Завантажуємо адресу та біт запису (0) у регістр зсуву
                        shift_reg <= {addr, 1'b0};
                        bit_cnt <= 8;
                        send_data_stage <= 0; // Починаємо з відправки адреси
                    end
                end

                START_A: begin
                    sda_o <= 0; // SCL високий, SDA опускаємо -> START condition
                end

                START_B: begin
                    // Тримаємо SDA низьким, SCL опускається. Готові до передачі біт.
                end

                SEND_BYTE: begin
                    // Коли SCL низький, виставляємо наступний біт на SDA
                    if (scl == 0) begin
                        sda_o <= shift_reg[7];
                        if (bit_cnt > 0) begin
                            shift_reg <= shift_reg << 1;
                            bit_cnt <= bit_cnt - 1;
                        end
                    end
                end

                WAIT_ACK: begin
                    sda_oe <= 0; // Відпускаємо SDA, щоб Slave міг надіслати ACK
                    if (scl == 1) begin
                        if (sda_i == 1'b1) begin // '1' означає NACK
                            ack_error <= 1;
                        end
                    end
                end

                STOP_A: begin
                    sda_oe <= 1;
                    sda_o <= 0; // SCL низький, SDA опускаємо. Підготовка до STOP.
                end

                STOP_B: begin
                    // SCL піднімається до '1'
                end

                STOP_C: begin
                    sda_o <= 1; // SCL високий, SDA піднімаємо -> STOP condition
                    busy <= 0;
                    if (!ack_error) done <= 1; // Сигнал про успішне завершення
                end
            endcase
        end
    end

    // --- Комбінаційна логіка для переходів FSM ---
    always @(*) begin
        next_state = state; // За замовчуванням залишаємось у поточному стані
        case (state)
            IDLE: if (start_tx) next_state = START_A;
            START_A: if (scl == 1) next_state = START_B;
            START_B: if (scl == 0) next_state = SEND_BYTE;
            SEND_BYTE: if (bit_cnt == 0 && scl == 1) next_state = WAIT_ACK;
            WAIT_ACK: begin
                if (scl == 0) begin
                    if (ack_error) begin
                        next_state = STOP_A;
                    end else if (send_data_stage == 0) begin
                        // Адресу відправлено, готуємось відправляти дані
                        next_state = SEND_BYTE;
                        bit_cnt = 8;
                        shift_reg = data_in;
                        send_data_stage = 1;
                        sda_oe = 1; // Master знову бере контроль над SDA
                    end else begin
                        // Дані відправлено, завершуємо транзакцію
                        next_state = STOP_A;
                    end
                end
            end
            STOP_A: if (scl == 0) next_state = STOP_B;
            STOP_B: if (scl == 1) next_state = STOP_C;
            STOP_C: next_state = IDLE;
        endcase
    end
endmodule
