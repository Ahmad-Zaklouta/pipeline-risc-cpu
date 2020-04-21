library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity full_adder is
    port (
        a, b, cin : in std_logic;
        f, cout   : out std_logic
    );
end entity;

architecture rtl of full_adder is
begin
    f    <= (a xor b) xor cin;
    cout <= ((a xor b) and cin) or (a and b);
end architecture;