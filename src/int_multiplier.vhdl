library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity int_multiplier is
    -- N: bits of the input A, output C
    -- M: bits of input B
    -- N >= M
    generic (
        N : integer := 7;
        M : integer := 3
    );

    port (
        a    : in std_logic_vector(N - 1 downto 0);
        b    : in std_logic_vector(M - 1 downto 0);
        enbl : in std_logic;

        c    : out std_logic_vector(N - 1 downto 0)
    );
end entity;

architecture rtl of int_multiplier is
begin
    -- We only use this unit for address calculation, so we went with (*) operator.
    c <= to_vec(to_int(a) * to_int(b), c'length) when enbl = '1';
end architecture;