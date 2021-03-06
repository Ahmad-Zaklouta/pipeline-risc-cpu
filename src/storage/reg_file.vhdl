library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity reg_file is
    port (
        dst0_adr    : in std_logic_vector(3 downto 0); -- DST
        dst1_adr    : in std_logic_vector(3 downto 0);
        src0_adr    : in std_logic_vector(3 downto 0); -- SRC
        src1_adr    : in std_logic_vector(3 downto 0);
        fetch_adr   : in std_logic_vector(3 downto 0);  -- FETCH

        wb0_value   : in std_logic_vector(31 downto 0); -- WB
        wb1_value   : in std_logic_vector(31 downto 0);

        rst         : in std_logic;
        clk         : in std_logic;

        br_io_enbl  : in std_logic_vector(1 downto 0);   -- SPECIALS

        op0_value   : out std_logic_vector(31 downto 0); -- OP
        op1_value   : out std_logic_vector(31 downto 0);

        fetch_value : out std_logic_vector(31 downto 0);
        instr_adr   : out std_logic_vector(31 downto 0);

        out_value   : out std_logic_vector(31 downto 0) -- IO
    );
end entity;

architecture rtl of reg_file is
    -- why don't i put them in an array? because arrays don't appear in ghdl signals dump.
    signal r0, r1, r2, r3, r4, r5, r6, r7 : std_logic_vector(31 downto 0);
    signal sp                             : std_logic_vector(10 downto 0);
begin
    process (dst0_adr, dst1_adr, src0_adr, src1_adr, fetch_adr, wb0_value, wb1_value, rst, clk, br_io_enbl)
        procedure out_reg(adr : std_logic_vector(3 downto 0); signal o : out std_logic_vector(31 downto 0)) is
        begin
            case adr is
                when x"0" => o <= r0;
                when x"1" => o <= r1;
                when x"2" => o <= r2;
                when x"3" => o <= r3;
                when x"4" => o <= r4;
                when x"5" => o <= r5;
                when x"6" => o <= r6;
                when x"7" => o <= r7;
                when x"8" =>
                    o(10 downto 0)  <= sp;
                    o(31 downto 11) <= (others => '0');
                when others                => null;
            end case;
        end procedure;

        procedure in_reg(adr : std_logic_vector(3 downto 0); constant i : std_logic_vector(31 downto 0)) is
        begin
            case adr is
                when x"0"   => r0 <= i;
                when x"1"   => r1 <= i;
                when x"2"   => r2 <= i;
                when x"3"   => r3 <= i;
                when x"4"   => r4 <= i;
                when x"5"   => r5 <= i;
                when x"6"   => r6 <= i;
                when x"7"   => r7 <= i;
                when x"8"   => sp <= i(10 downto 0);
                when x"9"   => out_value <= i;
                when others => null;
            end case;
        end procedure;
    begin
        if rst = '1' then
            for i in 0 to 7 loop
                in_reg(to_vec(i, 4), to_vec(0, 32));
            end loop;
            in_reg(to_vec(8, 4), to_vec(0, 32 - 11) & to_vec(-2, 11));
        elsif falling_edge(clk) then -- read
            if (src0_adr = dst0_adr and src0_adr /= "1111") then
                op0_value     <= wb0_value;
            elsif (src0_adr = dst1_adr and src0_adr /= "1111") then
                op0_value     <= wb1_value;
            else
                out_reg(src0_adr, op0_value);
            end if;
            if (src1_adr = dst0_adr and src1_adr /= "1111") then
                op1_value     <= wb0_value;
            elsif (src1_adr = dst1_adr and src1_adr /= "1111") then
                op1_value     <= wb1_value;
            else
                out_reg(src1_adr, op1_value);
            end if;
            case br_io_enbl is
                when "11" => -- Branch
                    out_reg(src0_adr, instr_adr);
                when others =>
                    null;
            end case;
            out_reg(fetch_adr, fetch_value);
        elsif rising_edge(clk) then -- write
            in_reg(dst0_adr, wb0_value);
            in_reg(dst1_adr, wb1_value);
        end if;
    end process;
end architecture;