

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity master is
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
end master;


architecture behavior of master is

component bus_interface is
    port (
    write: in std_logic;
    read: out std_logic;
    wire: inout std_logic
    );
end component bus_interface;
    
    type state_t is (IDLE, ADRESSING, SENDING, RECEIVING);
    signal state: state_t := IDLE;
    
    signal dOut, dIn: std_logic;
    signal counter: integer range 0 to 16;
    signal clk_enable, clk_out: std_logic;
    
    signal pageIn, pageOut: std_logic_vector(7 downto 0) := (others => '0');
    
begin


    r_data <= pageIn;
    pageOut <= s_data;

    data_interface: bus_interface port map (
        write => dOut,
        read => dIn,
        wire => data_wire
    );


    clk_out <= clk and clk_enable;
    clock_interface: bus_interface port map (
        write => clk_out,
        read => open,
        wire => clk_wire
    );


    state_transition: process(state, go, counter, clk, dir, pageIn, pageOut, dIn, dOut, adress)
    begin
        
        if clk'event and clk = '1' then
            success <= '0';
        end if;

        fsm: case state is
            when IDLE =>
                dOut <= '0';
                clk_enable <= '0';
                state <= IDLE;
                counter <= 0;
                busy <= '0';
                  
                if go = '1' then
                    busy <= '1';
                    state <= ADRESSING;
                end if;
            
            when ADRESSING =>
                state <= ADRESSING;
                clk_enable <= '1';
                busy <= '1';
                
                rising_clk_addr: if clk'event and clk = '1' then
                    counter <= counter + 1;
                
                
                    internal_state_addr: if counter < 4 then
                        dOut <= adress(counter);
                    else
                        dOut <= dir;
                        counter <= 0;
                    
                        direction: if dir = '1' then
                            state <= SENDING;
                        else
                            state <= RECEIVING;
                        end if direction;
                        
                    end if internal_state_addr;
                
                
                    check_bus_addr: if dIn /= dOut and counter > 0 then
                        dOut <= '0';
                        counter <= 0;
                        state <= IDLE;
                    end if check_bus_addr;
                    
                end if rising_clk_addr;
                
            
            when SENDING =>
                state <= SENDING;
                clk_enable <= '1';
                busy <= '1';
                
                rising_clk_send: if clk'event and clk = '1' then
                    counter <= counter + 1;
                
                
                    internal_state_send: if counter < 8 then
                        dOut <= pageOut(counter);
                    else
                        counter <= 0;
                        success <= '1';
                        state <= IDLE;
                    end if internal_state_send;
                
                
                
                    check_bus_send: if dIn /= dOut and counter > 0 then
                        dOut <= '0';
                        counter <= 0;
                        state <= IDLE;
                    end if check_bus_send;
                    
                end if rising_clk_send;
            
            when RECEIVING =>
                dOut <= '0';
                state <= RECEIVING;
                clk_enable <= '1';
                busy <= '1';
                
                rising_clk_rec: if clk'event and clk = '1' then
                    counter <= counter + 1;
                
                
                    internal_state_rec: if counter < 8 then
                        pageIn(counter) <= dIn; --Offset for slave clock driven by master
                    else
                        counter <= 0;
                        success <= '1';
                        state <= IDLE;                    
                    end if internal_state_rec;
                end if rising_clk_rec;
                
            
            when others =>
                state <= IDLE;
        end case fsm;
    end process state_transition;
    


end behavior;








library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slave is
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
end slave;


architecture behavior of slave is

component bus_interface is
    port (
    write: in std_logic;
    read: out std_logic;
    wire: inout std_logic
    );
end component bus_interface;
    
    type state_t is (ADRESSING, SENDING, RECEIVING, SILENT);
    signal state: state_t := ADRESSING;
    
    signal dOut, dIn: std_logic;
    
    
    signal pageIn, pageOut: std_logic_vector(7 downto 0) := (others => '0');
    
    signal clk: std_logic;
    signal busy_i: std_logic := '0';
    
begin


    r_data <= pageIn;
    pageOut <= s_data;
    
    busy <= busy_i;
    clkOut <= clk;

    data_interface: bus_interface port map (
        write => dOut,
        read => dIn,
        wire => data_wire
    );


    clock_interface: bus_interface port map (
        write => '0',
        read => clk,
        wire => clk_wire
    );


    state_transition: process(state, clk, pageIn, pageOut, dIn, dOut)
        variable dir_v: std_logic;
        variable counter: integer range 0 to 16 := 0;
    begin
        
        if clk'event and clk = '1' then
            success <= '0';
        

        fsm: case state is
            
            when ADRESSING =>
                if busy_i = '0' then
                    counter := 0;
                else
                    counter := counter + 1;
                end if;
                
                dOut <= '0';
                state <= ADRESSING;
                busy_i <= '1';
                go <= '0';
                
                
                internal_state_addr: if counter < 4 then
                    if dIn /= ADRESS(counter) then
                        state <= SILENT;
                    end if;
                 else
                    dir_v := dIn;
                    dir <= dir_v;
                    go <= '1';
                    
                    
                    direction: if dir_v = '1' then
                        counter := 0;
                        state <= RECEIVING;
                    else
                         counter := 1;
                         dOut <= pageOut(0);
                         state <= SENDING;
                    end if direction;
                        
                  end if internal_state_addr;
                
                
            
            when SENDING =>
                state <= SENDING;
                busy_i <= '1';
                
                internal_state_send: if counter < 8 then
                    dOut <= pageOut(counter);
                else
                    success <= '1';
                    busy_i <= '0';
                    go <= '0';
                    state <= ADRESSING;
                end if internal_state_send;
                
                counter := counter + 1;
                
                check_bus_send: if dIn /= dOut and counter > 0 then
                    dOut <= '0';
                    busy_i <= '0';
                    go <= '0';
                    state <= ADRESSING;
                end if check_bus_send;
                    
            
            when RECEIVING =>
                dOut <= '0';
                state <= RECEIVING;
                busy_i <= '1';
                
                internal_state_rec: if counter < 8 then
                    pageIn(counter) <= dIn;
                else
                    success <= '1';
                    busy_i <= '0';
                    go <= '0';
                    state <= ADRESSING;                   
                end if internal_state_rec;
                
                counter := counter + 1;
            
            when SILENT =>
                dOut <= '0';
                state <= SILENT;
                busy_i <= '1';
                
                if counter > 11 then
                    busy_i <= '0';
                    go <= '0';
                    state <= ADRESSING;
                end if;
                
                counter := counter + 1;
                                    
            
            when others =>
                counter := 0;
                state <= ADRESSING;
        end case fsm;
        
        end if;
        
    end process state_transition;
    


end behavior;

