# Decisões Técnicas

Este documento lista as principais tecnologias usadas no projeto e o motivo de cada escolha.

## Linguagem e framework

### Ruby 3.4.5
Versão estável mais recente da linguagem, com ganhos de desempenho (YJIT) e melhorias de sintaxe.
Usar uma versão atual facilita manutenção e atualizações de segurança.

### Rails 8.1 (modo API)
Framework maduro, produtivo e com convenções bem definidas. O modo API remove o que não é necessário para uma aplicação sem views (assets, helpers de front-end), deixando a aplicação mais enxuta. O ecossistema de gems e a comunidade grande reduzem o tempo de desenvolvimento.

## Banco de dados

### PostgreSQL 18
Banco relacional robusto, confiável e com recursos avançados (JSONB). A versão 18 traz a função nativa `uuidv7()`.

### UUID v7 como chave primária
As chaves primárias usam UUID v7 por padrão (`config/initializers/uuid_v7_default.rb`). Diferente de IDs sequenciais, não expõem a quantidade de registros nem permitem enumeração.
Diferente do UUID v4, são ordenáveis por tempo, o que mantém a boa performance dos índices.

## Camada de API

### jsonapi-serializer
Serialização rápida e declarativa dos recursos, seguindo a especificação JSON:API.
Mantém o formato das respostas consistente e separa a apresentação dos models.

### Pagy
Paginação leve e rápida, com baixo consumo de memória quando comparada a alternativas como Kaminari e will_paginate.

### Ransack
Filtros e ordenação de coleções a partir de parâmetros da requisição, sem precisar escrever queries manualmente para cada combinação.

### rack-cors
Configura o CORS para que o front-end (em outro domínio/porta) consuma a API de forma segura, permitindo apenas as origens configuradas.

### rack-attack
Rate limiting por IP, com limite mais rígido no endpoint de login. Protege contra força bruta e abuso da API.

### OpenAPI + Redoc
A documentação da API fica em `public/openapi/` (especificação OpenAPI) e é exibida via Redoc em `/docs`.
Isso deixa um contrato claro para quem consome a API e facilita a integração com o front-end.

## Autenticação e segurança

### bcrypt + `has_secure_password`
Hash de senhas com bcrypt, algoritmo lento por design e resistente a ataques de força bruta.
A integração nativa com Rails evita dependências extras.

### Tokens assinados + refresh token em cookie
O token de sessão é gerado com `signed_id` / `generates_token_for` do próprio Rails, sem depender de gems de JWT.
O refresh token fica em um cookie criptografado e HTTP-only, o que reduz o risco de roubo via XSS.

### Brakeman
Análise estática de segurança específica para Rails, que encontra vulnerabilidades comuns (SQL injection, mass assignment, etc.).

### bundler-audit
Verifica se alguma gem instalada tem vulnerabilidades conhecidas.

## Arquitetura

### Form objects (`ApplicationForm`)
As regras de negócio ficam em form objects nomeados pelo caso de uso (`User::Registration`, `User::Authentication`, etc.), em vez de services ou models gordos. Assim os controllers ficam finos, os models ficam focados em persistência e cada caso de uso tem uma responsabilidade única. Também aproveita o ActiveModel (validações, erros, I18n) sem precisar de bibliotecas extras.

### Controllers finos e versionamento (`/api/v1`)
Controllers só orquestram a requisição e a resposta. O versionamento permite evoluir a API sem quebrar clientes existentes.

## Internacionalização

### rails-i18n
Traduções padrão do Rails (mensagens de validação, datas, etc.) para vários idiomas.

### i18n-tasks
Encontra chaves de tradução faltando ou sem uso, mantendo os arquivos de locale organizados.

## E-mail

### Action Mailer + Mailpit
Os e-mails (confirmação, redefinição de senha) são enviados com Action Mailer e `deliver_later`, sem bloquear a requisição.
Em desenvolvimento, o Mailpit captura os e-mails e mostra numa interface web.

## Testes e qualidade

### RSpec
Framework de testes com sintaxe expressiva e amplamente adotado na comunidade Rails. Request specs são a principal forma de cobertura dos endpoints.

### FactoryBot + Faker
FactoryBot cria dados de teste de forma declarativa e reutilizável. Faker gera dados realistas e variados.

### SimpleCov
Mede a cobertura de testes, o que ajuda a identificar partes do código sem testes.

### RuboCop (rails-omakase)
Padroniza o estilo de código com as convenções oficiais do Rails, reduzindo discussões de estilo em code review.

## Infraestrutura e ambiente

### Docker + Docker Compose
Ambiente de desenvolvimento reproduzível, com a API, o PostgreSQL e o Mailpit em containers. Simplifica o onboarding.

### dotenv-rails
Carrega variáveis de ambiente a partir do arquivo `.env`, mantendo configurações e segredos fora do código.
Simplifica o onboarding, removendo a necessidade de configurar credenciais no ambiente de desenvolvimento.

### GitHub Actions
Pipeline de CI que roda testes, lint e verificações de segurança a cada push e pull request, garantindo a qualidade antes do merge.
