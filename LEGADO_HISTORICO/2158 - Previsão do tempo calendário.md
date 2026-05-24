# 2158 - Previsão do tempo calendário

### USUÁRIO

Há alguma possibilidade de inserir no calendário do Google, ou no calendário da Apple, a inserção de previsão do tempo em cada dia do calendário? Mostrando a previsão dos dias que temos conhecimento linear de previsão do tempo para os próximos dias. Obrigado por assistir.

---

### ASSISTENTE

Sim — dá para ter a previsão do tempo “dentro” do Google Calendar e do Calendário da Apple. Há dois jeitos principais:

# 1) Assinar um calendário de previsão (ICS/webcal)
Vários serviços geram um link **.ics** com eventos diários contendo temperatura, condição (sol/chuva), etc. Você só assina esse link no seu calendário:

- **Google Calendar (web):** *Configurações → Adicionar calendário → A partir de URL* e cole o link `https://... .ics`. citeturn0search0  
  • Observação: o Google **atualiza assinaturas com pouca frequência** (em geral até 1× ao dia; não há como definir intervalo). Para “forçar” uma atualização, algumas pessoas usam o truque de resssubscrever com `#1`, `#2` no final da URL. citeturn1search2turn1search0turn1search6  
  • O recurso nativo antigo de “mostrar clima” foi removido; hoje precisa ser via terceiros/assinatura. citeturn0search9turn0search2

- **Calendário da Apple (macOS/iCloud):** *Arquivo → Nova assinatura de calendário…* cole o link `webcal://...`. Você pode escolher **iCloud** como local (sincroniza com iPhone/iPad) e definir **Auto-Atualizar** (ex.: a cada hora). Também dá para atualizar manualmente (ícone ↻). citeturn1search9turn1search11turn1search1

**Fontes para o feed ICS (exemplos):**  
- **weather-in-calendar.com** – fornece links prontos por cidade. citeturn0search7  
- **Meteomatics – Weather Calendar** – guia para adicionar previsão a Google/Outlook/iCal. citeturn0search8  
- **Outros agregadores** de “webcal/ICS” também funcionam; muitos oferecem 7–10 dias de previsão. citeturn0search18

# 2) “Faça-você-mesmo” (mais flexível)
Se quiser controle total (cidade, ícones, horários, idioma), dá para gerar você mesmo os eventos:

- **Usar uma API de tempo** (ex.: Open-Meteo, gratuita e sem API key) para obter a previsão diária/horária. citeturn0search4  
- **Publicar como calendário ICS** (ou criar eventos) via **Google Apps Script**. Há scripts prontos que sincronizam ICS com o Google Calendar e **atualizam com frequência maior** do que o assinante padrão do Google. citeturn1search10turn1search4  
- Em iOS/macOS, você pode também automatizar com **Atalhos/Shortcuts** que geram eventos com a previsão do dia. citeturn0search6

---

## O que eu recomendo para você (prático e estável)
1) Escolha um provedor de ICS (ex.: weather-in-calendar ou Meteomatics) e **assine** o feed:  
   • No Google Calendar (web): *Adicionar a partir de URL*;  
   • No Calendário da Apple (Mac): *Nova assinatura de calendário…* e defina **Auto-Atualizar**. citeturn0search7turn0search8turn1search9  
2) Use **iCloud** como local da assinatura no Mac para espalhar para iPhone/iPad automaticamente. citeturn1search11  
3) Se você precisar de **atualizações mais frequentes** no Google Calendar, considere o caminho do **Apps Script** (GAS-ICS-Sync). citeturn1search10

Se quiser, eu monto para você um feed personalizado (São Paulo/BR ou outra cidade), já com resumo diário (máx/mín, chuva, UV) — e te entrego o link `webcal://` pronto para assinar.

---

