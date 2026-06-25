LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY tb_cron_basq IS
END tb_cron_basq;

ARCHITECTURE behavior OF tb_cron_basq IS 

   -- Entradas
   signal ucf_clock           : std_logic := '1';
   signal ucf_reset           : std_logic := '0';
   signal ucf_carga           : std_logic := '0';
   signal ucf_modo_novoQuarto : std_logic := '0';
   signal ucf_para_continua   : std_logic := '0';
	
	-- Chaves Deslizantes (Iniciando zeradas)
   signal ucf_SW_QT           : std_logic_vector(1 downto 0) := "00";
   signal ucf_SW_MIN          : std_logic_vector(3 downto 0) := "0000";
   signal ucf_SW_SEG          : std_logic_vector(1 downto 0) := "00";

   -- Saídas
   signal ucf_LD_MIN          : std_logic_vector(3 downto 0);
   signal ucf_LD_QT           : std_logic_vector(3 downto 0);

BEGIN
ucf_clock <= not ucf_clock after 10 ns;

   -- 2. Instância do Top-Level (Sua Placa Mãe)
   uut: entity work.cron_dec
      generic map (
         -- ATENÇÃO CRÍTICA AQUI: O valor MÍNIMO agora tem que ser 100! 
         -- Porque a matemática do centésimo faz (CLOCK_FREQ / 100).
         CLOCK_FREQ => 500 
      )
      port map (
		ucf_clock           => ucf_clock,
		ucf_reset           => ucf_reset,
		ucf_carga           => ucf_carga,
		ucf_modo_novoQuarto => ucf_modo_novoQuarto,
		ucf_para_continua   => ucf_para_continua,
		ucf_SW_QT           => ucf_SW_QT,
		ucf_SW_MIN          => ucf_SW_MIN,
		ucf_SW_SEG          => ucf_SW_SEG,
		ucf_LD_MIN          => ucf_LD_MIN,
		ucf_LD_QT           => ucf_LD_QT,
		ucf_dec_ddp         => open, -- Ignoramos o display para focar na lógica
		ucf_an              => open  
	);
	stim_proc: process
   begin
      -- FASE 1: Reset inicial no Modo NBA (Modo/NovoQuarto solto = 12 mins)
      ucf_reset <= '1';
      wait for 100 ns;
      ucf_reset <= '0';
      wait for 500 ns;
		
		ucf_para_continua <= '1';
      wait for 120 ns; 
      ucf_para_continua <= '0';
		
		wait for 1000 ns;

      -- FASE 3: Teste da Carga (Pular para o final do Quarto)
      -- Primeiro, paramos o cronômetro
      ucf_para_continua <= '1';
      wait for 120 ns;
      ucf_para_continua <= '0';
      wait for 1000 ns;
		
		ucf_SW_QT  <= "01";   
      ucf_SW_MIN <= "0000"; 
      ucf_SW_SEG <= "11";   
      
      -- Apertamos Carga
      ucf_carga <= '1';
      wait for 120 ns;
      ucf_carga <= '0';
      wait for 100 ns;

      -- Voltamos a ligar o cronômetro
      ucf_para_continua <= '1';
      wait for 120 ns;
      ucf_para_continua <= '0';
		
		wait for 8000 ns;

      -- FASE 4: Troca de Quarto
      -- Quando a contagem morrer em 00:00:00, apertamos Novo Quarto
      ucf_modo_novoQuarto <= '1';
      wait for 120 ns;
      ucf_modo_novoQuarto <= '0';

      -- A simulação acaba e ele deve voltar para o Q2, com 12:00:00 na tela.
      wait;
   end process;

END behavior;
	