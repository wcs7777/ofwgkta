DROP FUNCTION IF EXISTS FormatoMoeda //
CREATE FUNCTION FormatoMoeda(valor DOUBLE(7, 2))
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
	RETURN Replace(Format(valor, 2), '.', ',');
END //

DROP FUNCTION IF EXISTS MinusculoSemAcento //
CREATE FUNCTION MinusculoSemAcento(str VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	SET @str := Lower(str);
	SET @comAcento := 'àáâãèéêìíîòóôõùúûç';
	SET @semAcento := 'aaaaeeeiiioooouuuc';
	SET @i := Length(@comAcento);

	WHILE @i > 0 DO
		SET @str := Replace(
		  @str,
		  SubStr(@comAcento, @i, 1),
		  SubStr(@semAcento, @i, 1)
		);
		SET @i = @i - 1;
	END WHILE;

	RETURN @str;
END //

DROP FUNCTION IF EXISTS QuantidadeEstoque //
CREATE FUNCTION QuantidadeEstoque(IdProduto INT)
RETURNS INT
READS SQL DATA
BEGIN
	SELECT
		Sum(l.qtd)
	INTO
		@qtd
	FROM
		lote AS l
	WHERE
		l.idProduto = idProduto;

	RETURN If(@qtd IS NOT NULL, @qtd, 0);
END //

DROP FUNCTION IF EXISTS VendasPeriodo //
CREATE FUNCTION VendasPeriodo(idProduto INT, periodo INT)
RETURNS INT
READS SQL DATA
BEGIN
	SELECT
		Sum(i.qtd)
	INTO
		@vendas
	FROM
		item_pedido AS i
	INNER JOIN
		pedido      AS p
	ON
		i.idProduto = idProduto AND
		i.idPedido = p.id
	WHERE
		If(periodo >= 0, (DateDiff(Now(), p.feito) <= periodo), TRUE);

	RETURN If(@vendas IS NOT NULL, @vendas, 0);
END //

DROP FUNCTION IF EXISTS StatusValidade //
CREATE FUNCTION StatusValidade(validade DATE, tolerancia INT)
RETURNS VARCHAR(7)
DETERMINISTIC
BEGIN
	SET @diff := DateDiff(validade, Now());

	IF @diff > tolerancia THEN
		RETURN 'Normal';
	ELSEIF @diff > 0 THEN
		RETURN 'Perto';
	ELSE
		RETURN 'Vencido';
	END IF;
END //

DROP FUNCTION IF EXISTS ConsumoMedio //
CREATE FUNCTION ConsumoMedio(idProduto INT, periodo INT)
RETURNS DOUBLE
READS SQL DATA
BEGIN
	SET @total := VendasPeriodo(idProduto, periodo);

	RETURN If(@total > 0, @total/periodo, 0);
END //

DROP FUNCTION IF EXISTS TempoReposicao //
CREATE FUNCTION TempoReposicao(idProduto INT)
RETURNS INT
READS SQL DATA
BEGIN
	SELECT
		DateDiff(r.entregue, r.feito)
	INTO
		@tempo
	FROM
		requisicao AS r
	INNER JOIN
		fornecedor AS f
	ON
		f.idProduto = idProduto AND
		f.id = r.idFornecedor
	WHERE
		r.entregue = (
			SELECT
				Max(r.entregue)
			FROM
				requisicao AS r
			INNER JOIN
				fornecedor AS f
			ON
				f.idProduto = idProduto AND
				f.id = r.idFornecedor
		)
	LIMIT
		1;

	RETURN If(@tempo IS NOT NULL, @tempo, 0);
END //

DROP FUNCTION IF EXISTS EstoqueMinimo //
CREATE FUNCTION EstoqueMinimo(idProduto INT, periodo INT)
RETURNS INT
READS SQL DATA
BEGIN
	RETURN ConsumoMedio(idProduto, periodo) * TempoReposicao(idProduto);
END //

DROP FUNCTION IF EXISTS PontoDePedido //
CREATE FUNCTION PontoDePedido(estoqueMinimo INT)
RETURNS INT DETERMINISTIC
BEGIN
	RETURN estoqueMinimo * 2;
END //

DROP FUNCTION IF EXISTS StatusQuantidade //
CREATE FUNCTION StatusQuantidade(idProduto INT, periodo INT)
RETURNS VARCHAR(6) DETERMINISTIC
READS SQL DATA
BEGIN
	SET @quantidade := QuantidadeEstoque(idProduto);
	SET @minimo := EstoqueMinimo(idProduto, periodo);

	IF @quantidade > PontoDePedido(@minimo) THEN
		RETURN 'Seguro';
	ELSEIF @quantidade > @minimo THEN
		RETURN 'Baixo';
	ELSE
		RETURN 'Alerta';
	END IF;
END //

DROP FUNCTION IF EXISTS RetirarProduto //
CREATE FUNCTION RetirarProduto(id INT, quantidade INT)
RETURNS BOOLEAN
READS SQL DATA
BEGIN
	DECLARE fim BOOLEAN DEFAULT FALSE;
	DECLARE idLote, qtdLote, reserva INT DEFAULT 0;

	DECLARE cur CURSOR FOR (
		SELECT
			l.id,
			l.qtd
		FROM
			lote AS l
		WHERE
			l.idProduto = id
		ORDER BY
			l.validade
	);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET fim := TRUE;

	OPEN cur;
	SET @sucesso := FALSE;

	WHILE (quantidade > reserva) AND (NOT fim) DO
		FETCH
			cur
		INTO
			idLote,
			qtdLote;

		IF (NOT fim) AND (qtdLote > quantidade - reserva) THEN
			SET qtdLote := qtdLote - (quantidade - reserva);
			SET reserva := reserva + (quantidade - reserva);

			UPDATE
				lote AS l
			SET
				l.qtd = qtdLote
			WHERE
				l.id = idLote;
		ELSEIF (NOT fim) THEN
			SET reserva := reserva + qtdLote;

			DELETE
				l
			FROM
				lote AS l
			WHERE
				l.id = idLote;
		END IF;
	END WHILE;

	CLOSE cur;

	IF NOT fim THEN
		SET @sucesso := TRUE;
	END IF;

	RETURN @sucesso;
END //

DROP PROCEDURE IF EXISTS CriarTabelaAuxiliar_EstoqueAbc //
CREATE PROCEDURE CriarTabelaAuxiliar_EstoqueAbc()
BEGIN
	DROP TABLE IF EXISTS auxiliar;

	CREATE TEMPORARY TABLE auxiliar AS (
		SELECT
			p.id                              AS id,
			QuantidadeEstoque(p.id)           AS quantidade,
			p.preco * QuantidadeEstoque(p.id) AS valor
		FROM
			produto AS p
		ORDER BY
			valor
		DESC
	);
END //

DROP PROCEDURE IF EXISTS CriarTabelaAuxiliar_VendaAbc //
CREATE PROCEDURE CriarTabelaAuxiliar_VendaAbc(periodo INT)
BEGIN
	DROP TABLE IF EXISTS auxiliar;

	CREATE TEMPORARY TABLE auxiliar AS (
		SELECT
			p.id                                   AS id,
			VendasPeriodo(p.id, periodo)           AS quantidade,
			p.preco * VendasPeriodo(p.id, periodo) AS valor
		FROM
			produto AS p
		ORDER BY
			valor
		DESC
	);
END //
CALL CriarTabelaAuxiliar_EstoqueAbc() //

DROP PROCEDURE IF EXISTS CriarTabelaRelativa //
CREATE PROCEDURE CriarTabelaRelativa()
BEGIN
	SELECT
		Sum(valor)
	INTO
		@total
	FROM
		auxiliar;

	IF @total IS NULL THEN
		SET @total := 1.0;
	END IF;

	DROP TABLE IF EXISTS relativa;

	CREATE TEMPORARY TABLE relativa AS (
		SELECT
			a.id           AS id,
			valor / @total AS porcentagem
		FROM
			auxiliar AS a
	);
END //
CALL CriarTabelaRelativa() //

DROP PROCEDURE IF EXISTS CriarTabelaAcumulada //
CREATE PROCEDURE CriarTabelaAcumulada()
BEGIN
	DECLARE idRelativa INT DEFAULT 0;
	DECLARE pctRelativa, pctAcumulada DOUBLE DEFAULT 0.0;
	DECLARE fim BOOLEAN DEFAULT FALSE;
	DECLARE cur CURSOR FOR (
		SELECT
			r.id,
			r.porcentagem
		FROM
			relativa AS r
	);
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET fim := TRUE;
	DROP TABLE IF EXISTS acumulada;

	CREATE TEMPORARY TABLE acumulada (
		id INT PRIMARY KEY,
		porcentagem DOUBLE
	);

	OPEN cur;

	WHILE NOT fim DO
		FETCH
			cur
		INTO
			idRelativa,
			pctRelativa;

		IF NOT fim THEN
			SET pctAcumulada := pctAcumulada + pctRelativa;

			INSERT INTO
				acumulada (id, porcentagem)
			VALUES
				(idRelativa, pctAcumulada);
		END IF;
	END WHILE;

	CLOSE cur;
END //

DROP FUNCTION IF EXISTS CategoriaAbc //
CREATE FUNCTION CategoriaAbc(porcentagem DOUBLE)
RETURNS CHAR(1)
DETERMINISTIC
BEGIN
	IF porcentagem < 0.7099 THEN
		RETURN 'A';
	ELSEIF porcentagem < 0.9099 THEN
		RETURN 'B';
	ELSE
		RETURN 'C';
	END IF;
END //
