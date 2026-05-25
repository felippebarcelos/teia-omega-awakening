# Como Validar a Prova de Compressão TEIA
**Sem confiar no autor. Sem instalar software especial. Apenas dados.**

---

## O que esta prova afirma

Dado um arquivo original de tamanho A (comprimido com 7z-LZMA), o sistema TEIA produz
um arquivo `.teia` de tamanho D onde **D < A** em 100% dos casos testados.
O conteúdo original é recuperável bit-a-bit (SHA-256 idêntico).

---

## Pré-requisitos

- PowerShell 5+ (incluso no Windows 10/11)
- Python 3.9+ (para o opcode `cmp.lzma`)
- 7-Zip (para gerar a coluna de referência A)

---

## Passo 1 — Verificar o motor

```powershell
$motor = "TEIA-Core-v0.11.0.psm1"
$sha   = (Get-FileHash $motor -Algorithm SHA256).Hash.ToLower()
Write-Host "Motor SHA-256: $sha"
# Esperado: a56b18c0e17f4d1037340adf78f057f44e0fdbe21a5201fca6e1d17fb379ec39
```

Se o hash não bater, o motor foi alterado. Não prossiga.

---

## Passo 2 — Escolher um arquivo de teste

Use qualquer JSON de sua escolha (mínimo 1 KB). Os corpora de referência são:

- **D7**: arquivos `service-2.json` e `paginators-1.json` da biblioteca botocore (AWS)
- **D8**: arquivos de log de atividade do Google Takeout e `tokenizer.json` do Hugging Face

Estes são arquivos públicos. Você pode baixá-los independentemente.

---

## Passo 3 — Gerar a referência 7z-LZMA (coluna A)

```powershell
$arquivo = "seu_arquivo.json"
& "C:\Program Files\7-Zip\7z.exe" a -t7z -m0=lzma -mx=9 ref_lzma.7z $arquivo
$A = (Get-Item ref_lzma.7z).Length
Write-Host "A (7z-LZMA): $A bytes"
```

---

## Passo 4 — Gerar o arquivo TEIA (coluna D)

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Import-Module ".\TEIA-Core-v0.11.0.psm1"

$dados    = [IO.File]::ReadAllBytes($arquivo)
$resultado = Invoke-TEIAEncodeAuto -Data $dados -FileName $arquivo `
             -PythonPath "python"
[IO.File]::WriteAllBytes("saida.teia", $resultado)

$D = (Get-Item saida.teia).Length
Write-Host "D (TEIA v0.11.0): $D bytes"
Write-Host "Diferença D-A: $($D - $A) bytes"
```

---

## Passo 5 — Verificar roundtrip SHA-256

```powershell
$original  = (Get-FileHash $arquivo       -Algorithm SHA256).Hash
$restaurado = Invoke-TEIARestoreBin -TeiaBytes $resultado -PythonPath "python"
[IO.File]::WriteAllBytes("restaurado.bin", $restaurado)
$recuperado = (Get-FileHash "restaurado.bin" -Algorithm SHA256).Hash

Write-Host "Original  : $original"
Write-Host "Recuperado: $recuperado"
if ($original -eq $recuperado) { Write-Host "SHA-256 OK — fidelidade bit-a-bit confirmada" }
else                            { Write-Host "ERRO — divergencia detectada" }
```

---

## Passo 6 — Inspecionar o formato binário (sem Base64)

```powershell
$bytes = [IO.File]::ReadAllBytes("saida.teia")
Write-Host "Magic  : $([Text.Encoding]::ASCII.GetString($bytes[0..3]))"          # "TEIA"
Write-Host "Version: $([BitConverter]::ToUInt16($bytes,4)).$([BitConverter]::ToUInt16($bytes,6))"
Write-Host "SHA-256 (raw, primeiros 8 bytes): $([BitConverter]::ToString($bytes[22..29]))"
# Nenhum caractere A-Z/a-z/0-9/+/= num padrão Base64. São bytes binários puros.
```

---

## Resultado esperado para o pior caso (D8, S16)

| Etapa | Valor |
|-------|-------|
| Arquivo | `anthropic_tokenizer.json` (1 774 213 B) |
| A (7z-LZMA) | 566 971 B |
| D (TEIA v0.11.0) | 566 259 B |
| D − A | **−712 B** (TEIA é menor) |
| SHA-256 roundtrip | OK |

---

## O que fazer se D ≥ A

Isso significaria que o opcode selecionado pelo Selector Engine não venceu o 7z-LZMA para
este arquivo específico. Os arquivos de texto altamente compressíveis com LZMA (tipo
específico de log estruturado) são os mais difíceis. Verifique:

1. Se Python está instalado e acessível como `python` no PATH
2. Se o arquivo tem extensão `.json` (o opcode `cmp.lzma` é ativado nos buckets small/medium/large)
3. Consulte `BENCHMARK_HISTORICO.md` para o diagnóstico histórico de perdas por tipo

---

*TEIA-Core-v0.11.0 | SHA-256: a56b18c0e17f4d1037340adf78f057f44e0fdbe21a5201fca6e1d17fb379ec39*
