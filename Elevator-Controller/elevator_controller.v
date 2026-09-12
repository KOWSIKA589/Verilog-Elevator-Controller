//==============================================================
// 8-FLOOR LIFT / ELEVATOR CONTROLLER
// Floors: 0 to 7
//==============================================================

module Lift8 (
    input  logic       clk,
    input  logic       reset,
    input  logic [2:0] req_floor,
    input  logic       emergency_stop,

    output logic       idle,
    output logic       door,
    output logic       Up,
    output logic       Down,
    output logic [2:0] current_floor,
    output logic [7:0] requests,
    output logic [2:0] max_request,
    output logic [2:0] min_request
);

    //==========================================================
    // Internal variables
    //==========================================================

    logic emergency_stopped;
    logic request_received;

    //==========================================================
    // REQUEST HANDLING
    // A new floor request is stored in the request register.
    //==========================================================

    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            requests <= 8'b00000000;
        end
        else
        begin
            // Store requested floor
            requests[req_floor] <= 1'b1;

            // Clear request after reaching that floor
            if (requests[current_floor])
                requests[current_floor] <= 1'b0;
        end
    end

    //==========================================================
    // FIND MINIMUM AND MAXIMUM REQUESTED FLOORS
    //==========================================================

    integer i;

    always @(*)
    begin
        max_request = current_floor;
        min_request = current_floor;

        for (i = 0; i < 8; i = i + 1)
        begin
            if (requests[i])
            begin
                if (i > max_request)
                    max_request = i;

                if (i < min_request)
                    min_request = i;
            end
        end
    end

    //==========================================================
    // MAIN LIFT CONTROLLER
    //==========================================================

    always @(posedge clk or posedge reset)
    begin
        if (reset)
        begin
            current_floor     <= 3'b000;
            idle              <= 1'b1;
            door              <= 1'b0;
            Up                <= 1'b1;
            Down              <= 1'b0;
            emergency_stopped <= 1'b0;
            request_received  <= 1'b0;
        end

        //======================================================
        // EMERGENCY STOP
        //======================================================

        else if (emergency_stop)
        begin
            emergency_stopped <= 1'b1;
            idle              <= 1'b1;
            door              <= 1'b0;
            Up                <= 1'b0;
            Down              <= 1'b0;
        end

        //======================================================
        // EMERGENCY RELEASE
        //======================================================

        else if (emergency_stopped)
        begin
            emergency_stopped <= 1'b0;

            // Resume based on pending requests
            if (requests != 8'b00000000)
            begin
                idle <= 1'b0;
            end
            else
            begin
                idle <= 1'b1;
            end
        end

        //======================================================
        // NORMAL OPERATION
        //======================================================

        else
        begin

            // Door closes after one clock cycle
            if (door)
            begin
                door <= 1'b0;
            end

            //==================================================
            // CURRENT FLOOR HAS A REQUEST
            //==================================================

            if (requests[current_floor])
            begin
                idle <= 1'b1;
                door <= 1'b1;

                // Decide direction for next request
                if (max_request > current_floor)
                begin
                    Up   <= 1'b1;
                    Down <= 1'b0;
                end
                else if (min_request < current_floor)
                begin
                    Up   <= 1'b0;
                    Down <= 1'b1;
                end
                else
                begin
                    Up   <= 1'b0;
                    Down <= 1'b0;
                end
            end

            //==================================================
            // MOVE UP
            //==================================================

            else if (max_request > current_floor)
            begin
                if (current_floor < 3'b111)
                begin
                    current_floor <= current_floor + 1'b1;
                    idle <= 1'b0;
                    door <= 1'b0;
                    Up   <= 1'b1;
                    Down <= 1'b0;
                end
            end

            //==================================================
            // MOVE DOWN
            //==================================================

            else if (min_request < current_floor)
            begin
                if (current_floor > 3'b000)
                begin
                    current_floor <= current_floor - 1'b1;
                    idle <= 1'b0;
                    door <= 1'b0;
                    Up   <= 1'b0;
                    Down <= 1'b1;
                end
            end

            //==================================================
            // NO REQUEST
            //==================================================

            else
            begin
                current_floor <= current_floor;
                idle <= 1'b1;
                Up   <= 1'b0;
                Down <= 1'b0;
            end
        end
    end

endmodule


//================================================================
// TESTBENCH
//================================================================

module Lift8_Tb;

    logic clk;
    logic reset;
    logic [2:0] req_floor;
    logic emergency_stop;

    logic idle;
    logic door;
    logic Up;
    logic Down;

    logic [2:0] current_floor;
    logic [7:0] requests;
    logic [2:0] max_request;
    logic [2:0] min_request;

    //============================================================
    // DUT - Device Under Test
    //============================================================

    Lift8 dut (
        .clk(clk),
        .reset(reset),
        .req_floor(req_floor),
        .emergency_stop(emergency_stop),

        .idle(idle),
        .door(door),
        .Up(Up),
        .Down(Down),
        .current_floor(current_floor),
        .requests(requests),
        .max_request(max_request),
        .min_request(min_request)
    );

    //============================================================
    // CLOCK GENERATION
    //============================================================

    initial
    begin
        clk = 1'b0;

        forever
            #5 clk = ~clk;
    end

    //============================================================
    // VCD WAVEFORM
    //============================================================

    initial
    begin
        $dumpfile("lift8.vcd");
        $dumpvars(0, Lift8_Tb);
    end

    //============================================================
    // TEST SEQUENCE
    //============================================================

    initial
    begin

        // Initial values
        reset = 1'b1;
        req_floor = 3'b000;
        emergency_stop = 1'b0;

        //========================================================
        // RESET
        //========================================================

        #10;
        reset = 1'b0;

        //========================================================
        // REQUEST FLOOR 1
        //========================================================

        #10;
        req_floor = 3'b001;

        #50;

        //========================================================
        // REQUEST FLOOR 4
        //========================================================

        req_floor = 3'b100;

        #60;

        //========================================================
        // REQUEST FLOOR 3
        //========================================================

        req_floor = 3'b011;

        #40;

        //========================================================
        // REQUEST FLOOR 7
        //========================================================

        req_floor = 3'b111;

        #40;

        //========================================================
        // EMERGENCY STOP
        //========================================================

        emergency_stop = 1'b1;

        #30;

        //========================================================
        // RELEASE EMERGENCY STOP
        //========================================================

        emergency_stop = 1'b0;

        #20;

        //========================================================
        // REQUEST FLOOR 2
        //========================================================

        req_floor = 3'b010;

        #50;

        //========================================================
        // REQUEST FLOOR 6
        //========================================================

        req_floor = 3'b110;

        #50;

        //========================================================
        // REQUEST FLOOR 1
        //========================================================

        req_floor = 3'b001;

        #60;

        //========================================================
        // END SIMULATION
        //========================================================

        $display("Simulation finished.");
        $finish;

    end

    //============================================================
    // DISPLAY OUTPUT
    //============================================================

    initial
    begin
        $monitor(
            "Time=%0t | CLK=%b | RESET=%b | REQ=%0d | FLOOR=%0d | REQUESTS=%b | MIN=%0d | MAX=%0d | UP=%b | DOWN=%b | DOOR=%b | IDLE=%b | EMERGENCY=%b",
            $time,
            clk,
            reset,
            req_floor,
            current_floor,
            requests,
            min_request,
            max_request,
            Up,
            Down,
            door,
            idle,
            emergency_stop
        );
    end

endmodule