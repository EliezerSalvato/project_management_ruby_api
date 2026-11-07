# Decisões Técnicas

Este documento lista as principais tecnologias usadas no projeto e o motivo de cada escolha.

## Linguagem e framework

### Ruby 3.4.12
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

### Paginação por cursor (keyset)
A listagem de projetos é paginada por cursor (parâmetro `after` e `next_cursor` na resposta), 20 itens por página, sem gems de paginação.
Diferente da paginação por `OFFSET`, a performance não cai nas páginas mais distantes e os itens não se repetem nem somem quando projetos são criados ou removidos entre uma página e outra.

### Ordenação
As ordenações disponíveis ficam em uma lista fechada em `Project::Sort` (`name`, `recent_start`, `nearest_deadline`), e o cliente não consegue ordenar por colunas arbitrárias.
Cada ordenação define as expressões que geram o `ORDER BY` e a comparação do cursor, o que mantém as duas sempre iguais. O `id` é o último critério de desempate, então a ordem é sempre determinística.
Nas ordenações por data, projetos atrasados vão para o final, e a data de referência ("hoje") usa o fuso horário do projeto (`America/Sao_Paulo`).

### Busca
A busca procura o termo tanto no nome do projeto quanto no nome do cliente. Usa `ILIKE` com a extensão `unaccent` do PostgreSQL, que ignora maiúsculas, minúsculas e acentos (buscar "joao" encontra "João").
Para o MVP atual a busca resolve bem, sem depender de serviços externos. Se o volume de dados crescer ou surgir a necessidade de busca por relevância ou tolerância a erros de digitação, será preciso avaliar alternativas como o Elasticsearch.

### rack-cors
Configura o CORS para que o front-end (em outro domínio/porta) consuma a API de forma segura, permitindo apenas as origens configuradas.

### rack-attack
Rate limiting por IP, com limite mais rígido no endpoint de login. Protege contra força bruta e abuso da API.

### OpenAPI + Redoc
A documentação da API fica em `public/openapi/` (especificação OpenAPI) e é exibida via Redoc em `/docs`.
Isso deixa um contrato claro para quem consome a API e facilita a integração com o front-end.
A documentação existe em dois idiomas, inglês e português (`public/openapi/pt-BR/`), com um seletor de idioma no Redoc. As duas versões têm os mesmos arquivos e a mesma estrutura, mudando só o texto.

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

### Desenvolvimento orientado a especificação (SDD)
As funcionalidades são desenvolvidas com Spec-Driven Development usando a skill `tlc-spec-driven`, uma das skills de SDD mais completas da atualidade e sempre atualizada com as melhores práticas do momento.
Antes do código, cada funcionalidade passa por especificação com requisitos testáveis, design, tarefas atômicas e, no final, uma verificação de cada critério de aceite com o teste que o comprova. Os artefatos ficam em `.specs/features/` (por exemplo, `.specs/features/projects/`).

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
