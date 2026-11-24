-- Banco de pruebas de hdmi_tx: escribe los simbolos (q.txt) y el audio enviado (au.txt)
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all; use std.textio.all;
entity tb is end;
architecture t of tb is
 signal c: std_logic:='0'; signal h,v: unsigned(9 downto 0):=(others=>'0');
 signal hs,vs,de,hs1,vs1,de1,hs2,vs2,de2: std_logic:='1'; signal rgb,rgb1,rgb2: std_logic_vector(23 downto 0):=(others=>'0');
 signal req,rq: std_logic:='0'; signal au: std_logic_vector(15 downto 0):=x"0000"; signal q0,q1,q2: std_logic_vector(9 downto 0); signal stop: boolean:=false;
 signal n: integer:=0;
 file f: text open write_mode is "q.txt"; file g: text open write_mode is "au.txt";
begin
 c<=not c after 5 ns when not stop else '0';
 u: entity work.hdmi_tx generic map(true) port map(c,h,v,hs2,vs2,de2,rgb2,req,au,q0,q1,q2);
 hs<='0' when h>=736 and h<=797 else '1';
 vs<='0' when (v>489 or (v=489 and h>=736)) and (v<=494 or (v=495 and h<736)) else '1';
 de<='1' when h<720 and v<480 else '0';
 rgb<=std_logic_vector(resize(h*7+v*13,8)) & std_logic_vector(resize(h+v*3,8)) & std_logic_vector(resize(h*5,8));
 process(c) variable l: line; variable a: unsigned(15 downto 0):=x"1234"; begin if rising_edge(c) then
  if h=857 then h<=(others=>'0'); if v=524 then v<=(others=>'0'); else v<=v+1; end if; else h<=h+1; end if;
  hs1<=hs; vs1<=vs; de1<=de; rgb1<=rgb; hs2<=hs1; vs2<=vs1; de2<=de1; rgb2<=rgb1;
  rq<=req; if rq/=req then a:=a(14 downto 0)&(a(15) xor a(13) xor a(12) xor a(10)); au<=std_logic_vector(a); write(l,to_integer(a)); writeline(g,l); end if;
  write(l,q0);write(l,' ');write(l,q1);write(l,' ');write(l,q2);write(l,' ');write(l,hs2);write(l,vs2);write(l,de2);write(l,' ');hwrite(l,rgb2);writeline(f,l);
  n<=n+1; if n=480000 then stop<=true; end if;
 end if; end process;
end;
