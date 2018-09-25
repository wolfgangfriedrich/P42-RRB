----------------------------------------------------------------------------------
-- Company: Pier42 Design
-- Engineer: WF
-- 
-- Create Date: 08/31/2018 
-- Design Name: Radio Rewind Button
-- Module Name: RRB - Behavioral
-- Project Name: RRB
-- Target Devices: ARTY-S7 board Spartan7
-- Tool Versions: Vivado 18.2
-- Description: 
-- 
-- Dependencies: SDRAM
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RRB is
    Generic (
        RCLK_FM_TARGET  : integer := 32768;     -- in Hz
        SYSCLK          : integer := 12000000   -- in Hz
        );
    Port (  
        CLK12MHZ    : in STD_LOGIC;
        CLK100MHZ   : in STD_LOGIC;
        nCK_RST     : in STD_LOGIC;
        RCLK_FM     : out STD_LOGIC;
        
        MCLK        : out STD_LOGIC;
        
        BTN         : in  STD_LOGIC_VECTOR (3 downto 0);
        LED         : out STD_LOGIC_VECTOR (3 downto 0);
		LED0_R      : out STD_LOGIC;
		LED0_G      : out STD_LOGIC;
		LED0_B      : out STD_LOGIC;
		LED1_R      : out STD_LOGIC;
		LED1_G      : out STD_LOGIC;
		LED1_B      : out STD_LOGIC;
		
		ddr3_dq       : inout std_logic_vector(15 downto 0);
		ddr3_dqs_p    : inout std_logic_vector(1 downto 0);
		ddr3_dqs_n    : inout std_logic_vector(1 downto 0);
		
		ddr3_addr     : out   std_logic_vector(13 downto 0);
		ddr3_ba       : out   std_logic_vector(2 downto 0);
		ddr3_ras_n    : out   std_logic;
		ddr3_cas_n    : out   std_logic;
		ddr3_we_n     : out   std_logic;
		ddr3_reset_n  : out   std_logic;
		ddr3_ck_p     : out   std_logic_vector(0 downto 0);
		ddr3_ck_n     : out   std_logic_vector(0 downto 0);
		ddr3_cke      : out   std_logic_vector(0 downto 0);
		ddr3_cs_n     : out   std_logic_vector(0 downto 0);
		ddr3_dm       : out   std_logic_vector(1 downto 0);
		ddr3_odt      : out   std_logic_vector(0 downto 0)		
		);
end RRB;

architecture Behavioral of RRB is

-- Signal Debouncer: re-used from ARTY-S7GPIO project
-- Copyright 2011 Digilent, Inc.

component debouncer
Generic(
        DEBNC_CLOCKS : integer;
        PORT_WIDTH   : integer);
Port(
		SIGNAL_I : in std_logic_vector(3 downto 0);
		CLK_I    : in std_logic;          
		SIGNAL_O : out std_logic_vector(3 downto 0)
		);
end component;


