# GameClock_FPGA (Trabalho T3)

![Status](https://img.shields.io/badge/Status-Conclu%C3%ADdo-brightgreen)
![Language](https://img.shields.io/badge/Language-VHDL-blue)
![Platform](https://img.shields.io/badge/Platform-FPGA%20Nexys-orange)

**Disciplina:** Projeto e Prototipação de Circuitos Digitais - UFSC

## Descrição
Sistema digital completo de um cronômetro para jogos de basquete, evoluindo a arquitetura básica do temporizador decrescente[cite: 1]. O sistema controla os quartos de jogo e lida com temporizações específicas das principais ligas do esporte[cite: 1].

## Plataforma e Hardware
* Placa: Digilent Nexys 1 ou Nexys 2.
* Clock Principal: 50 MHz (utilizado de forma unificada para acionar todas as partes do hardware, eliminando clocks lentos.
* Filtro: Implementação de módulo Debounce para leitura precisa dos apertos de botões humanos.

## Funcionalidades Principais
* Precisão: Contagem decrescente visível com precisão de centésimos de segundo.
* Controle de Quartos: Exibição do quarto atual (Q1 a Q4) em ordem crescente utilizando LEDs com codificação 1-hot.
* Regras de Ligas: Suporte à inicialização de tempos baseados na FIBA (10 minutos) ou NBA (12 minutos).
* Parada Automática: O cronômetro para e zera ao final de cada quarto e, no Q4, encerra a partida impossibilitando o avanço para um próximo quarto.

## Controles
* reset: Reinicia o jogo no Q1 com a contagem inicial padrão (modo FIBA ou NBA).
* modo_novoquarto: Define o modo de jogo (se acionado junto ao reset) ou avança o jogo para o próximo quarto com o relógio congelado.
* para_continua: Inicia, pausa ou retoma a contagem do tempo a partir de onde parou.
* carga: Lê manualmente configurações personalizadas nas chaves (quarto, minutos e segundos) quando o tempo está parado.
