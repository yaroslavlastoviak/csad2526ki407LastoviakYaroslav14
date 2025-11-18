module i2c_rx(
    input  wire       clk,       // Системний тактовий сигнал
    input  wire       rstn,      // Сигнал скидання (активний низький)
    inout  wire       sda,       // Лінія даних I2C
    input  wire       scl,       // Лінія тактування I2C
    input  wire [6:0] my_addr    // Власна 7-бітна адреса цього пристрою
);

    // --- Регістри для синхронізації та керування SDA ---
    reg  sda_o;
    reg  sda_oe;
    assign sda = sda_oe ? sda_o : 1'bz;

    // --- Синхронізація вхідних сигналів для уникнення метастабільності ---
    reg sda_sync, scl_sync;
    reg sda_d1, scl_d1;
    always @(posedge clk) begin
        sda_d1 <= sda; sda_sync <= sda_d1;
        scl_d1 <= scl; scl_sync <= scl_d1;
    end

    // --- Детектор фронтів SCL та умов START/STOP ---
    wire scl_rising_edge = scl_sync && !scl_d1;
    wire scl_falling_edge = !scl_sync && scl_d1;
    wire start_condition = scl_sync && (sda_d1 && !sda_sync);
    wire stop_condition = scl_sync && (!sda_d1 && sda_sync);

    // --- Внутрішні регістри стану ---
    reg [3:0] bit_cnt;      // Лічильник біт (для прийому 8 біт)
    reg [7:0] shift_reg;    // Регістр зсуву для прийому даних
    reg active;             // Прапор, що вказує на активну транзакцію
    reg addr_match;         // Прапор, що вказує на збіг адреси

    // --- Основна логіка Slave ---
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Скидання всіх станів
            bit_cnt <= 0;
            shift_reg <= 0;
            active <= 0;
            addr_match <= 0;
            sda_oe <= 0; // Відпустити шину
        end else begin
            // --- Логіка START/STOP ---
            if (start_condition) begin
                active <= 1;
                addr_match <= 0;
                bit_cnt <= 8; // Готуємось приймати 8 біт (адреса + R/W)
            end
            if (stop_condition) begin
                active <= 0;
                addr_match <= 0;
                sda_oe <= 0; // Завжди відпускаємо шину після STOP
            end

            if (active) begin
                // --- Логіка прийому даних ---
                if (scl_rising_edge) begin
                    if (bit_cnt > 0) begin
                        shift_reg <= {shift_reg[6:0], sda_sync};
                        bit_cnt <= bit_cnt - 1;
                    end
                end

                // --- Логіка відправки ACK ---
                if (scl_falling_edge) begin
                    if (bit_cnt == 0) begin
                        // 8 біт отримано, час надсилати ACK/NACK
                        if (!addr_match) begin // Це була адреса
                            if (shift_reg[7:1] == my_addr) begin
                                addr_match <= 1;
                                sda_o <= 0; // Готуємо ACK (тягнемо SDA до 0)
                                sda_oe <= 1;
                            end
                            bit_cnt <= 8; // Готуємось до наступного байта
                        end else begin // Це були дані
                            // Ми отримали байт даних, відправляємо ACK
                            sda_o <= 0;
                            sda_oe <= 1;
                            bit_cnt <= 8;
                        end
                    end else if (sda_oe) begin
                        // Якщо ми відправляли ACK, відпускаємо шину після одного такту
                        sda_oe <= 0;
                    end
                end
            end
        end
    end
endmodule
