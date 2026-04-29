
-- ============================================================
-- TG – ESQUELETO DO PROCESSAMENTO FUZZY EM PL/SQL
-- Projeto: Análise e Previsão de Falhas em Equipamentos
-- ============================================================


-- ============================================================
-- PACKAGE SPECIFICATION
-- ============================================================
CREATE OR REPLACE PACKAGE PKG_ANALISE_FUZZY AS

    ----------------------------------------------------------------
    -- FUNÇÃO PRINCIPAL – VERSÃO PARA TRIGGER
    ----------------------------------------------------------------
    FUNCTION FN_ANALISAR_EQUIPAMENTO (
        P_ID_POSICAO IN NUMBER
    ) RETURN NUMBER;

    ----------------------------------------------------------------
    -- FUNÇÃO PRINCIPAL – VERSÃO COMPLETA (chamada direta)
    ----------------------------------------------------------------
    FUNCTION FN_ANALISAR_EQUIPAMENTO (
        P_ID_POSICAO        IN NUMBER,
        P_TEMP_AMBIENTE     IN NUMBER,
        P_TEMP_EQUIPAMENTO  IN NUMBER,
        P_VELOCIDADE        IN NUMBER,
        P_TEMP_MAQ          IN NUMBER
    ) RETURN NUMBER;

END PKG_ANALISE_FUZZY;
/

