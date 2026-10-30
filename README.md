# Gov_contracts_analytics

Pipeline analítico end-to-end para auditoria, sanitização e modelagem de contratações públicas federais (PNCP). Desenvolvimento de Data Warehouse em MySQL e dashboard executivo para apoiar a controladoria pública.

---

## 🎯 Sobre o Projeto
Este projeto consiste num pipeline de **ETL (Extract, Transform, Load)** desenvolvido para processar, higienizar e estruturar dados públicos de contratações do **PNCP (Portal Nacional de Contratações Públicas)**. Os dados transformados foram modelados num **Modelo Estrela (Star Schema)** e persistidos numa base de dados relacional **MySQL**, servindo de base para auditorias, análises de conformidade e visualizações de inteligência de negócio.

---

## 🛠️ Planejamento e Progresso do Projeto (Sprints)

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

## 🏛️ Arquitetura do Modelo Estrela (Star Schema)
O Data Warehouse foi estruturado com uma tabela de factos central rodeada por quatro dimensões essenciais:

* **`fato_item_contratado`** (Tabela de Factos): Contém os itens contratados, métricas financeiras (valores estimados vs. homologados), prazos do ciclo de compras e chaves estrangeiras.
* **`dim_orgao`**: Informações normalizadas sobre os órgãos públicos contratantes (Poder, CNPJ e Nome).
* **`dim_fornecedor`**: Dados dos fornecedores/contratados (identificação, tipo de pessoa e porte).
* **`dim_modalidade`**: Classificação das modalidades de contratação.
* **`dim_localidade`**: Agrupamento geográfico por UF e região.

---

## 🧹 Regras de Qualidade de Dados e Limpeza
Durante a fase de transformação (`limpeza.py`), foram aplicadas rigorosas regras de engenharia de dados:

1. **Tratamento de Nulos Ocultos**: Identificação e normalização de strings vazias ou nulos mascarados para instâncias consistentes (`NaN`/`None`).
2. **Normalização de Documentos**: Padronização e formatação limpa de CNPJ, CPF e identificadores (`PE`).
3. **Sanitização Monetária**: Conversão de campos de texto financeiro em formatos numéricos decimais precisos (`DECIMAL`), eliminando inconsistências de símbolos e pontuação.
4. **Remoção de Outliers**: Filtragem de valores anómalos ou distorcidos que pudessem comprometer a análise agregada.
5. **Classificação de Perfis de Gasto**: Aplicação de expressões regulares (`Regex`) para categorizar automaticamente o perfil dos gastos públicos.

---

## 📂 Estrutura do Repositório

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
