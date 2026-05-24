# 0163 - Integrating Sked Social with Zapier

### USUÁRIO

Conectei minha conta da Sked Social na Zapier, meu intuito é usar o plugin da zapier no chat gpt para fornecer a análise detalhada dos dados de cada rede social que vinculei ao SkedSocial para o chat fazer o processamento dos dados e fornecer sugestões de melhorias para nossa evolução continua, porém acredito que para isso precisamos criar "zaps" na integração da skedsocial com a zapier para fazer essa função... me ajude a fornecer essas informações com a skedsocial e zapier

---

### ASSISTENTE

Para ajudá-lo a integrar o Sked Social com a Zapier usando ações personalizadas do ChatGPT, precisaremos criar especificações OpenAPI para as APIs relevantes. No entanto, as APIs da Sked Social e da Zapier podem não estar publicamente documentadas ou acessíveis diretamente. Vamos abordar esta questão em duas etapas:

1. **Identificar as APIs e Endpoints Relevantes**: Precisamos primeiro identificar quais endpoints da API da Sked Social e da Zapier você deseja acessar. Isso geralmente envolve obter dados de redes sociais, como estatísticas de postagens, engajamento, etc.

2. **Criar a Especificação OpenAPI**: Com base nos endpoints identificados, criaremos uma especificação OpenAPI. Essa especificação servirá para definir como a Zapier e o ChatGPT devem interagir com as APIs da Sked Social.

Como não temos acesso direto às APIs da Sked Social e da Zapier, vou fornecer um exemplo genérico de como uma especificação OpenAPI poderia ser estruturada para um caso de uso hipotético. Você precisará adaptar este exemplo às APIs específicas que está usando.

```yaml
openapi: 3.0.0
info:
  title: SkedSocial-Zapier Integration
  description: Integrate Sked Social with Zapier for analytics and suggestions.
  version: 1.0.0
servers

---