-- ============================================================
-- PACKAGE BODY
-- ============================================================
CREATE OR REPLACE PACKAGE BODY PKG_ANALISE_FUZZY AS

    ----------------------------------------------------------------
    -- FUNÇÕES FUZZY
    ----------------------------------------------------------------

    -- 2) FUZZIFICAÇÃO - Cada variável possui sua própria função de pertinência
	FUNCTION FN_FUZZ_TEMP_AMBIENTE (
        p_valor NUMBER,
        p_label VARCHAR2
    ) RETURN NUMBER IS
        -- < 19°C (V1) | 21°C (V2) | 24°C (V3) | 27°C (V4) >
        V1 CONSTANT NUMBER := 19;
        V2 CONSTANT NUMBER := 21;
        V3 CONSTANT NUMBER := 24;
        V4 CONSTANT NUMBER := 27;

        v_result NUMBER := 0;
    BEGIN
        IF p_label = 'Baixa' THEN
            IF p_valor <= V1 THEN
                v_result := 1;
            ELSIF p_valor > V1 AND p_valor < V2 THEN
                v_result := (V2 - p_valor) / (V2 - V1);
            ELSE
                v_result := 0;
            END IF;

        ELSIF p_label = 'Normal' THEN
            IF p_valor >= V2 AND p_valor <= V3 THEN
                v_result := 1;
            ELSIF p_valor > V1 AND p_valor < V2 THEN
                v_result := (p_valor - V1) / (V2 - V1);
            ELSIF p_valor > V3 AND p_valor < V4 THEN
                v_result := (V4 - p_valor) / (V4 - V3);
            ELSE
                v_result := 0;
            END IF;

        ELSIF p_label = 'Alta' THEN
            IF p_valor >= V4 THEN
                v_result := 1;
            ELSIF p_valor > V3 AND p_valor < V4 THEN
                v_result := (p_valor - V3) / (V4 - V3);
            ELSE
                v_result := 0;
            END IF;
        END IF;

        RETURN v_result;
    END;


	FUNCTION FN_FUZZ_TEMP_EQUIP (
        p_valor NUMBER,
        p_base_temp NUMBER,
        p_label VARCHAR2
    ) RETURN NUMBER IS
        -- < T+3 (V1) | T+7 (V2) | T+10 (V3) | T+15 (V4) >
        V1 NUMBER := p_base_temp + 3;
        V2 NUMBER := p_base_temp + 7;
        V3 NUMBER := p_base_temp + 10;
        V4 NUMBER := p_base_temp + 15;

        v_result NUMBER := 0;
    BEGIN
        IF p_label = 'Normal' THEN
            IF p_valor <= V1 THEN
                v_result := 1;
            ELSIF p_valor > V1 AND p_valor < V2 THEN
                v_result := (V2 - p_valor) / (V2 - V1);
            END IF;

        ELSIF p_label = 'Aquecendo' THEN
            IF p_valor >= V2 AND p_valor <= V3 THEN
                v_result := 1;
            ELSIF p_valor > V1 AND p_valor < V2 THEN
                v_result := (p_valor - V1) / (V2 - V1);
            ELSIF p_valor > V3 AND p_valor < V4 THEN
                v_result := (V4 - p_valor) / (V4 - V3);
            END IF;

        ELSIF p_label = 'Quente' THEN
            IF p_valor >= V4 THEN
                v_result := 1;
            ELSIF p_valor > V3 AND p_valor < V4 THEN
                v_result := (p_valor - V3) / (V4 - V3);
            END IF;
        END IF;

        RETURN v_result;
    END;


	FUNCTION FN_FUZZ_VELOCIDADE (
        p_valor NUMBER,
        p_base NUMBER,
        p_constante CHAR,
        p_label VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF p_constante = 'S' THEN
            IF p_label = 'Normal' THEN
                RETURN 1;
            ELSE
                RETURN 0;
            END IF;
        END IF;

        IF p_label = 'Baixa' AND p_valor < p_base THEN
            RETURN 1;
        ELSIF p_label = 'Normal' AND p_valor = p_base THEN
            RETURN 1;
        ELSIF p_label = 'Alta' AND p_valor > p_base THEN
            RETURN 1;
        END IF;

        RETURN 0;
    END;


    FUNCTION FN_FUZZ_LUBRIFICACAO (
        p_valor NUMBER,
        p_label VARCHAR2
    ) RETURN NUMBER IS
        -- < 30% | 40% | 60% | 70% | 95% | 105% >
        V1 CONSTANT NUMBER := 30;
        V2 CONSTANT NUMBER := 40;
        V3 CONSTANT NUMBER := 60;
        V4 CONSTANT NUMBER := 70;
        V5 CONSTANT NUMBER := 95;
        V6 CONSTANT NUMBER := 105;

        v_result NUMBER := 0;
    BEGIN
        IF p_label = 'Relubrificado' THEN
            IF p_valor <= V1 THEN
                v_result := 1;
            ELSIF p_valor > V1 AND p_valor < V2 THEN
                v_result := (V2 - p_valor) / (V2 - V1);
            END IF;

        ELSIF p_label = 'Normal' THEN
            IF p_valor >= V2 AND p_valor <= V3 THEN
                v_result := 1;
            ELSIF p_valor > V1 AND p_valor < V2 THEN
                v_result := (p_valor - V1) / (V2 - V1);
            ELSIF p_valor > V3 AND p_valor < V4 THEN
                v_result := (V4 - p_valor) / (V4 - V3);
            END IF;

        ELSIF p_label = 'Vencer' THEN
            IF p_valor >= V4 AND p_valor <= V5 THEN
                v_result := 1;
            ELSIF p_valor > V3 AND p_valor < V4 THEN
                v_result := (p_valor - V3) / (V4 - V3);
            ELSIF p_valor > V5 AND p_valor < V6 THEN
                v_result := (V6 - p_valor) / (V6 - V5);
            END IF;

        ELSIF p_label = 'Atrasado' THEN
            IF p_valor >= V6 THEN
                v_result := 1;
            ELSIF p_valor > V5 AND p_valor < V6 THEN
                v_result := (p_valor - V5) / (V6 - V5);
            END IF;
        END IF;

        RETURN v_result;
    END;


    FUNCTION FN_FUZZ_TEMPO_MAQUINA (
        p_dias NUMBER,
        p_label VARCHAR2
    ) RETURN NUMBER IS
        -- 0 | 0.5 ano | 1.5 ano
        V1 CONSTANT NUMBER := 0.5;
        V2 CONSTANT NUMBER := 1.5;

        v_anos NUMBER := p_dias / 365;
    BEGIN
        IF p_label = 'Pouco' THEN
            IF v_anos <= V1 THEN
                RETURN 1;
            ELSIF v_anos > V1 AND v_anos < V2 THEN
                RETURN (V2 - v_anos) / (V2 - V1);
            END IF;

        ELSIF p_label = 'Longo' THEN
            IF v_anos >= V2 THEN
                RETURN 1;
            ELSIF v_anos > V1 AND v_anos < V2 THEN
                RETURN (v_anos - V1) / (V2 - V1);
            END IF;
        END IF;

        RETURN 0;
    END;


	-- 3) INFERÊNCIA FUZZY - Baseada na tabela FUZZY_INFERENCIA (216 regras)
	FUNCTION FN_APLICAR_INFERENCIA (
        p_t_amb   VARCHAR2,
        p_t_equip VARCHAR2,
        p_veloc   VARCHAR2,
        p_lub     VARCHAR2,
        p_t_maq   VARCHAR2,

        p_cta_baixa   NUMBER,
        p_cta_normal  NUMBER,
        p_cta_alta    NUMBER,

        p_cte_normal     NUMBER,
        p_cte_aquecendo  NUMBER,
        p_cte_quente     NUMBER,

        p_bv_baixa  NUMBER,
        p_bv_normal NUMBER,
        p_bv_alta   NUMBER,

        p_cl_relub    NUMBER,
        p_cl_normal   NUMBER,
        p_cl_vencer   NUMBER,
        p_cl_vencido  NUMBER,

        p_btm_pouco NUMBER,
        p_btm_longo NUMBER
    ) RETURN NUMBER IS
        v_result NUMBER := 1;
    BEGIN
        -- TEMP AMBIENTE
        IF p_t_amb = 'Baixa' THEN
            v_result := LEAST(v_result, p_cta_baixa);
        ELSIF p_t_amb = 'Normal' THEN
            v_result := LEAST(v_result, p_cta_normal);
        ELSIF p_t_amb = 'Alta' THEN
            v_result := LEAST(v_result, p_cta_alta);
        END IF;

        -- TEMP EQUIPAMENTO
        IF p_t_equip = 'Normal' THEN
            v_result := LEAST(v_result, p_cte_normal);
        ELSIF p_t_equip = 'Aquecendo' THEN
            v_result := LEAST(v_result, p_cte_aquecendo);
        ELSIF p_t_equip = 'Quente' THEN
            v_result := LEAST(v_result, p_cte_quente);
        END IF;

        -- VELOCIDADE
        IF p_veloc = 'Baixa' THEN
            v_result := LEAST(v_result, p_bv_baixa);
        ELSIF p_veloc = 'Normal' THEN
            v_result := LEAST(v_result, p_bv_normal);
        ELSIF p_veloc = 'Alta' THEN
            v_result := LEAST(v_result, p_bv_alta);
        END IF;

        -- LUBRIFICAÇÃO
        IF p_lub = 'Relubrificado' THEN
            v_result := LEAST(v_result, p_cl_relub);
        ELSIF p_lub = 'Normal' THEN
            v_result := LEAST(v_result, p_cl_normal);
        ELSIF p_lub = 'Vencer' THEN
            v_result := LEAST(v_result, p_cl_vencer);
        ELSIF p_lub = 'Atrasado' THEN
            v_result := LEAST(v_result, p_cl_vencido);
        END IF;

        -- TEMPO EM MÁQUINA
        IF p_t_maq = 'Pouco' THEN
            v_result := LEAST(v_result, p_btm_pouco);
        ELSIF p_t_maq = 'Longo' THEN
            v_result := LEAST(v_result, p_btm_longo);
        END IF;

        RETURN v_result;
    END;

    FUNCTION FN_CALCULAR_STATUS (
        p_status VARCHAR2,

        -- todos os valores fuzzificados
        p_cta_baixa   NUMBER,
        p_cta_normal  NUMBER,
        p_cta_alta    NUMBER,
        p_cte_normal  NUMBER,
        p_cte_aquec   NUMBER,
        p_cte_quente  NUMBER,
        p_bv_baixa    NUMBER,
        p_bv_normal   NUMBER,
        p_bv_alta     NUMBER,
        p_cl_relub    NUMBER,
        p_cl_normal   NUMBER,
        p_cl_vencer  NUMBER,
        p_cl_vencido  NUMBER,
        p_btm_pouco   NUMBER,
        p_btm_longo   NUMBER
    ) RETURN NUMBER IS

        v_max NUMBER := 0;
        v_aux NUMBER;

    BEGIN
        FOR r IN (
            SELECT *
            FROM FUZZY_INFERENCIA
            WHERE STATUS = p_status
        ) LOOP

            v_aux := FN_APLICAR_INFERENCIA(
                r.T_AMB, r.T_EQUIP, r.VELOC, r.LUB, r.T_MAQ,
                p_cta_baixa, p_cta_normal, p_cta_alta,
                p_cte_normal, p_cte_aquec, p_cte_quente,
                p_bv_baixa, p_bv_normal, p_bv_alta,
                p_cl_relub, p_cl_normal, p_cl_vencer, p_cl_vencido,
                p_btm_pouco, p_btm_longo
            );

            IF v_aux > v_max THEN
                v_max := v_aux;
            END IF;

            IF v_max = 1 THEN
                EXIT;
            END IF;

        END LOOP;

        RETURN v_max;
    END;

    PROCEDURE PR_INFERENCIA (
        -- entradas fuzzificadas
        p_cta_baixa   NUMBER,
        p_cta_normal  NUMBER,
        p_cta_alta    NUMBER,
        p_cte_normal  NUMBER,
        p_cte_aquec   NUMBER,
        p_cte_quente  NUMBER,
        p_bv_baixa    NUMBER,
        p_bv_normal   NUMBER,
        p_bv_alta     NUMBER,
        p_cl_relub    NUMBER,
        p_cl_normal   NUMBER,
        p_cl_vencer  NUMBER,
        p_cl_vencido  NUMBER,
        p_btm_pouco   NUMBER,
        p_btm_longo   NUMBER,

        -- saídas
        o_normal     OUT NUMBER,
        o_aceitavel  OUT NUMBER,
        o_em_alerta  OUT NUMBER,
        o_falha      OUT NUMBER
    ) IS
    BEGIN
        o_normal := FN_CALCULAR_STATUS(
            'Normal',
            p_cta_baixa, p_cta_normal, p_cta_alta,
            p_cte_normal, p_cte_aquec, p_cte_quente,
            p_bv_baixa, p_bv_normal, p_bv_alta,
            p_cl_relub, p_cl_normal, p_cl_vencer, p_cl_vencido,
            p_btm_pouco, p_btm_longo
        );

        o_aceitavel := FN_CALCULAR_STATUS(
            'Aceitavel',
            p_cta_baixa, p_cta_normal, p_cta_alta,
            p_cte_normal, p_cte_aquec, p_cte_quente,
            p_bv_baixa, p_bv_normal, p_bv_alta,
            p_cl_relub, p_cl_normal, p_cl_vencer, p_cl_vencido,
            p_btm_pouco, p_btm_longo
        );

        o_em_alerta := FN_CALCULAR_STATUS(
            'Alerta',
            p_cta_baixa, p_cta_normal, p_cta_alta,
            p_cte_normal, p_cte_aquec, p_cte_quente,
            p_bv_baixa, p_bv_normal, p_bv_alta,
            p_cl_relub, p_cl_normal, p_cl_vencer, p_cl_vencido,
            p_btm_pouco, p_btm_longo
        );

        o_falha := FN_CALCULAR_STATUS(
            'Emfalha',
            p_cta_baixa, p_cta_normal, p_cta_alta,
            p_cte_normal, p_cte_aquec, p_cte_quente,
            p_bv_baixa, p_bv_normal, p_bv_alta,
            p_cl_relub, p_cl_normal, p_cl_vencer, p_cl_vencido,
            p_btm_pouco, p_btm_longo
        );
    END;

	FUNCTION FN_INTERPRETAR_ESTADO (
		p_normal    NUMBER,
		p_aceitavel NUMBER,
		p_alerta    NUMBER,
		p_falha     NUMBER
	) RETURN VARCHAR2 IS

		v_result VARCHAR2(200);
		v_max    NUMBER := GREATEST(p_normal, p_aceitavel, p_alerta, p_falha);

	BEGIN
		v_result := '';

		IF p_normal > 0 THEN
			v_result := v_result || 'Normal (' || ROUND(p_normal*100,1) || '%) ';
		END IF;

		IF p_aceitavel > 0 THEN
			v_result := v_result || 'Aceitável (' || ROUND(p_aceitavel*100,1) || '%) ';
		END IF;

		IF p_alerta > 0 THEN
			v_result := v_result || 'Alerta (' || ROUND(p_alerta*100,1) || '%) ';
		END IF;

		IF p_falha > 0 THEN
			v_result := v_result || 'Falha (' || ROUND(p_falha*100,1) || '%) ';
		END IF;

		RETURN RTRIM(v_result);

	END;

	FUNCTION FN_ESTADO_DOMINANTE (
		p_normal    NUMBER,
		p_aceitavel NUMBER,
		p_alerta    NUMBER,
		p_falha     NUMBER
	) RETURN VARCHAR2 IS
	BEGIN
		IF p_falha = GREATEST(p_normal, p_aceitavel, p_alerta, p_falha) THEN
			RETURN 'Falha';
		ELSIF p_alerta = GREATEST(p_normal, p_aceitavel, p_alerta) THEN
			RETURN 'Alerta';
		ELSIF p_aceitavel = GREATEST(p_normal, p_aceitavel) THEN
			RETURN 'Aceitável';
		ELSE
			RETURN 'Normal';
		END IF;
	END;


	-- 4) DEFUZZIFICAÇÃO - Método do centroide
	FUNCTION FN_DEFUZZIFICAR (
        p_normal     NUMBER,
        p_aceitavel  NUMBER,
        p_em_alerta  NUMBER,
        p_falha      NUMBER
    ) RETURN NUMBER IS

        v_numerator   NUMBER;
        v_denominator NUMBER;

        FUNCTION MAIOR(a NUMBER, b NUMBER) RETURN NUMBER IS
        BEGIN
            IF a > b THEN
                RETURN a;
            ELSE
                RETURN b;
            END IF;
        END;

    BEGIN
        -- (0,5+1 + 1,5)*N + (2,5+3)A + 4E + 5F + maior(N, A) * 2 + maior (A,E)*3,5 + maior(E,F)*4,5
        -- 3N + 2A + 1E +1F +  1*maior(N, A) + 1*maior (A,E) + 1*maior(E,F)

        -- Numerador (parte de cima)
        v_numerator :=
            (0.5 + 1 + 1.5) * p_normal
            + (2.5 + 3)       * p_aceitavel
            + 4               * p_em_alerta
            + 5               * p_falha
            + 2.0 * LEAST(0.5, MAIOR(p_normal, p_aceitavel))
            + 3.5 * LEAST(
                        0.33,
                        MAIOR(
                            LEAST(0.33, p_aceitavel),
                            LEAST(0.67, p_em_alerta)
                        )
                    )
            + 4.5 * LEAST(0.5, MAIOR(p_em_alerta, p_falha));

        -- Denominador (parte de baixo)
        v_denominator :=
            3 * p_normal
            + 2 * p_aceitavel
            +     p_em_alerta
            +     p_falha
            + LEAST(0.5, MAIOR(p_normal, p_aceitavel))
            + LEAST(
                0.33,
                MAIOR(
                    LEAST(0.33, p_aceitavel),
                    LEAST(0.67, p_em_alerta)
                )
            )
            + LEAST(0.5, MAIOR(p_em_alerta, p_falha));

        IF v_denominator = 0 THEN
            RETURN 0;
        END IF;

        RETURN v_numerator / v_denominator;
    END;

	-- Calculo de pertinencia
	PROCEDURE PR_PERTINENCIA_STATUS (
	    p_grau        IN  NUMBER,
	    o_normal      OUT NUMBER,
	    o_aceitavel   OUT NUMBER,
	    o_alerta      OUT NUMBER,
	    o_falha       OUT NUMBER
	) IS
	    V1 CONSTANT NUMBER := 1.75;
	    V2 CONSTANT NUMBER := 2.25;
	    V3 CONSTANT NUMBER := 3.00;
	    V4 CONSTANT NUMBER := 3.75;
	    V5 CONSTANT NUMBER := 4.25;
	    V6 CONSTANT NUMBER := 5.00;
	BEGIN
	    o_normal    := 0;
	    o_aceitavel := 0;
	    o_alerta    := 0;
	    o_falha     := 0;
	
	    IF p_grau <= V1 THEN
	        o_normal := 1;
	
	    ELSIF p_grau >= V2 AND p_grau <= V3 THEN
	        o_aceitavel := 1;
	
	    ELSIF p_grau >= V4 AND p_grau <= V5 THEN
	        o_alerta := 1;
	
	    ELSIF p_grau >= V6 THEN
	        o_falha := 1;
	
	    ELSIF p_grau > V1 AND p_grau < V2 THEN
	        o_normal    := (V2 - p_grau) / (V2 - V1);
	        o_aceitavel := (p_grau - V1) / (V2 - V1);
	
	    ELSIF p_grau > V3 AND p_grau < V4 THEN
	        o_aceitavel := (V4 - p_grau) / (V4 - V3);
	        o_alerta    := (p_grau - V3) / (V4 - V3);
	
	    ELSIF p_grau > V5 AND p_grau < V6 THEN
	        o_alerta := (V6 - p_grau) / (V6 - V5);
	        o_falha  := (p_grau - V5) / (V6 - V5);
	    END IF;
	END;



    ----------------------------------------------------------------
    -- FUNÇÕES DE APOIO (SELECTS)
    ----------------------------------------------------------------
    FUNCTION FN_GET_ID_EQUIPAMENTO (
        P_ID_POSICAO NUMBER
    ) RETURN NUMBER IS
        v_id_equip NUMBER;
    BEGIN
        SELECT POS_ID_EQUIP
          INTO v_id_equip
          FROM CAD_POSICAO
         WHERE ID_POSICAO = P_ID_POSICAO
           AND POS_ATIVO = 'S';

        RETURN v_id_equip;
    END;


    FUNCTION FN_GET_ULTIMA_ROT_TEMP (
        P_ID_POSICAO NUMBER,
        P_CAMPO      VARCHAR2
    ) RETURN NUMBER IS
        v_result NUMBER;
    BEGIN
        IF P_CAMPO = 'AMB' THEN
            SELECT RTE_TEMP_AMB
              INTO v_result
              FROM MAN_ROT_TEMP
             WHERE RTE_ID_POS = P_ID_POSICAO
		  ORDER BY RTE_DATA DESC FETCH FIRST 1 ROW ONLY;
        ELSE
            SELECT RTE_TEMP_EQUIP
              INTO v_result
              FROM MAN_ROT_TEMP
             WHERE RTE_ID_POS = P_ID_POSICAO
          ORDER BY RTE_DATA DESC FETCH FIRST 1 ROW ONLY;
        END IF;

        RETURN v_result;
    END;


    FUNCTION FN_GET_VELOCIDADE (
        P_ID_POSICAO NUMBER
    ) RETURN NUMBER IS
        v_vel NUMBER;
    BEGIN
        SELECT RTE_VELOCIDADE
          INTO v_vel
          FROM MAN_ROT_TEMP
         WHERE RTE_ID_POS = P_ID_POSICAO
           AND RTE_DATA = (
               SELECT MAX(RTE_DATA)
                 FROM MAN_ROT_TEMP
                WHERE RTE_ID_POS = P_ID_POSICAO
           );

        RETURN v_vel;
    END;


    FUNCTION FN_GET_TEMPO_MAQUINA (
        P_ID_POSICAO NUMBER
    ) RETURN NUMBER IS
        v_dias NUMBER;
    BEGIN
        SELECT TRUNC(SYSDATE - POS_DT_INSTALACAO)
          INTO v_dias
          FROM CAD_POSICAO
         WHERE ID_POSICAO = P_ID_POSICAO
           AND POS_ATIVO = 'S';

        RETURN v_dias;
    END;


	FUNCTION FN_GET_TEMP_BASE_POSICAO (
		P_ID_POSICAO IN NUMBER
	) RETURN NUMBER IS
		v_temp_base NUMBER;
	BEGIN
		SELECT POS_TEMP_BASE
		  INTO v_temp_base
		  FROM CAD_POSICAO
		 WHERE ID_POSICAO = P_ID_POSICAO
		   AND POS_ATIVO = 'S';

		RETURN v_temp_base;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	
	
	FUNCTION FN_CALCULAR_LUBRIFICACAO (
		P_ID_POSICAO IN NUMBER
	) RETURN NUMBER IS

		v_id_equip        NUMBER;
		v_freq_lub        NUMBER;
		v_data_base       DATE := SYSDATE;

		v_ultima_lub      DATE;
		v_prox_lub        DATE;

		v_dias_total      NUMBER;
		v_dias_restantes  NUMBER;

		v_indice_lub      NUMBER;

	BEGIN
		------------------------------------------------------------------
		-- 1) Identificar o equipamento vinculado à posição
		------------------------------------------------------------------
		SELECT POS_ID_EQUIP
		  INTO v_id_equip
		  FROM CAD_POSICAO
		 WHERE ID_POSICAO = P_ID_POSICAO
		   AND POS_ATIVO = 'S';

		------------------------------------------------------------------
		-- 2) Buscar frequência de lubrificação do equipamento
		------------------------------------------------------------------
		SELECT EQU_FREQ_LUB
		  INTO v_freq_lub
		  FROM CAD_EQUIPAMENTO
		 WHERE ID_EQUIPAMENTO = v_id_equip;

		------------------------------------------------------------------
		-- 3) Verificar última lubrificação registrada
		------------------------------------------------------------------
		BEGIN
			SELECT MAX(RLU_DATA)
			  INTO v_ultima_lub
			  FROM MAN_ROT_LUB
			 WHERE RLU_ID_POS = P_ID_POSICAO;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_ultima_lub := NULL;
		END;

		------------------------------------------------------------------
		-- 4) Definir data da próxima lubrificação
		------------------------------------------------------------------
		IF v_ultima_lub IS NOT NULL THEN
			v_prox_lub := v_ultima_lub + v_freq_lub;
		ELSE
			SELECT POS_DT_PROX_LUB
			  INTO v_prox_lub
			  FROM CAD_POSICAO
			 WHERE ID_POSICAO = P_ID_POSICAO
			   AND POS_ATIVO = 'S';
		END IF;

		------------------------------------------------------------------
		-- 5) Calcular intervalo e índice
		------------------------------------------------------------------
		v_dias_total     := v_freq_lub;
		v_dias_restantes := v_prox_lub - v_data_base;

		-- Normalização simples:
		-- 100 = recém lubrificado
		-- 0   = totalmente vencido
		v_indice_lub := (v_dias_restantes / v_dias_total) * 100;

		-- Garantir faixa válida
		IF v_indice_lub < 0 THEN
			v_indice_lub := 0;
		ELSIF v_indice_lub > 100 THEN
			v_indice_lub := 100;
		END IF;

		RETURN v_indice_lub;

	EXCEPTION
		WHEN OTHERS THEN
			-- Em caso de erro, retorna valor neutro para não quebrar o fuzzy
			RETURN 50;
	END;
	
	
	PROCEDURE PR_GET_DADOS_VELOCIDADE (
		P_ID_EQUIPAMENTO IN  NUMBER,
		O_VEL_BASE       OUT NUMBER,
		O_VEL_CONS       OUT CHAR
	) IS
	BEGIN
		SELECT EQU_RPM,
			   EQU_RPM_FIXO
		  INTO O_VEL_BASE,
			   O_VEL_CONS
		  FROM CAD_EQUIPAMENTO
		 WHERE ID_EQUIPAMENTO = P_ID_EQUIPAMENTO;
	END;


    ----------------------------------------------------------------
    -- FUNÇÃO PRINCIPAL – VERSÃO TRIGGER
    ----------------------------------------------------------------
    FUNCTION FN_ANALISAR_EQUIPAMENTO (
        P_ID_POSICAO IN NUMBER
    ) RETURN NUMBER IS

        v_data_inspecao    DATE := SYSDATE;
        v_temp_ambiente    NUMBER;
        v_temp_equipamento NUMBER;
        v_velocidade       NUMBER;
        v_tempo_maq        NUMBER;

    BEGIN
        -- BUSCA DADOS BASE
		v_temp_ambiente    := FN_GET_ULTIMA_ROT_TEMP(P_ID_POSICAO, 'AMB');
        v_temp_equipamento := FN_GET_ULTIMA_ROT_TEMP(P_ID_POSICAO, 'EQUIP');
        v_velocidade       := FN_GET_VELOCIDADE(P_ID_POSICAO);
        v_tempo_maq        := FN_GET_TEMPO_MAQUINA(P_ID_POSICAO);
		
        RETURN FN_ANALISAR_EQUIPAMENTO(
            P_ID_POSICAO,
            v_temp_ambiente,
            v_temp_equipamento,
            v_velocidade,
            v_tempo_maq
        );
    END;


    ----------------------------------------------------------------
    -- FUNÇÃO PRINCIPAL – VERSÃO COMPLETA
    ----------------------------------------------------------------
    FUNCTION FN_ANALISAR_EQUIPAMENTO (
        P_ID_POSICAO        IN NUMBER,
        P_TEMP_AMBIENTE     IN NUMBER,
        P_TEMP_EQUIPAMENTO  IN NUMBER,
        P_VELOCIDADE        IN NUMBER,
        P_TEMP_MAQ          IN NUMBER
    ) RETURN NUMBER IS
	
		v_id_equip         NUMBER;
		v_data_inspecao    DATE := SYSDATE;
		v_temp_base_equip  NUMBER;
		v_vel_base         NUMBER;
        v_vel_cons         CHAR(1);
		v_lubrificacao     NUMBER;
		
		-- Variáveis fuzzificadas
        v_ta_baixa   NUMBER;
        v_ta_normal  NUMBER;
        v_ta_alta    NUMBER;

        v_te_normal     NUMBER;
        v_te_aquecendo  NUMBER;
        v_te_quente     NUMBER;

        v_vel_baixa  NUMBER;
        v_vel_normal NUMBER;
        v_vel_alta   NUMBER;
        
        v_lub_relub    NUMBER;
        v_lub_normal   NUMBER;
        v_lub_vencer   NUMBER;
        v_lub_atrasado NUMBER;
        
        v_tempo_pouco NUMBER;
        v_tempo_longo NUMBER;

		-- Saidas Linguisticas
		v_estado_linguistico VARCHAR2(200);
		v_estado_dominante   VARCHAR2(20);
        
        -- Saídas da inferência
        v_normal    NUMBER := 0;
        v_aceitavel NUMBER := 0;
        v_alerta    NUMBER := 0;
        v_falha     NUMBER := 0;

        v_resultado NUMBER;
    BEGIN
        
		v_id_equip := FN_GET_ID_EQUIPAMENTO(P_ID_POSICAO);
		v_lubrificacao 	   := FN_CALCULAR_LUBRIFICACAO(P_ID_POSICAO);
		v_temp_base_equip := FN_GET_TEMP_BASE_POSICAO(P_ID_POSICAO);
		PR_GET_DADOS_VELOCIDADE(
			v_id_equip,
			v_vel_base,
			v_vel_cons
		);

		
		-- FUZZIFICAÇÃO
        v_ta_baixa  := FN_FUZZ_TEMP_AMBIENTE(P_TEMP_AMBIENTE, 'Baixa');
        v_ta_normal := FN_FUZZ_TEMP_AMBIENTE(P_TEMP_AMBIENTE, 'Normal');
        v_ta_alta   := FN_FUZZ_TEMP_AMBIENTE(P_TEMP_AMBIENTE, 'Alta');

        v_te_normal    := FN_FUZZ_TEMP_EQUIP(P_TEMP_EQUIPAMENTO, v_temp_base_equip, 'Normal');
        v_te_aquecendo := FN_FUZZ_TEMP_EQUIP(P_TEMP_EQUIPAMENTO, v_temp_base_equip, 'Aquecendo');
        v_te_quente    := FN_FUZZ_TEMP_EQUIP(P_TEMP_EQUIPAMENTO, v_temp_base_equip, 'Quente');

        v_vel_baixa  := FN_FUZZ_VELOCIDADE(P_VELOCIDADE, v_vel_base, v_vel_cons, 'Baixa');
        v_vel_normal := FN_FUZZ_VELOCIDADE(P_VELOCIDADE, v_vel_base, v_vel_cons, 'Normal');
        v_vel_alta   := FN_FUZZ_VELOCIDADE(P_VELOCIDADE, v_vel_base, v_vel_cons, 'Alta');

        v_lub_relub    := FN_FUZZ_LUBRIFICACAO(v_lubrificacao, 'Relubrificado');
        v_lub_normal   := FN_FUZZ_LUBRIFICACAO(v_lubrificacao, 'Normal');
        v_lub_vencer   := FN_FUZZ_LUBRIFICACAO(v_lubrificacao, 'Vencer');
        v_lub_atrasado := FN_FUZZ_LUBRIFICACAO(v_lubrificacao, 'Atrasado');
        
        v_tempo_pouco := FN_FUZZ_TEMPO_MAQUINA(P_TEMP_MAQ, 'Pouco');
        v_tempo_longo := FN_FUZZ_TEMPO_MAQUINA(P_TEMP_MAQ, 'Longo');

        -- INFERÊNCIA 
        PR_INFERENCIA(
            -- entradas fuzzificadas
            v_ta_baixa,
            v_ta_normal,
            v_ta_alta,

            v_te_normal,
            v_te_aquecendo,
            v_te_quente,

            v_vel_baixa,
            v_vel_normal,
            v_vel_alta,

            v_lub_relub,
            v_lub_normal,
            v_lub_vencer,
            v_lub_atrasado,

            v_tempo_pouco,
            v_tempo_longo,

            -- saídas
            v_normal,
            v_aceitavel,
            v_alerta,
            v_falha
        );

        -- DESFUZZIFICAÇÃO
        v_resultado := FN_DEFUZZIFICAR(
            v_normal,
            v_aceitavel,
            v_alerta,
            v_falha
        );

		-- PERTINENCIA
		PR_PERTINENCIA_STATUS(
		    p_grau      => v_resultado,
		    o_normal    => v_normal,
		    o_aceitavel => v_aceitavel,
		    o_alerta    => v_alerta,
		    o_falha     => v_falha
		);

		-- Retorno estado Linguistico Proporcional
		v_estado_linguistico := FN_INTERPRETAR_ESTADO(
			v_normal,
			v_aceitavel,
			v_alerta,
			v_falha
		);

		-- Retorno estado Linguistico Dominante
		v_estado_dominante := FN_ESTADO_DOMINANTE(
			v_normal,
			v_aceitavel,
			v_alerta,
			v_falha
		);

		--Salvar na tabela
		INSERT INTO MAN_FALHA (
		    FAL_ID_POS,
			--FAL_ID_R_TEMP,
			--FAL_ID_R_LUB,
			--FAL_ID_OCORRENCIA,
			--FAL_ID_TP_ALERTA,
		    FAL_DATA,
		    FAL_FUZZY_NUM,
		    FAL_FUZZY_LING,
		    FAL_FUZZY_DOM,
		    FAL_GRAU_NORMAL,
		    FAL_GRAU_ACEITAVEL,
		    FAL_GRAU_ALERTA,
		    FAL_GRAU_FALHA
		) VALUES (
		    P_ID_POSICAO,
			--FAL_ID_R_TEMP,
			--FAL_ID_R_LUB,
			--FAL_ID_OCORRENCIA,
			--FAL_ID_TP_ALERTA,
		    SYSDATE,
		    v_resultado,
		    v_estado_linguistico,
		    v_estado_dominante,
		    v_normal,
		    v_aceitavel,
		    v_alerta,
		    v_falha
		);

		RETURN v_resultado;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
		WHEN OTHERS THEN
			-- opcional: log futuro
			RETURN NULL;
	END;

END PKG_ANALISE_FUZZY;
/


/*
OBSERVAÇÔES
Criar indice na tabela RTE -> (RTE_ID_POS, RTE_DATA DESC)
Fazer função para atualizar / registrar falha

*/
