USE pncp_controladoria;

-- ============================================================================
-- SPRINT 5: CONSULTAS DE AUDITORIA E INTELIGÊNCIA DE NEGÓCIO (CONTROLADORIA)
-- Autor: Victor Almeida
-- Objetivo: Responder às 6 perguntas estratégicas exigidas pela Controladoria
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PERGUNTA 1: Economia global do Poder Público
-- Regra: Calcula o percentual e o valor financeiro nominal economizado pelo 
-- governo. Considera estritamente os itens comparáveis (comparavel = 1).
-- ----------------------------------------------------------------------------
SELECT 
    -- Soma o valor estimado apenas dos itens que são válidos para comparação
    SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END) AS valor_estimado_comparavel,
    
    -- Soma o valor total homologado de todos os itens comparáveis
    SUM(CASE WHEN comparavel = 1 THEN valor_total_homologado ELSE 0 END) AS valor_homologado_comparavel,
    
    -- Soma o valor nominal da economia (já pré-calculada no pipeline ETL)
    SUM(economia_valor) AS economia_nominal_rs,
    
    -- Calcula o percentual de economia: (Soma da Economia / Soma do Estimado Comparável) * 100
    -- Usa NULLIF para prevenir erro matemático de divisão por zero
    ROUND(
        (SUM(economia_valor) / NULLIF(SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 0)) * 100, 
        2
    ) AS economia_percentual
FROM fato_item_contratado;