component mig_7series_0
  port (
      ddr3_dq       : inout std_logic_vector(15 downto 0);
      ddr3_dqs_p    : inout std_logic_vector(1 downto 0);
      ddr3_dqs_n    : inout std_logic_vector(1 downto 0);

      ddr3_addr     : out   std_logic_vector(13 downto 0);
      ddr3_ba       : out   std_logic_vector(2 downto 0);
      ddr3_ras_n    : out   std_logic;
      ddr3_cas_n    : out   std_logic;
      ddr3_we_n     : out   std_logic;
      ddr3_reset_n  : out   std_logic;
      ddr3_ck_p     : out   std_logic_vector(0 downto 0);
      ddr3_ck_n     : out   std_logic_vector(0 downto 0);
      ddr3_cke      : out   std_logic_vector(0 downto 0);
	  ddr3_cs_n     : out   std_logic_vector(0 downto 0);
      ddr3_dm       : out   std_logic_vector(1 downto 0);
      ddr3_odt      : out   std_logic_vector(0 downto 0);
      app_addr                  : in    std_logic_vector(27 downto 0);
      app_cmd                   : in    std_logic_vector(2 downto 0);
      app_en                    : in    std_logic;
      app_wdf_data              : in    std_logic_vector(127 downto 0);
      app_wdf_end               : in    std_logic;
      app_wdf_mask              : in    std_logic_vector(15 downto 0);
      app_wdf_wren              : in    std_logic;
      app_rd_data               : out   std_logic_vector(127 downto 0);
      app_rd_data_end           : out   std_logic;
      app_rd_data_valid         : out   std_logic;
      app_rdy                   : out   std_logic;
      app_wdf_rdy               : out   std_logic;
      app_sr_req                : in    std_logic;
      app_ref_req               : in    std_logic;
      app_zq_req                : in    std_logic;
      app_sr_active             : out   std_logic;
      app_ref_ack               : out   std_logic;
      app_zq_ack                : out   std_logic;
      ui_clk                    : out   std_logic;
      ui_clk_sync_rst           : out   std_logic;
      init_calib_complete       : out   std_logic;
      -- System Clock Ports
      sys_clk_i                 : in    std_logic;
      -- Reference Clock Ports
      clk_ref_i                 : in    std_logic;
      sys_rst                   : in    std_logic
  );
end component mig_7series_0;


-------------------------------------------------------------------------------
type sdram_test_sm_type is (sm_idle, sm_cmd_wr, sm_wr, sm_wr_wait, sm_cmd_rd, sm_rd );

-------------------------------------------------------------------------------
constant rclk_count     : integer := SYSCLK/RCLK_FM_TARGET/2;
constant mclk_count     : integer := 4;                         -- divide by 10

constant debnc_clocks    : integer := 2**16;
constant debncport_width : integer := 4;


-------------------------------------------------------------------------------
signal CK_RST           : STD_LOGIC;
signal rclk_fm_int      : STD_LOGIC;
signal mclk_int         : STD_LOGIC;

signal btn_debnc		: STD_LOGIC_VECTOR(3 downto 0);
signal btn_reg			: STD_LOGIC_VECTOR(3 downto 0);
-- SDRAM signals
signal app_addr       		: STD_LOGIC_VECTOR(27 downto 0);
signal app_cmd        		: STD_LOGIC_VECTOR(2 downto 0);
signal app_en         		: STD_LOGIC;
signal app_wdf_data   		: STD_LOGIC_VECTOR(127 downto 0);
signal app_wdf_end    		: STD_LOGIC;
signal app_wdf_mask     	: STD_LOGIC_VECTOR(15 downto 0);
signal app_wdf_wren   		: STD_LOGIC;
signal app_rd_data    		: STD_LOGIC_VECTOR(127 downto 0);
signal app_rd_data_end		: STD_LOGIC;
signal app_rd_data_valid	: STD_LOGIC;
signal app_rdy				: STD_LOGIC;
signal app_wdf_rdy      	: STD_LOGIC;
signal app_sr_req       	: STD_LOGIC;
signal app_ref_req      	: STD_LOGIC;
signal app_zq_req       	: STD_LOGIC;
signal app_sr_active    	: STD_LOGIC;
signal app_ref_ack      	: STD_LOGIC;
signal app_zq_ack       	: STD_LOGIC;
signal ui_clk           	: STD_LOGIC;
signal ui_clk_sync_rst  	: STD_LOGIC;
signal init_calib_complete  : STD_LOGIC;

signal sdram_test_sm		: sdram_test_sm_type := sm_idle;
signal sdram_test_start		: STD_LOGIC;
signal sdram_rd_data    	: STD_LOGIC_VECTOR(127 downto 0);

begin

CK_RST <= not nCK_RST;

-------------------------------------------------------------------------------
--Debounces btn signals 
Inst_btn_debounce: debouncer 
    generic map(
        DEBNC_CLOCKS => debnc_clocks,
        PORT_WIDTH   => debncport_width)
    port map(
		SIGNAL_I => BTN,
		CLK_I => CLK100MHZ,
		SIGNAL_O => btn_debnc
	);

