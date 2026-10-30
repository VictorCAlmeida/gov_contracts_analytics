# Gov_contracts_analytics
Pipeline analítico end-to-end para auditoria, sanitização e modelagem de contratações públicas federais (PNCP). Desenvolvimento de data warehouse em MySQL e dashboard executivo para apoiar a controladoria pública.

## 🛠️ Detalhamento técnico das regras de limpeza e tratamento

O pipeline desenvolvido executa uma higienização em camadas sobre os dados brutos do PNCP.

1. **Higienização léxica e nulos ocultos**: Conversão de termos textuais nulos (`N/A`, `-`, `0` inválidos) para `NULL` estrutural.
2. **Normalização cadastral (CNPJ/CPF/Estrangeiro)**: Correção de formatação, preservação de zeros à esquerda com `zfill` e tratamento flexível para CPFs, CNPJs e registros de pessoas estrangeiras (`PE`).
3. **Conversão monetária robusta**: Tratamento de padrões mistos de separadores decimais (brasileiro/americano), remoção de símbolos monetários e suporte a valores negativos.
4. **Filtragem de integridade e rejeição**: Descarte automático de resultados cancelados, orçamentos sigilosos, itens com valores zerados/negativos e distorções matemáticas extremas (> 1.000x entre estimado e homologado).
5. **Auditoria cronológica**: Validação de precedência temporal entre datas de publicação e homologação, neutralizando inconsistências e calculando o tempo de ciclo licitatório.
6. **Classificação de perfil de gasto via regex**: Mapeamento inteligente de descrições e objetos para segmentação precisa entre Bens, Serviços e Obras e Engenharia.
