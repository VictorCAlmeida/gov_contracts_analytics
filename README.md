# Gov_contracts_analytics

Pipeline analítico end-to-end para auditoria, sanitização e modelagem de contratações públicas federais (PNCP). Desenvolvimento de Data Warehouse em MySQL e dashboard executivo para apoiar a controladoria pública.

---

## 🎯 Sobre o projeto
Este projeto consiste num pipeline de **ETL (Extract, Transform, Load)** desenvolvido para processar, higienizar e estruturar dados públicos de contratações do **PNCP (Portal Nacional de Contratações Públicas)**. Os dados transformados foram modelados num **Modelo Estrela (Star Schema)** e persistidos numa base de dados relacional **MySQL**, servindo de base para auditorias, análises de conformidade e visualizações de inteligência de negócio.

---

## 🛠️ Planejamento e progresso do projeto (Sprints)

| Sprint | Objetivo Principal | Tarefas Principais | Status | Done |
|---|---|---|---|---|
| **Sprint 0** | Configuração e Entendimento | Criar repositório GitHub, estrutura de pastas e analisar os CSVs brutos. | Concluído | Pastas criadas (`src`, `sql`, `powerbi`, `docs/img`, `data/raw`) e dicionário de anomalias mapeado. |
| **Sprint 1** | Auditoria dos Dados | Mapear e anotar no `README.md` os problemas da base (nulos ocultos, CNPJs sujos, datas invertidas). | Concluído | Anomalias documentadas com contagem de registros afetados. |
| **Sprint 2** | Limpeza em Python | Completar os scripts de higienização (`src/limpeza.py`). | Concluído | O autoteste em Python (`python -m src.limpeza`) mostra sucesso (✓) em todos os exemplos. |
| **Sprint 3** | Montagem das Tabelas | Aplicar regras de negócio, grão da fato, filtros, perfil do gasto e comparabilidade (`src/montar_tabelas.py`). | Concluído | Linhas e somas batem com os números de conferência da Prova Real. |
| **Sprint 4** | Banco de Dados e Carga | Escrever `sql/01_criar_banco.sql` (Star Schema) e automatizar a carga em lote (`src/carregar.py`). | Concluído | Contagens no MySQL idênticas aos arquivos e zero chaves estrangeiras (FK) soltas. |
| **Sprint 5** | Perguntas de Negócio (SQL) | Escrever as consultas em `sql/02_perguntas.sql` para responder à Controladoria. | Em andamento | Consultas rodando no MySQL Workbench retornando os resultados esperados. |
| **Sprint 6** | Dashboard no Power BI | Criar Calendário DAX, 15 medidas obrigatórias e estruturar as 6 páginas da história. | A fazer | Painel interativo respondendo às perguntas com menu, tooltips e design limpo. |
| **Sprint 7** | Documentação e Vídeo | Escrever o `README.md`, salvar a imagem das Sprints em `docs/img/sprints.png` e gravar o vídeo de review. | A fazer | Repositório público documentado, link do vídeo no Google Drive e entrega pronta. |

---

## 🏛️ Arquitetura do modelo estrela (Star Schema)
O Data Warehouse foi estruturado com uma tabela de factos central rodeada por quatro dimensões essenciais:

* **`fato_item_contratado`** (Tabela de Factos): Contém os itens contratados, métricas financeiras (valores estimados vs. homologados), prazos do ciclo de compras e chaves estrangeiras.
* **`dim_orgao`**: Informações normalizadas sobre os órgãos públicos contratantes (Poder, CNPJ e Nome).
* **`dim_fornecedor`**: Dados dos fornecedores/contratados (identificação, tipo de pessoa e porte).
* **`dim_modalidade`**: Classificação das modalidades de contratação.
* **`dim_localidade`**: Agrupamento geográfico por UF e região.

---

## 🧹 Regras de qualidade de dados e limpeza
Durante a fase de transformação (`limpeza.py`), foram aplicadas rigorosas regras de engenharia de dados:

1. **Tratamento de Nulos Ocultos**: Identificação e normalização de strings vazias ou nulos mascarados para instâncias consistentes (`NaN`/`None`).
2. **Normalização de Documentos**: Padronização e formatação limpa de CNPJ, CPF e identificadores (`PE`).
3. **Sanitização Monetária**: Conversão de campos de texto financeiro em formatos numéricos decimais precisos (`DECIMAL`), eliminando inconsistências de símbolos e pontuação.
4. **Remoção de Outliers**: Filtragem de valores anómalos ou distorcidos que pudessem comprometer a análise agregada.
5. **Classificação de Perfis de Gasto**: Aplicação de expressões regulares (`Regex`) para categorizar automaticamente o perfil dos gastos públicos.

---

## 🔍 Consultas de auditoria (Controladoria)

As 6 perguntas centrais de negócio foram respondidas utilizando consultas SQL estruturadas com joins relacionais (`fato_item_contratado` com as dimensões de órgãos, fornecedores, modalidades e localidades) e tratamentos robustos de nulos (`NULLIF`, `COUNT(*)`).