--Registers the debounced button signals, for edge detection.
btn_reg_process : process (CLK100MHZ, nCK_RST)
begin
if nCK_RST = '0' then
    btn_reg <= "0000";
elsif (rising_edge(CLK100MHZ)) then
		btn_reg <= btn_debnc(3 downto 0);
	end if;
end process;

LED0_R <= btn_reg(1) or btn_reg(0);
LED0_G <= btn_reg(2) or btn_reg(0);
LED0_B <= btn_reg(3) or btn_reg(0);

-------------------------------------------------------------------------------
blink_process : process (CLK12MHZ, nCK_RST)

variable count : STD_LOGIC_VECTOR (27 downto 0) := X"0000000";

begin
    if nCK_RST = '0' then
        count := X"0000000";
        LED <= "0000";
    elsif rising_edge(CLK12MHZ) then
        count := std_logic_vector( unsigned(count) + 1);   --X"000001";    
        
        LED(3) <= count (27);
        LED(2) <= count (26);
        LED(1) <= count (25);
        LED(0) <= count (24);
        
        sdram_test_start <= count (25);
        
    end if;

end process;

RCLK_FM <= rclk_fm_int;

-------------------------------------------------------------------------------
rclk_fm_process : process (CLK12MHZ, nCK_RST)

variable rclk_counter : integer;

begin
    if nCK_RST = '0' then
        rclk_counter := rclk_count;
        rclk_fm_int <= '0';
    elsif rising_edge(CLK12MHZ) then
        if rclk_counter = 0 then
            rclk_fm_int <= not rclk_fm_int;
            rclk_counter := rclk_count;
        elsif rclk_counter > 0 then
            rclk_fm_int <= rclk_fm_int;
            rclk_counter := rclk_counter - 1;
        else
            rclk_fm_int <= rclk_fm_int;
            rclk_counter := rclk_count;    
        end if;
    end if;
end process;

MCLK <= mclk_int;

-------------------------------------------------------------------------------
mclk_process : process (CLK100MHZ, nCK_RST)

variable mclk_counter : integer;

begin
    if nCK_RST = '0' then
        mclk_counter := mclk_count;
        mclk_int <= '0';
    elsif rising_edge(CLK100MHZ) then
        if mclk_counter = 0 then
            mclk_int <= not mclk_int;
            mclk_counter := mclk_count;
        elsif mclk_counter > 0 then
            mclk_int <= mclk_int;
            mclk_counter := mclk_counter - 1;
        else
            mclk_int <= mclk_int;
            mclk_counter := mclk_count;    
        end if;
    end if;
end process;


-------------------------------------------------------------------------------
  u_artys7_sdram : mig_7series_0
    port map (
       -- Memory interface ports
       ddr3_addr                      => ddr3_addr,
       ddr3_ba                        => ddr3_ba,
       ddr3_cas_n                     => ddr3_cas_n,
       ddr3_ck_n                      => ddr3_ck_n,
       ddr3_ck_p                      => ddr3_ck_p,
       ddr3_cke                       => ddr3_cke,
       ddr3_ras_n                     => ddr3_ras_n,
       ddr3_reset_n                   => ddr3_reset_n,
       ddr3_we_n                      => ddr3_we_n,
       ddr3_dq                        => ddr3_dq,
       ddr3_dqs_n                     => ddr3_dqs_n,
       ddr3_dqs_p                     => ddr3_dqs_p,
       init_calib_complete            => init_calib_complete,
	   ddr3_cs_n                      => ddr3_cs_n,
       ddr3_dm                        => ddr3_dm,
       ddr3_odt                       => ddr3_odt,
       -- Application interface ports
       app_addr                       => app_addr,
       app_cmd                        => app_cmd,
       app_en                         => app_en,
       app_wdf_data                   => app_wdf_data,
       app_wdf_end                    => app_wdf_end,
       app_wdf_wren                   => app_wdf_wren,
       app_rd_data                    => app_rd_data,
       app_rd_data_end                => app_rd_data_end,
       app_rd_data_valid              => app_rd_data_valid,
       app_rdy                        => app_rdy,
       app_wdf_rdy                    => app_wdf_rdy,
       app_sr_req                     => app_sr_req,
       app_ref_req                    => app_ref_req,
       app_zq_req                     => app_zq_req,
       app_sr_active                  => app_sr_active,
       app_ref_ack                    => app_ref_ack,
       app_zq_ack                     => app_zq_ack,
       ui_clk                         => ui_clk,
       ui_clk_sync_rst                => ui_clk_sync_rst,
       app_wdf_mask                   => app_wdf_mask,
       -- System Clock Ports
       sys_clk_i                      => CLK100MHZ,
       -- Reference Clock Ports
       clk_ref_i                      => CLK100MHZ,
      sys_rst                         => nCK_RST
    );		
    
