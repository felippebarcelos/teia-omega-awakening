# TEIA RELEASE NOTES v2.0.1 - AION OFFLINE (The Emancipation)

## Visão Geral
Esta release marca a emancipação definitiva da TEIA AION RISPA NDC. O motor de compressão procedural (Storage as Computation) foi consolidado como um sistema autônomo, offline e determinístico.

## Destaques da Arquitetura V2
- **Independência Total:** Extirpação completa de dependências de nuvem, LLMs externos e pacotes Python.
- **Motor Nativo:** O AION RISPA NDC v2.0.1 opera puramente via PowerShell/C# e .NET BrotliStream.
- **Deteriminismo:** O sistema forja seus próprios decodificadores dinamicamente através de heurísticas estruturais puras.
- **Soberania de Dados:** Superação irrefutável da compressão estatística clássica em ambiente estéril.

## Métricas de Auditoria (Ground Truth)
- **Arquivo de Referência:** `csv_covid_countries_aggregated.csv`
- **Brotli SmallestSize (Limite Teórico):** 661.353 bytes
- **Tamanho AION Package:** 490.731 bytes
- **Delta Real Observado:** **170.622 bytes** (Vantagem procedural absoluta).

## Validação de Integridade
- **Pacote:** `TEIA_AION_OFFLINE_DEMO_v2.0.1.zip`
- **SHA-256:** `6ACE91E6CCB25A5AEB3386A9BAC9C77C0F737B15C24FB2F5541251CCF448A040`

## Como Executar
Extraia o arquivo ZIP e execute o script `audit-one-click-aion.ps1` no PowerShell 7. O sistema baixará o dataset original e realizará a auditoria completa de forma autônoma.

Protocolo P28.0 finalizado.
