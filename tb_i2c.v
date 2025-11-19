`timescale 1ns/1ps
module tb_i2c;

    // --- Сигнали для тестування ---
    reg clk;
    reg rstn;
    reg start_tx;
    reg [6:0] addr;
    reg [7:0] data_in;
    wire sda;
    wire scl;
    wire busy;
    wire ack_error;
    wire done;

    // --- Адреса Slave, яка буде використовуватись у тесті ---
    localparam SLAVE_ADDR = 7'h42;

    // --- Інстанціювання Master модуля ---
    // Частота CLK = 100MHz (період 10нс).
    // Частота SCL = 100kHz.
    // CLK_DIV = (100,000,000 / 100,000) / 2 = 500
    i2c_tx #(.CLK_DIV(500)) master (
        .clk(clk),
        .rstn(rstn),
        .start_tx(start_tx),
        .addr(addr),
        .data_in(data_in),
        .busy(busy),
        .ack_error(ack_error),
        .done(done),
        .sda(sda),
        .scl(scl)
    );

    // --- Інстанціювання Slave модуля ---
    i2c_rx slave (
        .clk(clk),
        .rstn(rstn),
        .sda(sda),
        .scl(scl),
        .my_addr(SLAVE_ADDR)
    );

    // --- Генератор тактового сигналу (100 MHz) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Основний сценарій тестування ---
    initial begin
        // 1. Ініціалізація та скидання
        rstn = 1;
        start_tx = 0;
        addr = SLAVE_ADDR;
        data_in = 8'hA5;
        #20;
        rstn = 0; // Активуємо reset
        #100;
        rstn = 1; // Деактивуємо reset
        #200;

        // 2. Запуск транзакції
        $display("TEST: Starting I2C transaction...");
        start_tx = 1;
        #10; // Тривалість імпульсу start_tx - один такт clk
        start_tx = 0;

        // 3. Очікування завершення
        wait(done == 1);
        $display("TEST: Transaction complete. Done signal received.");
        $display("TEST: Final status: busy = %b, ack_error = %b", busy, ack_error);
        #200;

        // 4. Завершення симуляції
        $finish;
    end

endmodule