--app_addr		<= (others => '0');
--app_cmd			<= (others => '0');     
--app_en			<= '1';      
--app_wdf_data	<= (others => '0');
--app_wdf_end		<= '0';
app_wdf_mask	<= (others => '1');
--app_wdf_wren	<= '0';
--app_rd_data		<= (others => '0');
app_sr_req		<= '0';
app_ref_req		<= '0';
app_zq_req		<= '0';

-------------------------------------------------------------------------------
sdram_test_process : process (CLK100MHZ, nCK_RST)
begin
	if nCK_RST = '0' then
		sdram_test_sm <= sm_idle;
		app_addr		<= (others => '0');
		app_cmd			<= (others => '0');     
		app_en			<= '0';      
		app_wdf_data <= (others => '0');
		app_wdf_wren <= '0';
		app_wdf_end <='0';
		sdram_rd_data	<= (others => '0');
	elsif rising_edge(CLK100MHZ) then
		app_addr		<= (others => '0');
		app_cmd			<= (others => '0');     
		app_en			<= '1';
		app_wdf_data <= X"0123456789abcdefaffedeadbeeff00d";
		app_wdf_wren <= '0';
		app_wdf_end <='0';
		sdram_rd_data	<= sdram_rd_data;
		case sdram_test_sm is
			when sm_idle =>
				app_addr		<= (others => '0');
				app_cmd			<= (others => '0');     
				app_en			<= '0';
				if sdram_test_start = '1' then
					sdram_test_sm <= sm_cmd_wr;
				else
					sdram_test_sm <= sm_idle;
				end if;
			when sm_cmd_wr =>
				app_addr		<= (others => '0');
				app_cmd			<= "000";     
				app_en			<= '1';
				if app_rdy = '1' then
					sdram_test_sm <= sm_wr;
				else
					sdram_test_sm <= sm_cmd_wr;
				end if;
			when sm_wr =>
				app_wdf_data <= X"0123456789abcdefaffedeadbeeff00d";
				app_wdf_wren <= '1';
				app_wdf_end <='1';
				sdram_test_sm <= sm_wr_wait;
			when sm_wr_wait =>
				app_wdf_wren <= '0';
				app_wdf_end <='0';
				if sdram_test_start = '0' then
					sdram_test_sm <= sm_cmd_rd;
				else
					sdram_test_sm <= sm_wr_wait;
				end if;
			when sm_cmd_rd =>
				if app_rdy = '1' then
					app_addr		<= (others => '0');
					app_cmd			<= "001";     
					app_en			<= '1';
					sdram_test_sm <= sm_rd;
				else
					sdram_test_sm <= sm_cmd_rd;
				end if;
			when sm_rd =>
				if app_rd_data_valid = '1' then
					sdram_rd_data <= app_rd_data;
					sdram_test_sm <= sm_idle;
				else 
					sdram_rd_data <= sdram_rd_data;
					sdram_test_sm <= sm_rd;
				end if;
	
	
		end case;
	end if;
end process;

LED1_B <= '0';
LED1_G <= '1' when sdram_rd_data  = X"0123456789abcdefaffedeadbeeff00d"
				else '0';
LED1_R <= '1' when sdram_rd_data /= X"0123456789abcdefaffedeadbeeff00d"
				else '0';


end Behavioral;
