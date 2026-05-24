# OntoProcedural Pack (ESP32 + MicroPython + PowerShell)

Arquitetura mínima para execução determinística orientada a **manifesto ontoprocedural** em ESP32,
com orquestração por **PowerShell** no host.

## Conteúdo
- `esp32_onto_procedural.py` — núcleo MicroPython: ações registradas, prioridade, SHA256, log, JLines.
- `manifest_seed.json` — exemplo de manifesto com 6 tarefas.
- `onto_procedural_host.ps1` — orquestrador host (TEIA textdoc embed Codex).
- `README.md` — este arquivo.

## Requisitos
- ESP32 com **MicroPython** gravado (versão recente).
- Host com **PowerShell 7+**, **Python 3** e `mpremote` (`pip install mpremote`).

## Fluxo
1. Conecte o ESP32 via USB.
2. No PowerShell, execute `.\onto_procedural_host.ps1` (na pasta dos arquivos).
3. O script envia os arquivos e executa o manifesto no board.
4. A saída aparece no console em **linhas JSON**; o log local é salvo em `/log_onto.txt` no ESP32.

## Extensão
- Adicione novas ações no registro `REG.register("nome", func)`.
- Crie seus próprios manifestos e execute: `Run-Manifest ... "/seu_manifesto.json"`.

## 4 linhas (uso rápido)
1) `pip install mpremote`
2) Conecte o ESP32 com MicroPython
3) `.\onto_procedural_host.ps1`
4) Observe JSON no console e `/log_onto.txt` no board