-- ----------------------------------------------------------------------------
-- PERGUNTA 2: Concentração e risco de fornecedores
-- Regra: Identifica os 10 maiores fornecedores em volume financeiro e calcula 
-- o percentual de participação de cada um em relação ao orçamento público total.
-- ----------------------------------------------------------------------------
SELECT 
    f.ni_fornecedor,
    f.nome_fornecedor,
    -- Volume total homologado obtido por este fornecedor específico
    SUM(fi.valor_total_homologado) AS volume_homologado_rs,
    
    -- Percentual de participação frente ao volume total geral da base (subconsulta com ALL/Total)
    ROUND(
        (SUM(fi.valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
        2
    ) AS participacao_orcamento_percentual
FROM fato_item_contratado fi
JOIN dim_fornecedor f ON fi.sk_fornecedor = f.sk_fornecedor
GROUP BY f.sk_fornecedor, f.ni_fornecedor, f.nome_fornecedor
ORDER BY volume_homologado_rs DESC
LIMIT 10; -- Restringe rigorosamente aos 10 maiores


-- ----------------------------------------------------------------------------
-- PERGUNTA 3: Eficácia por modalidade
-- Regra: Avalia o volume de recursos movimentados e o deságio/economia obtido 
-- em cada modalidade licitatória.
-- ----------------------------------------------------------------------------
SELECT 
    m.nome_modalidade,
    COUNT(fi.sk_fato) AS qtd_itens,
    -- Volume total de recursos movimentados pela modalidade
    SUM(fi.valor_total_homologado) AS volume_homologado_rs,
    
    -- Participação percentual do volume da modalidade sobre o total geral
    ROUND(
        (SUM(fi.valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
        2
    ) AS participacao_volume_percentual,
    
    -- Economia nominal gerada na modalidade
    SUM(fi.economia_valor) AS economia_nominal_rs,
    
    -- Percentual de deságio/economia da modalidade (calculado via SOMA ÷ SOMA com tratamento de nulos)
    ROUND(
        (SUM(fi.economia_valor) / NULLIF(SUM(CASE WHEN fi.comparavel = 1 THEN fi.valor_total_estimado ELSE 0 END), 0)) * 100, 
        2
    ) AS desagio_economia_percentual
FROM fato_item_contratado fi
JOIN dim_modalidade m ON fi.sk_modalidade = m.sk_modalidade
GROUP BY m.sk_modalidade, m.nome_modalidade
ORDER BY volume_homologado_rs DESC;


-- ----------------------------------------------------------------------------
-- PERGUNTA 4: Tempo do ciclo de compras
-- Regra: Calcula a duração média e máxima (em dias) entre o lançamento do edital 
-- e a homologação. Aplica filtro de relevância (apenas órgãos com >= 5 itens com ciclo).
-- ----------------------------------------------------------------------------
SELECT 
    o.nome_orgao,
    -- Conta unidades compradoras distintas (CNPJs únicos associados ao nome do órgão)
    COUNT(DISTINCT o.cnpj_orgao) AS qtd_unidades_compradoras,
    -- Conta apenas os itens que possuem ciclo válido de dias preenchido
    COUNT(fi.dias_ciclo) AS itens_com_ciclo,
    -- Média aritmética dos dias de ciclo (arredondada para 1 casa decimal)
    ROUND(AVG(fi.dias_ciclo), 1) AS ciclo_medio_dias,
    -- Maior tempo de ciclo registrado para o órgão
    MAX(fi.dias_ciclo) AS ciclo_maximo_dias
FROM fato_item_contratado fi
JOIN dim_orgao o ON fi.sk_orgao = o.sk_orgao
WHERE fi.dias_ciclo IS NOT NULL -- Ignora datas invertidas ou nulas tratadas no ETL
GROUP BY o.nome_orgao
HAVING COUNT(fi.dias_ciclo) >= 5 -- Regra de corte exigida pela Controladoria
ORDER BY ciclo_medio_dias DESC;


-- ----------------------------------------------------------------------------
-- PERGUNTA 5: Distribuição regional
-- Regra: Mapeia quais estados (UFs) e regiões concentram as maiores despesas 
-- financeiras e quais apresentam os melhores indicadores de desconto.
-- ----------------------------------------------------------------------------
SELECT 
    l.regiao,
    l.uf_sigla,
    COUNT(fi.sk_fato) AS qtd_itens,
    -- Volume total homologado por localidade
    SUM(fi.valor_total_homologado) AS volume_homologado_rs,
    
    -- Participação percentual da UF no volume global
    ROUND(
        (SUM(fi.valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
        2
    ) AS participacao_volume_percentual,
    
    -- Indicador de deságio/economia percentual regional
    ROUND(
        (SUM(fi.economia_valor) / NULLIF(SUM(CASE WHEN fi.comparavel = 1 THEN fi.valor_total_estimado ELSE 0 END), 0)) * 100, 
        2
    ) AS desagio_economia_percentual
FROM fato_item_contratado fi
JOIN dim_localidade l ON fi.sk_localidade = l.sk_localidade
GROUP BY l.regiao, l.uf_sigla
ORDER BY volume_homologado_rs DESC;


-- ----------------------------------------------------------------------------
-- PERGUNTA 6: Perfil dos gastos
-- Regra: Agrega e distribui os recursos públicos nas categorias de perfil 
-- mapeadas via Regex no ETL (Bens, Serviços e Obras e Engenharia).
-- ----------------------------------------------------------------------------
SELECT 
    perfil_gasto, -- Coluna nativa da tabela fato tratada na montagem
    COUNT(sk_fato) AS qtd_itens,
    -- Volume financeiro total por perfil de gasto
    SUM(valor_total_homologado) AS volume_homologado_rs,
    
    -- Percentual de representatividade do perfil frente ao orçamento total
    ROUND(
        (SUM(valor_total_homologado) / (SELECT SUM(valor_total_homologado) FROM fato_item_contratado)) * 100, 
        2
    ) AS participacao_volume_percentual,
    
    -- Taxa de deságio/economia por perfil de gasto
    ROUND(
        (SUM(economia_valor) / NULLIF(SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 0)) * 100, 
        2
    ) AS desagio_economia_percentual,
    
    -- Ticket médio por item contratado (Volume Homologado ÷ Quantidade de Itens)
    ROUND(SUM(valor_total_homologado) / COUNT(sk_fato), 2) AS ticket_medio_por_item_rs
FROM fato_item_contratado
GROUP BY perfil_gasto
ORDER BY volume_homologado_rs DESC;