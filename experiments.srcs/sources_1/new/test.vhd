

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;



entity com_tb is
end com_tb;

architecture test of com_tb is

component master is
port (
    data_wire, clk_wire: inout std_logic;
    clk: in std_logic;
    dir: in std_logic; -- 1 = write, 0 = read
    s_data: in std_logic_vector(7 downto 0);
    r_data: out std_logic_vector(7 downto 0);
    adress: in std_logic_vector(3 downto 0);
    go: in std_logic;
    busy: out std_logic;
    success: out std_logic
);
end component master;


component slave is
generic (
    ADRESS: std_logic_vector(3 downto 0) := x"0"
);

port (
    data_wire, clk_wire: inout std_logic;
    clkOut: out std_logic;
    dir: out std_logic; -- 1 = write, 0 = read
    s_data: in std_logic_vector(7 downto 0);
    r_data: out std_logic_vector(7 downto 0);
    go: out std_logic;
    busy: out std_logic;
    success: out std_logic
);
end component slave;

component bus_interface is
    port (
    write: in std_logic;
    read: out std_logic;
    wire: inout std_logic
    );
end component bus_interface;


    signal a_clk, a_data: std_logic;
    
    signal n_data: std_logic;
    
    signal data_wire, clk_wire: std_logic;
    signal clk: std_logic := '0';
    signal dir: std_logic; -- 1 = write, 0 = read
    signal s_data: std_logic_vector(7 downto 0);
    signal r_data: std_logic_vector(7 downto 0);
    signal adress: std_logic_vector(3 downto 0);
    signal go: std_logic;
    signal busy: std_logic;
    signal success: std_logic;
    
    
    signal dirS, goS, busyS, successS: std_logic;
    signal s_dataS, r_dataS: std_logic_vector(7 downto 0);
    

begin

    clk <= not clk after 5 ns;
    
    
    i2c_ish_master: master port map (
        data_wire => data_wire,
        clk_wire => clk_wire,
        clk => clk,
        dir => dir,
        s_data => s_data,
        r_data => r_data,
        adress => adress,
        go => go,
        busy => busy,
        success => success
    );
    
    i2c_ish_slave: slave generic map (ADRESS => x"2")
    port map (
        data_wire => data_wire,
        clk_wire => clk_wire,
        clkOut => open,
        dir => dirS,
        s_data => s_dataS,
        r_data => r_dataS,
        go => goS,
        busy => busyS,
        success => successS
    );
    
    
    
    eval_clk: bus_interface port map (
        wire => clk_wire,
        write => '0',
        read => a_clk
    );

    eval_data: bus_interface port map (
        wire => data_wire,
        write => n_data,
        read => a_data
    );    

    process
    begin
        
        s_dataS <= x"23";
        
        dir <= '1';
        s_data <= x"51";
        adress <= x"2";
        go <= '0';
        
        n_data <= '0';
        
        wait for 20 ns;
        
        go <= '1';
        wait for 1 ns;
        
        go <= '0';
        wait for 179 ns;
        
        
        
        adress <= x"2";
       
        wait for 50 ns;
        dir <= '0';
        go <= '1';
        wait for 1 ns;
        go <= '0';
        
        wait for 179 ns;
        
        dir <= '1';
        s_data <= x"00";
        adress <= x"2";
        wait for 5 ns;
        go <= '1';
        wait for 1 ns;
        go <= '0';
        
        
        wait;
    end process;
    

end test;
