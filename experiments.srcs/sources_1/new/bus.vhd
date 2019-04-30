
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity bus_interface is
    port (
    write: in std_logic;
    read: out std_logic;
    wire: inout std_logic
    );
end bus_interface;

architecture behavioral of bus_interface is

begin

    process(wire)
    begin
    
        if wire = '0' then
            read <= '1';
        else
            read <= '0';
        end if;
    end process;
    
    process(write)
    begin
    
        if write = '1' then
            wire <= '0';
        else
            wire <= 'Z';
        end if;
    end process;

end behavioral;









library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bus_tb is
end entity;


architecture test of bus_tb is

component bus_interface is
    port (
    write: in std_logic;
    read: out std_logic;
    wire: inout std_logic
    );
end component bus_interface;


signal wire, s1, r1, s2, r2: std_logic;
begin

p1: bus_interface port map(
    wire => wire,
    write => s1,
    read => r1
);

p2: bus_interface port map(
    wire => wire,
    write => s2,
    read => r2
);



process
begin
s1 <= '0';
s2 <= '0';
wait for 10 ns;

s1 <= '1';
wait for 10 ns;

s2 <= '1';
wait for 10 ns;

s1 <= '0';
wait for 10 ns;

s2 <= '0';

wait;
end process;






end test;
