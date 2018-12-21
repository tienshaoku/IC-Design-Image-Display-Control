# IC-Design-Image-Display-Control
Verilog code of the implementation of Image Display Control



### Algorithm Explanation:
1. I implement the idea of finite state machine: 2c1s(2 combinational circuits and 1 sequential circuit), to describe the behaviour of controlling the transformation between different processes. There are five states in my design: initialization, read, operation, write and the end. Then, I describe the signals of six outputs in the combinational circuit of different states.
2. I use a counter during "read" and "write" states, and then let the address equal to the [5:0] bits of the counter. The sequence of data written out (IRB_D) is also depended on the number of counter.
3. Afterwards, I use 1 combinational circuit to assign different signals to the according command(cmd); two sequential circuits to fulfill the commands of moving the control point position ad dealing with the data inside the buffers.
4. 64 buffers are used to place the data read in for later use in the writing process.
5. It's said that the main design problem in this homework is the design of "shifting". However, I cannot come up with a better idea than using a multiplexor of 64 options, so I guess the area of my circuit will be very large.
6. Also, it's worth mentioning the problem of signed bit and unsigned bit, as this caused me some issues during the function of "decrease". Therefore, it's wiser to present the value in its full bits: 8 as 4'b1000.
7. Lastly, I got into some serious problem when I assigned the value of one signal in two or more always block. This even forced stop the ModelSim. Therefore, I believe this issue is the most precious lesson I learnt from this homework.

<br>

1. HW4.pdf: description of the homework
2. Image Dispaly Control.pdf: review over the homework
3. lcd_ctrl.v: verilog code of the Image Display Control
4. IRB.v, IROM.v, testfixture.v: testbench 
4. *.dat: testing data of the command, image and goal
5. LCD_CRTL.vo, LCD_CTRL_v.sdo, cycloneii_atoms.v: files for simulation
