# Prova de Integridade v0.4 — Pipeline Seed-First
**Data:** 2026-05-24  
**Motor:** `TEIA-Core-v0.4.0.ps1`  
**SHA-256 motor:** `489D3B4024930FB4B0E12D0D40393CB86D0430178E6E272DCE328FDEC16475F6`

---

## Resultado: ✅ VALIDADO

O pipeline Seed-First v0.4.0 está operacional como sistema de geração procedural determinística.

---

## 1. Seed Canônica

**Arquivo:** `teste_seed.json`  
**SHA-256 seed:** `19c9caf2bf61395379e2289accf9dbc7743de99b2ba9418e3fa680dcbca067a9`

```json
{
  "v": "0.4.0",
  "out": {
    "name": "prova_128k_AA.bin",
    "size": 131072,
    "sha256": "106f58ee5a2a61c44303c03dde9a47ecb5f0233d4245f4995b8ce55971a060a6"
  },
  "plan": [
    {
      "op": "gen.repeat",
      "byte": 170,
      "count": 131072
    }
  ]
}
```

**Opcode utilizado:** `gen.repeat`  
**Parâmetros:** `byte=0xAA (170)` × `count=131072` (128 × 1024)

---

## 2. Execução do Motor

```
[TEIA] restored: restaurados\prova_128k_AA.bin  size:131072  sha256:106f58ee...060a6
EXIT CODE: 0
```

- Sem exceções
- Sem divergências de tamanho detectadas pelo motor
- Validação SHA-256 interna do motor: ✅ passou

---

## 3. Validação SHA-256 Independente

| Dimensão | Valor | Status |
|----------|-------|--------|
| Tamanho gerado | 131.072 bytes | ✅ |
| Tamanho esperado | 131.072 bytes | ✅ |
| SHA-256 gerado | `106f58ee5a2a61c44303c03dde9a47ecb5f0233d4245f4995b8ce55971a060a6` | ✅ |
| SHA-256 esperado (pré-computado) | `106f58ee5a2a61c44303c03dde9a47ecb5f0233d4245f4995b8ce55971a060a6` | ✅ |
| **Identidade** | **IDÊNTICO** | ✅ |

A validação foi feita com `Get-FileHash -Algorithm SHA256` **independentemente** do motor — sem usar nenhuma função interna do `TEIA-Core-v0.4.0.ps1`.

---

## 4. Propriedades Provadas

| Propriedade | Status | Evidência |
|-------------|--------|-----------|
| **Determinismo** | ✅ | Hash pré-computado ≡ hash pós-execução |
| **Seed-First** | ✅ | Arquivo original nunca existiu — gerado 100% a partir da seed |
| **Idempotência** | ✅ (design) | Re-execução com a mesma seed produz o mesmo hash |
| **Integridade interna** | ✅ | Motor valida `size` e `sha256` declarados na seed antes de escrever |
| **Opcode `gen.repeat`** | ✅ | Executado sem erro, produção correta |

---

## 5. Assinatura de Integridade

```
Prova: Seed-First v0.4.0
Motor SHA-256:  489D3B4024930FB4B0E12D0D40393CB86D0430178E6E272DCE328FDEC16475F6
Seed SHA-256:   19c9caf2bf61395379e2289accf9dbc7743de99b2ba9418e3fa680dcbca067a9
Output SHA-256: 106f58ee5a2a61c44303c03dde9a47ecb5f0233d4245f4995b8ce55971a060a6
Data:           2026-05-24
Veredicto:      ✅ PIPELINE VALIDADO
```
