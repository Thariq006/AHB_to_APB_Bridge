`timescale 1ns/1ps

module tb_ahb_to_apb_bridge;

    reg HCLK;
    reg HRESETn;

    reg [31:0] HADDR;
    reg [1:0]  HTRANS;
    reg HWRITE;
    reg HSEL;
    reg HREADY;
    reg [31:0] HWDATA;

    wire [31:0] HRDATA;
    wire HREADYOUT;
    wire HRESP;

    wire [31:0] PADDR;
    wire PWRITE;
    wire PSEL;
    wire PENABLE;
    wire [31:0] PWDATA;

    reg [31:0] PRDATA;
    reg PREADY;
    reg PSLVERR;

    integer errors;

    // DUT
    ahb_to_apb_bridge DUT (

        .HCLK(HCLK),
        .HRESETn(HRESETn),

        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSEL(HSEL),
        .HREADY(HREADY),
        .HWDATA(HWDATA),

        .HRDATA(HRDATA),
        .HREADYOUT(HREADYOUT),
        .HRESP(HRESP),

        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)

    );

    // Clock generation
    initial begin

        HCLK = 0;

        forever #5 HCLK = ~HCLK;

    end

    // Reset
    task reset_system;
    begin

        HRESETn = 0;

        HSEL = 0;
        HREADY = 1;
        HTRANS = 0;
        HWRITE = 0;

        HADDR = 0;
        HWDATA = 0;

        PRDATA = 0;
        PREADY = 0;
        PSLVERR = 0;

        repeat(3) @(negedge HCLK);

        HRESETn = 1;

        @(negedge HCLK);

    end
    endtask

    // AHB write transaction
    task ahb_write;
        input [31:0] address;
        input [31:0] data;
    begin

        @(negedge HCLK);

        HSEL = 1;
        HREADY = 1;
        HTRANS = 2'b10;
        HWRITE = 1;
        HADDR = address;

        @(negedge HCLK);

        HSEL = 0;
        HTRANS = 0;
        HWDATA = data;

        // Setup phase
        if (!(PSEL && !PENABLE)) begin
            $display("FAIL: APB SETUP phase");
            errors = errors + 1;
        end

        // Access phase
        @(negedge HCLK);

        if (!(PSEL && PENABLE && PWRITE)) begin
            $display("FAIL: APB WRITE ACCESS phase");
            errors = errors + 1;
        end

        if (PADDR !== address) begin
            $display("FAIL: WRITE ADDRESS");
            errors = errors + 1;
        end

        if (PWDATA !== data) begin
            $display("FAIL: WRITE DATA");
            errors = errors + 1;
        end

        // Insert wait states
        PREADY = 0;

        repeat(2) begin

            @(negedge HCLK);

            if (!PSEL || !PENABLE) begin
                $display("FAIL: APB wait state");
                errors = errors + 1;
            end

        end

        PREADY = 1;

        @(negedge HCLK);

        PREADY = 0;

        $display("WRITE TRANSACTION COMPLETED");

    end
    endtask

    // AHB read transaction
    task ahb_read;
        input [31:0] address;
        input [31:0] read_data;
    begin

        @(negedge HCLK);

        HSEL = 1;
        HREADY = 1;
        HTRANS = 2'b10;
        HWRITE = 0;
        HADDR = address;

        @(negedge HCLK);

        HSEL = 0;
        HTRANS = 0;

        PRDATA = read_data;

        // Setup phase
        if (!(PSEL && !PENABLE)) begin
            $display("FAIL: READ SETUP");
            errors = errors + 1;
        end

        @(negedge HCLK);

        // Access phase
        if (!(PSEL && PENABLE && !PWRITE)) begin
            $display("FAIL: READ ACCESS");
            errors = errors + 1;
        end

        PREADY = 1;

        #1;

        if (HRDATA !== read_data) begin

            $display("FAIL: READ DATA Expected=%h Actual=%h",
                     read_data, HRDATA);

            errors = errors + 1;

        end

        if (HREADYOUT !== 1) begin

            $display("FAIL: READ READY");

            errors = errors + 1;

        end

        @(negedge HCLK);

        PREADY = 0;

        $display("READ TRANSACTION COMPLETED");

    end
    endtask

    // Main test
    initial begin

        errors = 0;

        $dumpfile("ahb_apb.vcd");
        $dumpvars(0, tb_ahb_to_apb_bridge);

        $display("--------------------------------");
        $display("AHB TO APB BRIDGE TEST STARTED");
        $display("--------------------------------");

        reset_system();

        // Test 1: Write
        ahb_write(32'h40000000, 32'h12345678);

        // Test 2: Read
        ahb_read(32'h40000004, 32'hAABBCCDD);

        // Test 3: Peripheral error
        @(negedge HCLK);

        HSEL = 1;
        HTRANS = 2'b10;
        HWRITE = 0;
        HADDR = 32'h40000008;
        HREADY = 1;

        @(negedge HCLK);

        HSEL = 0;
        HTRANS = 0;

        @(negedge HCLK);

        PREADY = 1;
        PSLVERR = 1;

        #1;

        if (HRESP !== 1'b1) begin

            $display("FAIL: ERROR RESPONSE");

            errors = errors + 1;

        end
        else begin

            $display("PASS: ERROR RESPONSE");

        end

        @(negedge HCLK);

        PREADY = 0;
        PSLVERR = 0;

        $display("--------------------------------");

        if (errors == 0)
            $display("ALL AHB APB TESTS PASSED");
        else
            $display("TEST FAILED: %0d ERRORS", errors);

        $display("--------------------------------");

        $finish;

    end

endmodule
