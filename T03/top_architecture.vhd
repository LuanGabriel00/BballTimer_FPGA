library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.rom.ALL; 

entity cron_dec is
    generic ( CLOCK_FREQ : integer := 50_000_000 );
    port(
        ucf_clock           : IN  STD_LOGIC;
        ucf_reset           : IN  STD_LOGIC;
        ucf_carga           : IN  STD_LOGIC;
        ucf_modo_novoQuarto : IN  STD_LOGIC; 
        ucf_para_continua   : IN  STD_LOGIC;
        ucf_SW_QT           : IN  STD_LOGIC_VECTOR (1 downto 0);
        ucf_SW_MIN          : IN  STD_LOGIC_VECTOR (3 downto 0);
        ucf_SW_SEG          : IN  STD_LOGIC_VECTOR (1 downto 0);
        ucf_LD_MIN          : OUT STD_LOGIC_VECTOR (3 downto 0);
        ucf_LD_QT           : OUT STD_LOGIC_VECTOR (3 downto 0);
        ucf_dec_ddp         : OUT STD_LOGIC_VECTOR (7 downto 0);
        ucf_an              : OUT STD_LOGIC_VECTOR (3 downto 0)
    );
end cron_dec;

architecture cron_dec of cron_dec is
   
    -- Sinais para receber os botões "limpos" pelo Debounce
    signal deb_carga           : STD_LOGIC;
    signal deb_modo_novoQuarto : STD_LOGIC;
    signal deb_para_continua   : STD_LOGIC;

    -- Sinais de saída do Cronômetro (Cérebro)
    signal out_quarto     : INTEGER RANGE 4 DOWNTO 1;
    signal out_minutos    : INTEGER RANGE 99 DOWNTO 0; 
    signal out_segundos   : INTEGER RANGE 59 DOWNTO 0;
    signal out_centesimos : INTEGER RANGE 99 DOWNTO 0;

    -- Sinais de conversão BCD para o Display
    signal segundos_BCD   : STD_LOGIC_VECTOR(7 downto 0);
    signal centesimos_BCD : STD_LOGIC_VECTOR(7 downto 0);

    signal conv_QT  : INTEGER RANGE 4 DOWNTO 0;
    signal conv_SEG : INTEGER RANGE 59 DOWNTO 0;
    
    -- Bypass do Debouncer para ler o botão segurado durante o Reset
    signal sinal_modo_misto : STD_LOGIC;
    
    -- Barramentos fatiados para o Driver do Display
    signal s_d3, s_d2, s_d1, s_d0 : STD_LOGIC_VECTOR (5 downto 0);

begin 
    deb_inst_carga: entity work.Debounce
        generic map (DIVISION_RATE => 4)
        port map (
            clock  => ucf_clock,
            reset  => ucf_reset,
            key    => ucf_carga,
            debkey => deb_carga
        );

    deb_inst_modo: entity work.Debounce
        generic map (DIVISION_RATE => 4)
        port map (
            clock  => ucf_clock,
            reset  => ucf_reset,
            key    => ucf_modo_novoQuarto,
            debkey => deb_modo_novoQuarto
        );

    deb_inst_para: entity work.Debounce
        generic map (DIVISION_RATE => 4) 
        port map (
            clock  => ucf_clock,
            reset  => ucf_reset,
            key    => ucf_para_continua,
            debkey => deb_para_continua
        );

    -- Bypass do Debouncer durante o Reset para conseguir ler o botão segurado!
    sinal_modo_misto <= ucf_modo_novoQuarto when ucf_reset = '1' else deb_modo_novoQuarto;
   
    reader: entity work.cronometro 
        generic map ( CLOCK_FREQ => CLOCK_FREQ )
        port map (
             cron_clock           => ucf_clock,
             cron_reset           => ucf_reset,
             cron_carga           => deb_carga,              
             cron_modo_novoQuarto => sinal_modo_misto,  -- AQUI: USA O SINAL MISTO
             cron_para_continua   => deb_para_continua,      
             cron_SW_QT           => conv_QT,
             cron_SW_MIN          => ucf_SW_MIN,
             cron_SW_SEG          => conv_SEG,
             cron_stop            => open, 
             quarto_saida         => out_quarto,
             min_saida            => out_minutos,
             seg_saida            => out_segundos,
             cent_saida           => out_centesimos
        );

    -- Conversão de Inteiro para Vetor Binário para os Minutos (Mostra nos LEDs)
    ucf_LD_MIN <= conv_std_logic_vector(out_minutos, 4);

    -- "One-Hot Encoding" para indicar os Quartos
    with out_quarto select
        ucf_LD_QT <= "0001" when 1, -- Q1: LED 4 aceso
                     "0010" when 2, -- Q2: LED 3 aceso
                     "0100" when 3, -- Q3: LED 2 aceso
                     "1000" when 4, -- Q4: LED 1 aceso
                     "0000" when others;
                     
    -- Conversão das chaves físicas de Quarto
    with ucf_SW_QT select
         conv_QT <= 1 when "00", 
                    2 when "01", 
                    3 when "10", 
                    4 when "11", 
                    0 when others;

    -- Conversão da Carga de Segundos para frações de 15s
    with ucf_SW_SEG select
        conv_SEG <= 0  when "00", 
                    15 when "01",  
                    30 when "10",   
                    45 when "11",
                    0  when others;
                    
    -- A ROM converte Segundos e Centésimos
    segundos_BCD   <= conv_to_BCD(out_segundos);
    centesimos_BCD <= conv_to_BCD(out_centesimos);

    -- Formatação para o driver: '1' (Enable) & Valor BCD & '1' (Ponto Desligado) / '0' (Ponto Ligado)
    s_d3 <= '1' & segundos_BCD(7 downto 4)   & '1'; -- Dezena dos Segundos
    s_d2 <= '1' & segundos_BCD(3 downto 0)   & '0'; -- Unidade dos Segundos (Ponto DECIMAL LIGADO)
    s_d1 <= '1' & centesimos_BCD(7 downto 4) & '1'; -- Dezena dos Centésimos
    s_d0 <= '1' & centesimos_BCD(3 downto 0) & '1'; -- Unidade dos Centésimos

    display_driver : entity work.dspl_drv
        port map(
            dsp_an      => ucf_an, 
            dsp_dec_ddp => ucf_dec_ddp, 
            dsp_d0      => s_d0,
            dsp_d1      => s_d1,
            dsp_d2      => s_d2,
            dsp_d3      => s_d3,
            dsp_clock   => ucf_clock, 
            dsp_reset   => ucf_reset
        );
    
end cron_dec;