library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity fetch_stage is
    port (
        clk                          : in std_logic;
        rst                          : in std_logic;

        in_interrupt                 : in std_logic;
        in_if_flush                  : in std_logic;
        in_if_enable                 : in std_logic;
        in_parallel_load_pc_selector : in std_logic;
        in_loaded_pc_value           : in std_logic_vector(31 downto 0);
        in_branch_address            : in std_logic_vector(31 downto 0);
        in_hashed_address            : in std_logic_vector(3 downto 0);
        in_reg_value                 : in std_logic_vector(31 downto 0);

        out_interrupt                : out std_logic;
        out_instruction_bits         : out std_logic_vector(31 downto 0);
        out_predicted_address        : out std_logic_vector(31 downto 0);
        out_hashed_address           : out std_logic_vector(3 downto 0);
        out_inc_pc                   : out std_logic_vector(31 downto 0);
        out_reg_idx                  : out std_logic_vector(3 downto 0);

        -- testing signals

        -- '1' if testbench is taking control now of the memory and regs
        tb_controls                  : in std_logic;

        -- to mem
        tb_mem_rd                    : in std_logic;
        tb_mem_wr                    : in std_logic;
        tb_mem_data_in               : in std_logic_vector(15 downto 0);
        tb_mem_adr                   : in std_logic_vector(31 downto 0);
        -- from mem
        tb_mem_data_out              : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of fetch_stage is
    --> inst_mem initials
    signal pc           : std_logic_vector(31 downto 0);
    signal len_bit      : std_logic                     := '0';
    signal mem_rd       : std_logic                     := '1';
    signal mem_wr       : std_logic                     := '0';
    signal mem_data_in  : std_logic_vector(15 downto 0) := (others => '0');
    signal mem_data_out : std_logic_vector(15 downto 0) := (others => '0');

    --> inst_mem
    signal im_rd        : std_logic;
    signal im_wr        : std_logic;
    signal im_data_in   : std_logic_vector(mem_data_in'range);
    signal im_adr       : std_logic_vector(pc'range);
    signal im_rst       : std_logic;

    --> temp stores
    signal temp_pc      : std_logic_vector(31 downto 0) := (others => '0');
    signal inst_store   : std_logic_vector(15 downto 0) := (others => '0');
    signal pc_store     : std_logic_vector(15 downto 0) := (others => '0');

    --> logic states
    signal rst_state    : std_logic_vector(1 downto 0)  := (others => '0');
    signal int_state    : std_logic_vector(2 downto 0)  := (others => '0');
    signal call_state   : std_logic                     := '0';
    signal jz_state     : std_logic                     := '0';

    --> branch_pred
    signal hashed_adr   : std_logic_vector(3 downto 0)  := (others => '0');
    signal br_pred      : std_logic                     := '0';

begin
    inst_mem : entity work.instr_mem(rtl)
        generic map(ADR_LENGTH => 32)
        port map(
            clk      => clk,
            rd       => im_rd,
            wr       => im_wr,
            rst      => im_rst,
            data_in  => im_data_in,
            address  => im_adr,
            data_out => mem_data_out
        );

    branch_pred : entity work.dyn_branch_pred(rtl)
        port map(
            rst             => rst,
            prev_hashed_adr => in_hashed_address,
            update          => in_if_flush,
            enable          => in_if_enable,
            cur_hashed_adr  => hashed_adr,
            taken           => br_pred
        );

    --IN
    im_rd              <= tb_mem_rd when tb_controls = '1' else mem_rd;
    im_wr              <= tb_mem_wr when tb_controls = '1' else mem_wr;
    im_data_in         <= tb_mem_data_in when tb_controls = '1' else mem_data_in;
    im_adr             <= tb_mem_adr when tb_controls = '1' else pc;
    im_rst             <= '0' when tb_controls = '1' else rst;
    --OUT
    tb_mem_data_out    <= mem_data_out;

    process (clk, rst, mem_data_out, br_pred, in_interrupt, in_if_flush, in_parallel_load_pc_selector, in_loaded_pc_value, in_branch_address, in_hashed_address, in_reg_value)
    begin
        if rst = '1' then
            -- reset logic start
            pc                    <= (others => '0');
            mem_data_in           <= (others => '0');
            len_bit               <= '0';
            mem_rd                <= '1';
            mem_wr                <= '0';
            out_interrupt         <= '0';
            out_instruction_bits  <= (others => '0');
            out_predicted_address <= (others => '0');
            out_inc_pc            <= to_vec(to_int(pc) + 1, pc'length);
            out_hashed_address    <= pc(3 downto 0);
            out_reg_idx           <= "1111";
            temp_pc               <= (others => '0');
            inst_store            <= (others => '0');
            pc_store              <= (others => '0');
            int_state             <= (others => '0');
            call_state            <= '0';
            jz_state              <= '0';
            hashed_adr            <= (others => '0');
            rst_state             <= "01";

        elsif in_if_flush = '1' then
            -- instruction flush
            pc                   <= in_branch_address;
            out_inc_pc           <= to_vec(to_int(pc) + 1, pc'length);
            out_hashed_address   <= pc(3 downto 0);
            -- output NOP
            out_instruction_bits <= (others => '0');

        elsif rising_edge(clk) then
            -- main fetch logic
            if rst_state = "01" then
                -- read upper part of pc (reset)
                pc_store              <= mem_data_out;
                pc                    <= to_vec(to_int(pc) + 1, pc'length);
                out_inc_pc            <= to_vec(to_int(pc) + 1, pc'length);
                out_hashed_address    <= pc(3 downto 0);
                rst_state             <= "10";
    
            elsif rst_state = "10" then
                -- read lower part of pc (reset)
                pc(31 downto 16)      <= pc_store;
                pc(15 downto 0)       <= mem_data_out;
                out_inc_pc            <= to_vec(to_int(pc) + 1, pc'length);
                out_hashed_address    <= pc(3 downto 0);
                rst_state             <= "00";

            elsif in_interrupt = '1' and int_state = "000" then
                -- Interrupt first state
                -- store current pc
                temp_pc              <= pc;
                -- output NOP
                out_instruction_bits <= (others => '0');
                int_state            <= "001";

            elsif int_state = "001" then
                -- Interrupt second state
                -- interrupt logic start
                out_interrupt        <= '1';
                pc                   <= to_vec(2, pc'length);
                out_inc_pc           <= temp_pc;
                out_hashed_address   <= temp_pc(3 downto 0);
                int_state            <= "010";

            elsif int_state = "010" then
                -- Interrupt third state
                -- read upper part of pc
                out_interrupt        <= '0';
                out_instruction_bits <= (others => '0');
                pc_store             <= mem_data_out;
                pc                   <= to_vec(to_int(pc) + 1, pc'length);
                int_state            <= "011";

            elsif int_state = "011" then
                -- Interrupt fourth state
                -- read lower part of pc
                out_instruction_bits <= (others => '0');
                pc(31 downto 16)     <= pc_store;
                pc(15 downto 0)      <= mem_data_out;
                int_state            <= "100";

            elsif int_state = "100" then
                -- Interrupt fifth state
                -- output NOP
                out_instruction_bits <= (others => '0');
                int_state            <= "000";

            elsif in_parallel_load_pc_selector = '1' then
                -- load from data memory
                pc                   <= in_loaded_pc_value;
                out_inc_pc           <= to_vec(to_int(pc) + 1, pc'length);
                out_hashed_address   <= pc(3 downto 0);
                -- output NOP
                out_instruction_bits <= (others => '0');

            elsif len_bit = '0' and (mem_data_out(14 downto 8) = "0000011" or mem_data_out(14 downto 8) = "0000010") then
                -- call and jump instructions
                if call_state = '0' then
                    -- get value from register file
                    out_reg_idx(3)          <= '0';
                    out_reg_idx(2 downto 0) <= mem_data_out(7 downto 5);
                    -- output NOP
                    out_instruction_bits    <= (others => '0');
                    temp_pc                 <= pc;
                    call_state              <= '1';
                else
                    -- assign branch value
                    pc                                    <= in_reg_value;
                    out_instruction_bits(31 downto 16)    <= mem_data_out;
                    out_predicted_address                 <= in_reg_value;
                    out_inc_pc                            <= to_vec(to_int(temp_pc) + 1, pc'length);
                    out_hashed_address                    <= temp_pc(3 downto 0);
                    call_state                            <= '0';
                end if;

            elsif len_bit = '0' and mem_data_out(14 downto 8) = "0000001" then
                -- JZ instruction
                if jz_state = '0' then
                    -- activate dynamic branch predictor
                    hashed_adr              <= pc(3 downto 0);
                    -- get value from register file
                    out_reg_idx(3)          <= '0';
                    out_reg_idx(2 downto 0) <= mem_data_out(7 downto 5);
                    -- output NOP
                    out_instruction_bits    <= (others => '0');
                    temp_pc                 <= pc;
                    jz_state                <= '1';
                else
                    -- determine PC next value and predicted address output
                    out_inc_pc                              <= to_vec(to_int(temp_pc) + 1, pc'length);
                    out_hashed_address                      <= temp_pc(3 downto 0);
                    if br_pred = '0' then
                        pc                                  <= to_vec(to_int(pc) + 1, pc'length);
                        out_predicted_address               <= to_vec(to_int(pc) + 1, pc'length);
                        out_instruction_bits(31 downto 16)  <= mem_data_out;
                        jz_state                            <= '0';
                    else
                        pc                                  <= in_reg_value;
                        out_predicted_address               <= in_reg_value;
                        out_instruction_bits(31 downto 16)  <= mem_data_out;
                        jz_state                            <= '0';
                    end if;
                end if;

            else
                out_inc_pc         <= to_vec(to_int(pc) + 1, pc'length);
                out_hashed_address <= pc(3 downto 0);
                pc                 <= to_vec(to_int(pc) + 1, pc'length);
                -- instruction output and instruction length decision
                if len_bit = '0' and mem_data_out(15) = '0' then
                    out_instruction_bits(31 downto 16) <= mem_data_out;
                    out_instruction_bits(15 downto 0)  <= (others => '0');

                elsif len_bit = '0' and mem_data_out(15) = '1' then
                    -- output NOP
                    out_instruction_bits               <= (others => '0');
                    inst_store                         <= mem_data_out;
                    len_bit                            <= '1';

                else
                    out_instruction_bits(31 downto 16) <= inst_store;
                    out_instruction_bits(15 downto 0)  <= mem_data_out;
                    len_bit                            <= '0';
                end if; 
            end if;  

        end if;

    end process;
end architecture;