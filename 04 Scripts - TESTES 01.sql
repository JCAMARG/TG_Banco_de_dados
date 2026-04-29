/* =========================================================
   LIMPEZA (opcional – apenas para ambiente de teste)
   ========================================================= */
/*
BEGIN
    EXECUTE IMMEDIATE 'DELETE FROM MAN_FALHA';
    EXECUTE IMMEDIATE 'DELETE FROM MAN_OCORRENCIAS';
    EXECUTE IMMEDIATE 'DELETE FROM MAN_ROT_LUB';
    EXECUTE IMMEDIATE 'DELETE FROM MAN_ROT_TEMP';
    EXECUTE IMMEDIATE 'DELETE FROM CAD_POSICAO';
    EXECUTE IMMEDIATE 'DELETE FROM CAD_COLABORADOR';
    EXECUTE IMMEDIATE 'DELETE FROM CAD_EQUIPAMENTO';
    EXECUTE IMMEDIATE 'DELETE FROM CAD_SETOR';
    EXECUTE IMMEDIATE 'DELETE FROM CAD_TP_ALERTA';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- ignora erros se estiver vazio
END;
/
*/

/* =========================================================
   1) SETOR
   ========================================================= */

INSERT INTO CAD_SETOR (SET_COD, SET_DESCRICAO)
VALUES ('PRD', 'Produção');

/* =========================================================
   2) EQUIPAMENTO
   ========================================================= */

INSERT INTO CAD_EQUIPAMENTO (
    EQU_SUB_TAG,
    EQU_FABRICANTE,
    EQU_MODELO,
    EQU_VIDA_UTIL,
    EQU_FREQ_LUB,
    EQU_RPM,
    EQU_RPM_FIXO
) VALUES (
    'MTR01',
    'WEG',
    'W22',
    3650,        -- vida útil em dias (exemplo)
    30,          -- frequência de lubrificação (dias)
    1750,        -- RPM base
    'S'          -- RPM fixo
);

/* =========================================================
   3) COLABORADOR
   ========================================================= */

INSERT INTO CAD_COLABORADOR (
    COL_ID_SETOR,
    COL_COD,
    COL_NOME,
    COL_FUNCAO
) VALUES (
    (SELECT ID_SETOR FROM CAD_SETOR WHERE SET_COD = 'PRD'),
    1001,
    'João Técnico',
    'Manutenção'
);

/* =========================================================
   4) POSIÇÃO DO EQUIPAMENTO
   ========================================================= */

INSERT INTO CAD_POSICAO (
    POS_ID_SETOR,
    POS_ID_EQUIP,
    POS_TAG,
    POS_DESCRICAO,
    POS_TEMP_BASE,
    POS_DT_INSTALACAO,
    POS_DT_PROX_LUB
) VALUES (
    (SELECT ID_SETOR FROM CAD_SETOR WHERE SET_COD = 'PRD'),
    (SELECT ID_EQUIPAMENTO FROM CAD_EQUIPAMENTO WHERE EQU_SUB_TAG = 'MTR01'),
    'PRD-MTR-01',
    'Motor da esteira principal',
    40,                                  -- temperatura base
    SYSDATE - 180,                       -- instalado há 180 dias
    SYSDATE + 10                         -- próxima lub em 10 dias
);

/* =========================================================
   5) TIPOS DE ALERTA (para uso futuro)
   ========================================================= */

INSERT INTO CAD_TP_ALERTA (TPA_DESCRICAO, TPA_GRAU)
VALUES ('Normal', 1);

INSERT INTO CAD_TP_ALERTA (TPA_DESCRICAO, TPA_GRAU)
VALUES ('Alerta', 3);

INSERT INTO CAD_TP_ALERTA (TPA_DESCRICAO, TPA_GRAU)
VALUES ('Falha', 5);

/* =========================================================
   6) ROTAS DE TEMPERATURA (histórico)
   ========================================================= */

-- Rota mais antiga
INSERT INTO MAN_ROT_TEMP (
    RTE_ID_POS,
    RTE_ID_COL,
    RTE_DATA,
    RTE_TEMP_AMB,
    RTE_TEMP_EQUIP,
    RTE_VELOCIDADE,
    RTE_OBS
) VALUES (
    (SELECT ID_POSICAO FROM CAD_POSICAO WHERE POS_TAG = 'PRD-MTR-01'),
    (SELECT ID_COLABORADOR FROM CAD_COLABORADOR WHERE COL_COD = 1001),
    SYSDATE - 5,
    28,
    55,
    1700,
    'Rota anterior'
);

-- Última rota (essa será usada pelo fuzzy)
INSERT INTO MAN_ROT_TEMP (
    RTE_ID_POS,
    RTE_ID_COL,
    RTE_DATA,
    RTE_TEMP_AMB,
    RTE_TEMP_EQUIP,
    RTE_VELOCIDADE,
    RTE_OBS
) VALUES (
    (SELECT ID_POSICAO FROM CAD_POSICAO WHERE POS_TAG = 'PRD-MTR-01'),
    (SELECT ID_COLABORADOR FROM CAD_COLABORADOR WHERE COL_COD = 1001),
    SYSDATE - 1,
    30,
    68,
    1800,
    'Rota mais recente'
);

/* =========================================================
   7) ROTINA DE LUBRIFICAÇÃO
   ========================================================= */

INSERT INTO MAN_ROT_LUB (
    RLU_ID_POS,
    RLU_ID_COL,
    RLU_DATA,
    RLU_OBS
) VALUES (
    (SELECT ID_POSICAO FROM CAD_POSICAO WHERE POS_TAG = 'PRD-MTR-01'),
    (SELECT ID_COLABORADOR FROM CAD_COLABORADOR WHERE COL_COD = 1001),
    SYSDATE - 20,
    'Lubrificação preventiva'
);

COMMIT;

/* =========================================================
   8) TESTE BÁSICO – FN_ANALISAR_EQUIPAMENTO
   ========================================================= */

DECLARE
    v_resultado NUMBER;
BEGIN
    v_resultado := PKG_ANALISE_FUZZY.FN_ANALISAR_EQUIPAMENTO('21');

    FOR r IN (
        SELECT
            FAL_ID_POS,
            FAL_DATA,
            FAL_FUZZY_NUM,
            FAL_FUZZY_LING,
            FAL_FUZZY_DOM,
            FAL_GRAU_NORMAL,
            FAL_GRAU_ACEITAVEL,
            FAL_GRAU_ALERTA,
            FAL_GRAU_FALHA
        FROM MAN_FALHA
        WHERE FAL_ID_POS = '21'
        ORDER BY FAL_DATA DESC
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            'ID: ' || r.FAL_ID_POS ||
            ' | DATA: ' || r.FAL_DATA ||
            ' | FUZZY: ' || r.FAL_FUZZY_NUM ||
            ' | DOMINANTE: ' || r.FAL_FUZZY_DOM ||
            ' | LINGUISTICO: ' || r.FAL_FUZZY_LING
        );
    END LOOP;
END;
/



SELECT
    POS_TEMP_BASE,
    POS_DT_PROX_LUB,
    ID_POSICAO,
    POS_ID_SETOR,
    POS_ID_EQUIP,
    POS_TAG,
    POS_DESCRICAO,
    POS_DT_INSTALACAO,
    POS_ATIVO
FROM
    CAD_POSICAO;

    ALTER TABLE MAN_FALHA MODIFY (
    FAL_ID_R_TEMP      NULL,
    FAL_ID_R_LUB       NULL,
    FAL_ID_OCORRENCIA  NULL,
    FAL_ID_TP_ALERTA   NULL
);