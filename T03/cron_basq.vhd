library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity cronometro is
generic ( clock_FREQ : integer := 50_000_000 );
port( 
    cron_clock          : in STD_LOGIC;
    cron_reset          : in STD_LOGIC;
    cron_para_continua   : in STD_LOGIC;
    cron_carga           : in STD_LOGIC;
    cron_modo_novoQuarto : in STD_LOGIC; 
    cron_SW_QT           : IN INTEGER RANGE 4 DOWNTO 0;
    cron_SW_MIN          : IN STD_LOGIC_VECTOR (3 downto 0);
    cron_SW_SEG          : IN INTEGER RANGE 59 DOWNTO 0;
    cron_stop           : out STD_LOGIC;
    quarto_saida        : out integer range 4 DOWNTO 1; 
    min_saida           : out integer range 99 DOWNTO 0;
    seg_saida           : out integer range 59 DOWNTO 0;
    cent_saida          : out integer range 99 DOWNTO 0  
); 
end cronometro;

architecture cronometro of cronometro is

    type states is (PARADO, CONTANDO, FIM_QUARTO); 
    signal pst, nst : states; -- Present State e Next State
    
    signal clock_cent : STD_LOGIC := '0';
    signal contador   : INTEGER range 0 to clock_FREQ := 0;
    
    signal centesimos : INTEGER RANGE 99 DOWNTO 0 := 0;    
    signal segundos   : INTEGER RANGE 59 DOWNTO 0 := 0;
    signal minutos    : INTEGER RANGE 12 DOWNTO 0 := 12;
    signal quarto     : INTEGER RANGE 4 DOWNTO 0  := 1;
    
    signal is_fiba    : STD_LOGIC := '0'; 

begin

DIVISOR:
process(cron_clock)
begin
    if rising_edge(cron_clock) then
        if contador = ((clock_FREQ / 100) - 1) then 
            clock_cent <= '1';
            contador <= 0;
        else
            contador <= contador + 1;
            clock_cent <= '0';
         end if;
    end if;
end process;

ESTADO:
process(cron_clock, cron_reset)
begin
    if cron_reset = '1' then
        pst <= PARADO;
    elsif rising_edge(cron_clock) then
        pst <= nst;
    end if;
end process;

NEXT_STATE:
process(pst, cron_para_continua, minutos, segundos, centesimos, cron_modo_novoQuarto, quarto)
begin
    nst <= pst;   
    case pst is 
        when PARADO =>
            if cron_para_continua = '1' then
                nst <= CONTANDO;
            end if;
        when CONTANDO =>
            if cron_para_continua = '1' then
                nst <= PARADO;
            elsif minutos = 0 and segundos = 0 and centesimos = 0 then
                nst <= FIM_QUARTO;
            end if;
            
        when FIM_QUARTO =>
            if cron_modo_novoQuarto = '1' and quarto < 4 then
                nst <= PARADO;
            end if;
    end case;
end process;

DADOS:
process(cron_clock, cron_reset)
begin
    if cron_reset = '1' then
        quarto <= 1;
        centesimos <= 0;
        segundos <= 0;
        cron_stop <= '0';
        
        if cron_modo_novoQuarto = '1' then
            is_fiba <= '1';
            minutos <= 10;
        else
            is_fiba <= '0';
            minutos <= 12;
        end if;
        
    elsif rising_edge(cron_clock) then
        
        -- Carga
        if pst = PARADO and cron_carga = '1' then
            quarto <= cron_SW_QT;
            minutos <= conv_integer(cron_SW_MIN);
            segundos <= cron_SW_SEG;
            centesimos <= 0;
        end if;
        
        -- Transição de Novo Quarto
        if pst = FIM_QUARTO and cron_modo_novoQuarto = '1' and quarto < 4 then
            quarto <= quarto + 1;
            centesimos <= 0;
            segundos <= 0;
            cron_stop <= '0';
            
            if is_fiba = '1' then
                minutos <= 10;
            else
                minutos <= 12;
            end if;
        end if;
        
        --  Decremento 
        if pst = CONTANDO then
            if minutos = 0 and segundos = 0 and centesimos = 0 then
                cron_stop <= '1';
            elsif clock_cent = '1' then
                if centesimos = 0 then
                    centesimos <= 99;
                    if segundos = 0 then
                        segundos <= 59;
                        minutos <= minutos - 1;
                    else 
                        segundos <= segundos - 1;
                    end if;
                else
                    centesimos <= centesimos - 1;
                end if;
            end if;
        end if;
        
    end if;
end process;
    
--saídas 
quarto_saida <= quarto;
min_saida    <= minutos;
seg_saida    <= segundos;
cent_saida   <= centesimos;

end cronometro;