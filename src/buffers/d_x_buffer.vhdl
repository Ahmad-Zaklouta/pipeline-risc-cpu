library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity d_x_buffer is
    port (
        clk            : in std_logic;

        in_alu_op      : in std_logic_vector (3 downto 0);
        in_operand0    : in std_logic_vector(32 - 1 downto 0);
        in_operand1    : in std_logic_vector(32 - 1 downto 0);
        in_src2_value  : in std_logic_vector(32 - 1 downto 0);
        in_sel_src2    : in std_logic;
        in_dest_0      : in std_logic_vector(4 - 1 downto 0);
        in_dest_1      : in std_logic_vector(4 - 1 downto 0);

        in_src_0       : in std_logic_vector(4 - 1 downto 0);
        in_src_1       : in std_logic_vector(4 - 1 downto 0);
        in_opcode      : in std_logic_vector(7 - 1 downto 0);
        in_r_w         : in std_logic_vector(1 downto 0);
        in_interrupt   : in std_logic;
        in_hlt         : in std_logic;
        in_ccr         : in std_logic_vector(2 downto 0);

        out_alu_op     : out std_logic_vector (3 downto 0);
        out_operand0   : out std_logic_vector(32 - 1 downto 0);
        out_operand1   : out std_logic_vector(32 - 1 downto 0);
        out_dest_0     : out std_logic_vector(4 - 1 downto 0);
        out_dest_1     : out std_logic_vector(4 - 1 downto 0);

        out_src_0      : out std_logic_vector(4 - 1 downto 0);
        out_src_1      : out std_logic_vector(4 - 1 downto 0);
        out_opcode     : out std_logic_vector(7 - 1 downto 0);
        out_r_w        : out std_logic_vector(1 downto 0);
        out_interrupt  : out std_logic;
        out_ccr        : out std_logic_vector( 2 downto 0);
        out_hlt        : out std_logic
    );
end entity;

architecture rtl of d_x_buffer is
    signal operand0      : std_logic_vector(32 - 1 downto 0);
    signal operand1      : std_logic_vector(32 - 1 downto 0);
    signal src2_value    : std_logic_vector(32 - 1 downto 0);
    signal destination_0 : std_logic_vector(4 - 1 downto 0);
    signal destination_1 : std_logic_vector(4 - 1 downto 0);
    signal src_0         : std_logic_vector(4 - 1 downto 0);
    signal src_1         : std_logic_vector(4 - 1 downto 0);
    signal opcode        : std_logic_vector(7 - 1 downto 0);
    signal r_w           : std_logic_vector(1 downto 0);
    signal interrupt     : std_logic;
    signal alu_op        : std_logic_vector(3 downto 0);
    signal ccr           : std_logic_vector(2 downto 0);
    signal hlt           : std_logic;
begin
    process (in_operand0, in_operand1, in_dest_0, in_dest_1, in_opcode, in_r_w, in_interrupt, in_hlt)
    begin
            operand0      <= in_operand0;
            operand1      <= in_operand1;
            src2_value    <= in_src2_value;
            destination_0 <= in_dest_0;
            destination_1 <= in_dest_1;
            src_0         <= in_src_0;
            src_1         <= in_src_1;
            opcode        <= in_opcode;
            r_w           <= in_r_w;
            interrupt     <= in_interrupt;
            alu_op        <= in_alu_op;
            hlt           <= in_hlt;
            ccr           <= in_ccr;
    end process;

    process (clk, in_operand0, in_operand1, in_dest_0, in_dest_1, in_opcode, in_r_w, in_interrupt , src2_value, in_hlt, in_src_0,in_src_1)
    begin
        if rising_edge(clk) then
            out_alu_op     <= alu_op;
            out_operand0   <= operand0;

            if in_sel_src2 = '1' then
                out_operand1 <= src2_value;
            else
                out_operand1   <= operand1;
            end if;

            out_dest_0     <= destination_0;
            out_dest_1     <= destination_1;

            out_src_0      <= src_0;
            out_src_1      <= src_1;

            out_opcode     <= opcode;
            out_r_w        <= r_w;
            out_interrupt  <= interrupt;
            out_hlt        <= hlt;
            out_ccr        <= in_ccr;
        end if;
    end process;
end architecture;