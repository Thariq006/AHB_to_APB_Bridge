
`timescale 1ns/1ps

module ahb_to_apb_bridge (
    input  wire        HCLK,
    input  wire        HRESETn,

    // AHB-Lite Interface
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire        HSEL,
    input  wire        HREADY,
    input  wire [31:0] HWDATA,

    output reg  [31:0] HRDATA,
    output reg         HREADYOUT,
    output reg         HRESP,

    // APB Interface
    output reg  [31:0] PADDR,
    output reg         PWRITE,
    output reg         PSEL,
    output reg         PENABLE,
    output reg  [31:0] PWDATA,

    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR
);

    // FSM State Encoding
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg [1:0] state;

    // Internal Registers
    reg [31:0] addr_reg;
    reg [31:0] wdata_reg;
    reg        write_reg;

    // FSM Sequential Logic
    always @(posedge HCLK or negedge HRESETn) begin

        if (!HRESETn) begin

            state     <= IDLE;
            addr_reg  <= 32'b0;
            wdata_reg <= 32'b0;
            write_reg <= 1'b0;

        end

        else begin

            case (state)

                // IDLE State
                IDLE: begin

                    if (HSEL && HREADY && HTRANS[1]) begin

                        addr_reg  <= HADDR;
                        write_reg <= HWRITE;

                        state <= SETUP;

                    end

                end

                // APB SETUP State
                SETUP: begin

                    if (write_reg)
                        wdata_reg <= HWDATA;

                    state <= ACCESS;

                end

                // APB ACCESS State
                ACCESS: begin

                    if (PREADY) begin

                        state <= IDLE;

                    end

                end

                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

    // APB and AHB Output Logic
    always @(*) begin

        // Default Outputs
        PADDR     = addr_reg;
        PWRITE    = write_reg;
        PWDATA    = wdata_reg;

        PSEL      = 1'b0;
        PENABLE   = 1'b0;

        HRDATA    = 32'b0;
        HREADYOUT = 1'b1;
        HRESP     = 1'b0;

        case (state)

            // IDLE
            IDLE: begin

                HREADYOUT = 1'b1;

            end

            // SETUP
            SETUP: begin

                PSEL      = 1'b1;
                PENABLE   = 1'b0;

                // Stall AHB while bridge prepares APB transfer
                HREADYOUT = 1'b0;

            end

            // ACCESS
            ACCESS: begin

                PSEL      = 1'b1;
                PENABLE   = 1'b1;

                // Wait until APB peripheral is ready
                HREADYOUT = PREADY;

                if (PREADY) begin

                    HRDATA = PRDATA;
                    HRESP  = PSLVERR;

                end

            end

            default: begin

                HREADYOUT = 1'b1;

            end

        endcase

    end

endmodule