### 1. Economia global do poder público
Calcula o valor estimado da base comparável, o valor homologado e a taxa de deságio/economia percentual global.
* **Resultado Esperado (Prova Real)**: Economia nominal de ~R$ 992,86 milhões, representando um deságio de **14,46%** sobre uma base comparável de R$ 6,86 bilhões.

### 2. Concentração e risco de fornecedores
Identifica os 10 maiores fornecedores em volume financeiro e o respetivo peso percentual no orçamento total.
* **Consulta SQL (`sql/02_perguntas.sql`)**: Agrupa por fornecedor ordenando de forma descendente com restrição `LIMIT 10`.

### 3. Eficácia por modalidade
Mapeia o volume financeiro movimentado e o deságio obtido em cada modalidade licitatória.
* **Destaque**: Modalidades como Pregão Eletrônico e Concorrência concentram os maiores fluxos de recursos públicos.

### 4. Tempo do ciclo de compras
Mede a duração média (em dias) entre a publicação do edital e a homologação por órgão público (com filtro mínimo de 5 itens).
* **Resultado esperado (prova real)**: Ciclo médio global de **48,1 dias**, com um máximo registado de **611 dias**.

### 5. Distribuição regional
Agrega os dados por estados (UFs) e regiões geográficas para identificar os maiores volumes de despesas e descontos.

### 6. Perfil dos gastos
Distribui os recursos públicos nas categorias estruturadas via Regex (Obras e Engenharia, Serviços, e Bens).
* **Perfil Oficial**: 
  * Obras e engenharia: **60,8%** do volume homologado.
  * Serviços: **36,6%**.
  * Bens: **2,6%**.

---

## 📊 Modelagem e engenharia no Power BI 

### 1. Conexão e engenharia de dados (Power Query)
- **Conexão MySQL**: Integração direta com a base local `pncp_controladoria` via Connector/NET 8.x.
- **Normalização de Tipos (Surrogate Keys)**: Conversão das chaves substitutas (`sk_orgao`, `sk_fornecedor`, `sk_modalidade`, `sk_localidade`) de texto (`String`) para **Número Inteiro (`Integer`)** tanto na tabela de factos como nas dimensões, garantindo a integridade dos relacionamentos.
- **Tratamento de Nulos (`dias_ciclo`)**: Manutenção dos ~7% de valores nulos nativos (`null`) na coluna `dias_ciclo` para evitar distorções nas métricas agregadas de ciclo médio de compras.

### 2. Validação do relacionamento Star Schema
- Estabelecimento e validação de relacionamentos **1 para Muitos (1:N)** com filtro unidirecional partindo de cada dimensão para a tabela `fato_item_contratado`.

### 3. Medidas DAX principais (KPIs)

* **Valor total homologado**:
  ```dax
  Total Homologado = SUM('pncp_controladoria fato_item_contratado'[valor_total_homologado])

  ---

### Camada de Métricas DAX

Criação e formatação das 4 medidas fundamentais de controladoria:

* **Total Homologado**:

  ```dax
  Total Homologado = SUM('pncp_controladoria fato_item_contratado'[valor_total_homologado])

  Economia Nominal = SUM('pncp_controladoria fato_item_contratado'[economia_valor])

  Percentual Desagio = DIVIDE([Economia Nominal], SUM('pncp_controladoria fato_item_contratado'[valor_total_homologado]) + [Economia Nominal], 0)

  Ciclo Médio (Dias) = AVERAGE('pncp_controladoria fato_item_contratado'[dias_ciclo])


  ---

  ## 📊 Dashboards e Evidências Visuais

### Page 1: Visão Geral
![Visão Geral](docs/img/visao_geral.png)

### Page 2: Desempenho Operacional
![Desempenho Operacional](docs/img/desempenho_operacional.png)

### Page 3: Análise de Frota e Custos
![Frota e Custos](docs/img/frota_e_custos.png)

  ---
  
## 📂 Estrutura do repositório

```text
Projeto_controladoria_GOV/
│
├── data/                 # Ficheiros de dados (raw, processed)
├── docs/                 # Documentação e relatórios diagnósticos
│   └── img/              # Capturas de tela e diagramas (ex: sprints.png)
├── powerbi/              # Relatórios e dashboards analíticos (.pbix)
├── sql/
│   ├── 01_criar_banco.sql# Script DDL de criação do schema e tabelas
│   └── 02_perguntas.sql  # Consultas SQL para validação e auditoria da Controladoria
├── src/
│   ├── banco.py          # Gestão de conexões e utilitários MySQL
│   ├── carregar.py       # Script de ingestão e prova real (contagens)
│   ├── config.py         # Configurações globais e variáveis de ambiente
│   ├── limpeza.py        # Regras de transformação e higiene de dados
│   └── montar_tabelas.py # Aplicação das regras de negócio e modelo de dados
├── .env                  # Variáveis de ambiente sensíveis (credenciais DB)
└── README.md             # Documentação principal do projeto

---
