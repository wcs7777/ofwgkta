DROP DATABASE IF EXISTS ofwgkta;
CREATE DATABASE ofwgkta;
USE ofwgkta;

CREATE TABLE produto (
	id INT PRIMARY KEY AUTO_INCREMENT,
	nome VARCHAR(30) NOT NULL UNIQUE,
	preco DOUBLE(7, 2) NOT NULL
);

CREATE TABLE lote (
	id INT PRIMARY KEY AUTO_INCREMENT,
	idProduto INT NOT NULL,
	qtd INT NOT NULL,
	validade DATE NOT NULL
);

CREATE TABLE pedido (
	id INT PRIMARY KEY AUTO_INCREMENT,
	feito DATE NOT NULL
);

CREATE TABLE item_pedido (
	idPedido INT NOT NULL,
	idProduto INT NOT NULL,
	qtd INT NOT NULL
);

CREATE TABLE fornecedor (
	id INT PRIMARY KEY AUTO_INCREMENT,
	nome VARCHAR(20) NOT NULL,
	contato VARCHAR(20) NOT NULL,
	idProduto INT NOT NULL
);

CREATE TABLE requisicao (
	id INT PRIMARY KEY AUTO_INCREMENT,
	idFornecedor INT NOT NULL,
	qtd INT NOT NULL,
	feito DATE NOT NULL,
	previsto DATE NOT NULL,
	entregue DATE
);

ALTER TABLE lote
	ADD CONSTRAINT fk_idProduto_lote
		FOREIGN KEY (idProduto)
		REFERENCES produto(id);

ALTER TABLE item_pedido
	ADD CONSTRAINT fk_idPedido_item_pedido
		FOREIGN KEY (idPedido)
		REFERENCES pedido(id),
	ADD CONSTRAINT fk_idProduto_item_pedido
		FOREIGN KEY (idProduto)
		REFERENCES produto(id);

ALTER TABLE fornecedor
	ADD CONSTRAINT fk_idProduto_fornecedor
		FOREIGN KEY (idProduto)
		REFERENCES produto(id);

ALTER TABLE requisicao
	ADD CONstRAINT fk_idFornecedor_requisicao
		FOREIGN KEY (idFornecedor)
		REFERENCES fornecedor(id);

DELIMITER //

DROP PROCEDURE IF EXISTS crieUsuarioBancoOfwgkta //
CREATE PROCEDURE crieUsuarioBancoOfwgkta()
BEGIN
	SELECT
		count(*)
	INTO
		@existe
	FROM
		mysql.user
	WHERE
		mysql.user.host = 'localhost' AND
		mysql.user.user = 'usuario_ofwgkta'
	LIMIT 1;

	IF @existe THEN
		DROP USER 'usuario_ofwgkta'@'localhost';
	END IF;

	CREATE USER
		'usuario_ofwgkta'@'localhost'
	IDENTIFIED BY
		'oddfuture';

	GRANT
		EXECUTE
	ON
		`ofwgkta`.*
	TO
		'usuario_ofwgkta'@'localhost';

	FLUSH PRIVILEGES;
END //

CALL crieUsuarioBancoOfwgkta() //
DROP PROCEDURE IF EXISTS crieUsuarioBancoOfwgkta //

DELIMITER ;

DELIMITER //

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

DROP PROCEDURE IF EXISTS AdicionarProduto //
CREATE PROCEDURE AdicionarProduto(nome VARCHAR(30), preco DOUBLE(7, 2))
BEGIN
	INSERT INTO
		produto (nome, preco)
	VALUES
		(Trim(nome), preco);
END //

DROP PROCEDURE IF EXISTS AdicionarLote //
CREATE PROCEDURE AdicionarLote(idProduto INT, quantidade INT, validade DATE)
BEGIN
	INSERT INTO
		lote (idProduto, qtd, validade)
	VALUES
		(idProduto, quantidade, validade);
END //

DROP PROCEDURE IF EXISTS AdicionarPedido //
CREATE PROCEDURE AdicionarPedido()
BEGIN
	INSERT INTO
		pedido (id, feito)
	VALUE
		(@id, Now());

	SELECT LAST_INSERT_ID() AS id;
END //

DROP PROCEDURE IF EXISTS AdicionarProdutosAoPedido //
CREATE PROCEDURE AdicionarProdutosAoPedido(
	idPedido   INT,
	idProduto  INT,
	quantidade INT
)
BEGIN
	SELECT
		RetirarProduto(idProduto, quantidade)
	INTO
		@sucesso;

	IF @sucesso THEN
		INSERT INTO
			item_pedido (idPedido, idProduto, qtd)
		VALUES
			(idPedido, idProduto, quantidade);
	END IF;

	SELECT @sucesso;
END //

DROP PROCEDURE IF EXISTS AdicionarFornecedor //
CREATE PROCEDURE AdicionarFornecedor(
	nome VARCHAR(20),
	contato VARCHAR(20),
	idProduto INT
)
BEGIN
	INSERT INTO
		fornecedor (nome, contato, idProduto)
	VALUES
		(Trim(nome), Trim(contato), idProduto);
END //

DROP PROCEDURE IF EXISTS AdicionarRequisicao //
CREATE PROCEDURE AdicionarRequisicao(
	idFornecedor INT,
	quantidade INT,
	previsto DATE
)
BEGIN
	INSERT INTO
		requisicao (idFornecedor, qtd, feito, previsto)
	VALUES
		(idFornecedor, quantidade, Now(), previsto);
END //

DROP PROCEDURE IF EXISTS ReceberRequisicao //
CREATE PROCEDURE ReceberRequisicao(id INT)
BEGIN
	UPDATE
		requisicao AS r
	SET
		r.entregue = Now()
	WHERE
		r.id = id;
END //

DROP PROCEDURE IF EXISTS EditarProduto //
CREATE PROCEDURE EditarProduto(id INT, nome VARCHAR(30), preco DOUBLE(7, 2))
BEGIN
	UPDATE
		produto AS p
	SET
		p.nome = Trim(nome),
		p.preco = preco
	WHERE
		p.id = id;
END //

DROP PROCEDURE IF EXISTS EditarFornecedor //
CREATE PROCEDURE EditarFornecedor(
	id INT,
	nome VARCHAR(20),
	contato VARCHAR(20),
	idProduto INT
)
BEGIN
	UPDATE
		fornecedor AS f
	SET
		f.nome = Trim(nome),
		f.contato = Trim(contato),
		f.idProduto = idProduto
	WHERE
		f.id = id;
END //

DROP PROCEDURE IF EXISTS Produtos //
CREATE PROCEDURE Produtos()
BEGIN
	SELECT
		p.id                    AS ID,
		p.nome                  AS Produto,
		QuantidadeEstoque(p.id) AS Quantidade,
		FormatoMoeda(p.preco)   AS Preço
	FROM
		produto AS p;
END //

DROP PROCEDURE IF EXISTS Fornecedores //
CREATE PROCEDURE Fornecedores()
BEGIN
	SELECT
		f.id      AS ID,
		f.nome    AS Fornecedor,
		f.contato AS Contato,
		p.nome    AS Produto
	FROM
		fornecedor AS f
	INNER JOIN
		produto    AS p
	ON
		f.idProduto = p.id;
END //

DROP PROCEDURE IF EXISTS Requisicoes //
CREATE PROCEDURE Requisicoes()
BEGIN
	SELECT
		r.id       AS Requisicao,
		p.nome     AS Produto,
		r.qtd      AS Quantidade,
		r.previsto AS Previsto
	FROM
		requisicao AS r
	INNER JOIN
		fornecedor AS f
	ON
		r.entregue IS NULL AND
		r.idFornecedor = f.id
	INNER JOIN
		produto    AS p
	ON
		f.idProduto = p.id;
END //

DROP PROCEDURE IF EXISTS RelatorioQuantidade //
CREATE PROCEDURE RelatorioQuantidade(periodo INT)
BEGIN
	SELECT
		p.nome                                      AS Produto,
		QuantidadeEstoque(p.id)                     AS Atual,
		EstoqueMinimo(p.id, periodo)                AS Mínimo,
		PontoDePedido(EstoqueMinimo(p.id, periodo)) AS 'Ponto pedido',
		StatusQuantidade(p.id, periodo)             AS Status
	FROM
		produto AS p;
END //

DROP PROCEDURE IF EXISTS RelatorioValidade //
CREATE PROCEDURE RelatorioValidade(tolerancia INT)
BEGIN
	SELECT
		p.nome                                 AS Produto,
		l.id                                   AS Lote,
		l.qtd                                  AS Quantidade,
		l.validade                             AS Validade,
		StatusValidade(l.validade, tolerancia) AS Status
	FROM
		produto AS p
	INNER JOIN
		lote    AS l
	ON
		p.id = l.idProduto;
END //

DROP PROCEDURE IF EXISTS EstoqueAbc //
CREATE PROCEDURE EstoqueAbc()
BEGIN
	CALL CriarTabelaAuxiliar_EstoqueAbc;
	CALL CriarTabelaRelativa;
	CALL CriarTabelaAcumulada;

	SELECT
		p.nome                        AS Produto,
		FormatoMoeda(p.preco)         AS Preço,
		aux.quantidade                AS Estoque,
		CategoriaAbc(acu.porcentagem) AS Categoria
	FROM
		produto   AS p
	INNER JOIN
		auxiliar  AS aux
	ON
		p.id = aux.id
	INNER JOIN
		acumulada AS acu
	ON
		p.id = acu.id;
END //

DROP PROCEDURE IF EXISTS VendaAbc //
CREATE PROCEDURE VendaAbc(periodo INT)
BEGIN
	CALL CriarTabelaAuxiliar_VendaAbc(periodo);
	CALL CriarTabelaRelativa;
	CALL CriarTabelaAcumulada;

	SELECT
		p.nome                        AS Produto,
		FormatoMoeda(p.preco)         AS Preço,
		aux.quantidade                AS Vendidos,
		CategoriaAbc(acu.porcentagem) AS Categoria
	FROM
		produto   AS p
	INNER JOIN
		auxiliar  AS aux
	ON
		p.id = aux.id
	INNER JOIN
		acumulada AS acu
	ON
		p.id = acu.id;
END //

DROP PROCEDURE IF EXISTS PrecoProduto //
CREATE PROCEDURE PrecoProduto(id INT)
BEGIN
	SELECT
		p.preco AS preco
	FROM
		produto AS p
	WHERE
		p.id = id;
END //

DROP PROCEDURE IF EXISTS NomeIdProdutos //
CREATE PROCEDURE NomeIdProdutos()
BEGIN
	SELECT
		MinusculoSemAcento(nome) AS Nome,
		id                       AS ID
	FROM
		produto
	ORDER BY
		Nome;
END //

DROP PROCEDURE IF EXISTS NomeProdutos //
CREATE PROCEDURE NomeProdutos()
BEGIN
	SELECT
		nome
	FROM
		produto
	ORDER BY
		nome;
END //

DROP PROCEDURE IF EXISTS ProdutosParaVenda //
CREATE PROCEDURE ProdutosParaVenda()
BEGIN
	SELECT
		nome,
		id,
		QuantidadeEstoque(id)
	FROM
		produto
	WHERE
		QuantidadeEstoque(id) > 0;
END //

DROP PROCEDURE IF EXISTS NomeIdFornecedores //
CREATE PROCEDURE NomeIdFornecedores()
BEGIN
	SELECT
		MinusculoSemAcento(nome) AS Nome,
		id                       AS ID
	FROM
		fornecedor
	ORDER BY
		Nome;
END //

DROP PROCEDURE IF EXISTS Lotes //
CREATE PROCEDURE Lotes(idProduto INT)
BEGIN
	SELECT
		p.nome     AS Produto,
		l.id       AS Lote,
		l.qtd      AS Quantidade,
		l.validade AS Validade
	FROM
		lote    AS l,
		produto AS p
	WHERE
		p.id = idProduto AND
		p.id = l.idProduto
	ORDER BY
		Validade;
END //

DELIMITER ;

/* Criado em: '2021-12-23' */

INSERT INTO
	produto (nome, preco)
VALUES
	('Açúcar Claro Orgânico NATIVE',     3.99),
	('Açúcar Cristal COLOMBO',           9.90),
	('Açúcar Mascavo MAIS VITA',         19.25),
	('Açúcar Orgânico Cristal ITAJÁ',    4.45),
	('Açúcar Refinado CARAVELAS',        2.35),
	('Açúcar Refinado DA BARRA',         2.63),
	('Adoçante em Pó GOLD',              6.99),
	('Adoçante em Pó LINEA',             15.94),
	('Adoçante em Pó ZERO CAL',          9.89),
	('Adoçante Líquido ADOCYL',          2.49),
	('Adoçante Líquido ASSUGRIN',        3.09),
	('Adoçante Líquido FINN',            11.75),
	('Atum Ralado GOMES DA COSTA',       4.79),
	('Bife Vegetal SUPERBOM',            11.90),
	('Ervilha Extra Fina BONDUELLE',     9.59),
	('Mini Milho LUCA',                  14.50),
	('Sardinha em Óleo COQUEIRO',        5.79),
	('Seleta de Legumes CASINO',         8.65),
	('Cogumelo RAIOLA',                  7.75),
	('Espinafre em Conserva CASINO',     7.29),
	('Pickles em Conserva',              8.90),
	('Beterraba em Conserva HEMMER',     15.25),
	('Almôndega ao Molho BORDON',        4.62),
	('Aspargos Branco CASINO',           34.75),
	('Alcachofra na Brasa LA PASTINA',   19.25),
	('Feijoada BORDON',                  12.50),
	('Cebolinha Cristal em Conserva',    9.90),
	('Cogumelo QUALITÁ',                 13.72),
	('Café Torrado e Moído CABLOCO',     8.99),
	('Café Solúvel PELÉ',                7.79),
	('Cápsulas de Café ORFEU',           24.25),
	('Licor de Creme de Café STOCK',     44.75),
	('Cappuccino Tradicional NESCAFÉ',   11.50),
	('Café à Vácuo Gourmet TOLEDO',      13.25),
	('Trigo para Kibe YOKI',             4.79),
	('Farinha de Milho Amarela YOKI',    3.79),
	('Amido de Milho QUALITÁ',           3.77),
	('Polvilho Doce YOKI',               6.39),
	('Massa para Tapioca YOKI',          8.59),
	('Polvilho Azedo YOKI',              9.49),
	('Arroz Integral Tipo 1 TAEQ',       4.23),
	('Arroz Preto CAMIL Gourmet',        9.39),
	('Arroz Agulinha Tipo 1 TIO JOÃO',   15.90),
	('Arroz Vermelho CAMIL Gourmet',     17.50),
	('Arroz Oriental Tipo 1 MOMIJI',     36.75),
	('Arroz Frânces Rasman CASINO',      8.89),
	('Sopa Creme de Galinha KNORR',      6.09),
	('Creme de Queijo MAGGI',            5.29),
	('Creme de Cebola VONO',             4.69),
	('Sopa de Caldo Verde VONO',         1.89),
	('Sopa de Legumes Congelada TAEQ',   19.90),
	('Sopa de Batata com Carne VONO',    1.89),
	('Óleo de Soja SOYA',                10.17),
	('Óleo de Canola PURIVEL',           5.35),
	('Óleo de Linhaça LINO OIL',         17.75),
	('Óleo de Milho LIZA',               5.55),
	('Óleo de Canola QUALITÁ',           6.22),
	('Óleo de Girassol LIZA',            5.95),
	('Azeite de Dendê CEPÊRA',           3.89),
	('Passata Di Pomodoro RAIOLA',       14.25),
	('Feijão Fradinho QUALITÁ',          4.58),
	('Feijão Branco YOKI',               7.59),
	('Feijão Preto Pronto CAMIL',        4.59),
	('Feijão Branco BONDUELLE',          9.59),
	('Feijão Carioca Tipo 1 QUALITÁ',    3.49),
	('Feijão Preto KI CALDO',            5.59),
	('Ovos Caipira ORGÂNICO',            15.59),
	('Pimenta Biquinho HEMMER',          16.90),
	('Pimenta Vermelha QUALITÁ',         5.59),
	('Sal Refinado LEBRE',               1.49),
	('Sal Refinado QUALITÁ',             1.25),
	('Sal Grosso Temperado KITANO',      5.65),
	('Pimenta Suave QUALITÁ',            4.75),
	('Sal Refinado CISNE',               2.09),
	('Sal Moído Iodado MAIS VITA',       4.19),
	('Sal Grosso Rosa Himalia SMART',    32.50),
	('Creme de Leite NESTLÉ',            4.65),
	('Creme de Leite ITAMBÉ',            3.75),
	('Palmito Orgânico TAEQ',            20.90),
	('Tremoço Português RAIOLA',         9.85),
	('Leite Aurora Desnatado 1L',        2.29),
	('Leite Fazenda Pasteurizado',       5.81),
	('Leite Fermentado Activia',         1.78),
	('Leite Corpus Desnatado UHT',       3.51),
	('Bolinho de Arroz Tio João',        9.69),
	('Canelone artesanal misto',         15.94),
	('Capeletti Massa Leve queijo',      6.15),
	('Macarrão Adria com ovos argola',   2.69),
	('Bruschetta La Pastina japaleno',   17.91),
	('Champignon Alca Fatiado Sachet',   5.92);

INSERT INTO
	lote (idProduto, qtd, validade)
VALUES
	(1, 50, '2021-11-13'),
	(2, 70, '2022-03-19'),
	(3, 80, '2022-01-12'),
	(4, 90, '2022-01-14'),
	(5, 70, '2022-03-28'),
	(6, 50, '2022-03-03'),
	(7, 80, '2021-11-18'),
	(8, 90, '2022-04-04'),
	(9, 60, '2021-10-27'),
	(10, 90, '2022-01-23'),
	(11, 60, '2022-02-13'),
	(12, 70, '2021-12-25'),
	(13, 60, '2022-03-05'),
	(14, 60, '2022-01-28'),
	(15, 60, '2022-02-25'),
	(16, 60, '2022-04-23'),
	(17, 80, '2022-04-11'),
	(18, 90, '2022-01-27'),
	(19, 70, '2022-03-29'),
	(20, 50, '2022-03-12'),
	(21, 50, '2022-02-23'),
	(22, 60, '2022-02-17'),
	(23, 80, '2022-04-02'),
	(24, 70, '2022-02-17'),
	(25, 50, '2021-12-10'),
	(26, 60, '2021-11-30'),
	(27, 70, '2022-03-10'),
	(28, 50, '2021-12-27'),
	(29, 70, '2022-04-17'),
	(30, 50, '2021-11-06'),
	(31, 50, '2021-11-11'),
	(32, 50, '2022-05-03'),
	(33, 80, '2022-01-07'),
	(34, 70, '2022-05-06'),
	(35, 90, '2021-11-28'),
	(36, 90, '2021-11-05'),
	(37, 50, '2022-02-13'),
	(38, 50, '2022-02-28'),
	(39, 80, '2022-05-01'),
	(40, 90, '2022-05-03'),
	(41, 50, '2022-04-01'),
	(42, 90, '2022-04-25'),
	(43, 50, '2022-03-31'),
	(44, 80, '2021-10-28'),
	(45, 90, '2021-12-10'),
	(46, 60, '2022-02-10'),
	(47, 60, '2021-11-11'),
	(48, 50, '2021-12-29'),
	(49, 70, '2022-05-16'),
	(50, 60, '2022-05-09'),
	(51, 50, '2022-02-12'),
	(52, 60, '2022-05-11'),
	(53, 70, '2022-05-14'),
	(54, 90, '2022-01-06'),
	(55, 70, '2022-04-09'),
	(56, 50, '2022-02-07'),
	(57, 60, '2022-02-07'),
	(58, 70, '2022-02-10'),
	(59, 90, '2021-12-26'),
	(60, 80, '2021-11-28'),
	(61, 60, '2021-11-18'),
	(62, 60, '2021-12-17'),
	(63, 50, '2022-03-03'),
	(64, 80, '2022-05-14'),
	(65, 60, '2022-03-11'),
	(66, 80, '2022-02-02'),
	(67, 90, '2022-04-26'),
	(68, 90, '2022-01-25'),
	(69, 80, '2022-05-04'),
	(70, 70, '2021-10-23'),
	(71, 90, '2021-10-31'),
	(72, 60, '2022-04-30'),
	(73, 90, '2022-03-03'),
	(74, 50, '2021-11-14'),
	(75, 50, '2021-11-03'),
	(76, 80, '2022-02-06'),
	(77, 70, '2021-10-29'),
	(78, 90, '2021-12-13'),
	(79, 90, '2022-04-09'),
	(80, 90, '2022-03-11'),
	(81, 90, '2022-01-05'),
	(82, 50, '2022-01-15'),
	(83, 60, '2022-02-14'),
	(84, 50, '2021-10-31'),
	(85, 60, '2022-05-08'),
	(86, 60, '2022-05-01'),
	(87, 90, '2022-02-12'),
	(88, 60, '2021-12-30'),
	(89, 70, '2022-01-06'),
	(90, 80, '2022-03-05'),
	(1, 70, '2022-04-12'),
	(2, 70, '2021-11-29'),
	(3, 60, '2021-12-19'),
	(4, 90, '2021-12-03'),
	(5, 90, '2022-05-13'),
	(6, 70, '2021-11-08'),
	(7, 90, '2022-03-08'),
	(8, 80, '2022-02-09'),
	(9, 80, '2022-01-11'),
	(10, 60, '2021-11-06'),
	(11, 70, '2021-12-08'),
	(12, 80, '2021-12-13'),
	(13, 90, '2021-11-04'),
	(14, 60, '2022-03-11'),
	(15, 70, '2022-02-15'),
	(16, 70, '2022-03-20'),
	(17, 90, '2022-02-04'),
	(18, 70, '2022-02-13'),
	(19, 50, '2021-12-07'),
	(20, 90, '2022-03-14'),
	(21, 50, '2021-11-04'),
	(22, 80, '2021-12-29'),
	(23, 50, '2022-05-04'),
	(24, 60, '2022-04-16'),
	(25, 90, '2021-11-27'),
	(26, 70, '2021-11-14'),
	(27, 90, '2021-11-25'),
	(28, 60, '2022-03-28'),
	(29, 70, '2022-03-08'),
	(30, 60, '2022-03-18'),
	(31, 70, '2021-11-30'),
	(32, 60, '2022-03-03'),
	(33, 90, '2022-01-26'),
	(34, 70, '2021-11-05'),
	(35, 70, '2022-03-29'),
	(36, 80, '2022-04-30'),
	(37, 90, '2021-11-09'),
	(38, 60, '2021-10-25'),
	(39, 50, '2022-02-04'),
	(40, 90, '2022-04-11'),
	(41, 90, '2022-03-10'),
	(42, 50, '2021-11-27'),
	(43, 80, '2022-03-10'),
	(44, 50, '2022-05-19'),
	(45, 80, '2021-12-06'),
	(46, 60, '2022-04-15'),
	(47, 80, '2022-02-28'),
	(48, 80, '2022-05-11'),
	(49, 70, '2022-04-23'),
	(50, 50, '2021-12-28'),
	(51, 50, '2022-03-23'),
	(52, 60, '2022-03-06'),
	(53, 60, '2021-10-30'),
	(54, 90, '2021-12-05'),
	(55, 60, '2022-01-06'),
	(56, 90, '2022-01-16'),
	(57, 90, '2021-12-09'),
	(58, 90, '2022-02-07'),
	(59, 50, '2021-12-09'),
	(60, 50, '2021-11-06'),
	(61, 90, '2022-02-11'),
	(62, 70, '2022-04-16'),
	(63, 50, '2022-02-14'),
	(64, 90, '2021-12-12'),
	(65, 60, '2022-03-28'),
	(66, 50, '2022-05-13'),
	(67, 70, '2022-02-10'),
	(68, 60, '2022-03-27'),
	(69, 70, '2022-03-10'),
	(70, 90, '2021-10-31'),
	(71, 90, '2021-11-10'),
	(72, 50, '2022-02-15'),
	(73, 90, '2021-12-24'),
	(74, 90, '2022-05-05'),
	(75, 80, '2022-05-10'),
	(76, 90, '2021-12-04'),
	(77, 50, '2022-04-27'),
	(78, 70, '2022-03-10'),
	(79, 90, '2022-01-10'),
	(80, 50, '2022-04-16'),
	(81, 80, '2022-01-27'),
	(82, 80, '2022-04-24'),
	(83, 60, '2022-04-01'),
	(84, 80, '2021-12-17'),
	(85, 50, '2022-03-13'),
	(86, 60, '2022-04-07'),
	(87, 70, '2022-05-04'),
	(88, 60, '2022-02-12'),
	(89, 60, '2022-04-28'),
	(90, 60, '2022-01-09'),
	(63, 70, '2022-04-03'),
	(50, 90, '2022-03-05'),
	(45, 70, '2022-01-04'),
	(32, 90, '2022-05-06'),
	(34, 70, '2021-11-17'),
	(88, 90, '2022-04-27'),
	(29, 60, '2021-10-24'),
	(61, 50, '2022-04-03'),
	(45, 70, '2022-01-30'),
	(7, 50, '2022-02-24'),
	(64, 50, '2022-01-31'),
	(63, 70, '2021-10-31'),
	(69, 70, '2021-12-19'),
	(51, 50, '2021-12-04'),
	(79, 70, '2022-04-02'),
	(27, 60, '2021-10-26'),
	(58, 90, '2022-04-04'),
	(68, 90, '2022-01-29'),
	(52, 80, '2021-11-25'),
	(51, 60, '2021-11-04'),
	(54, 70, '2021-12-03'),
	(63, 80, '2021-11-01'),
	(39, 60, '2022-03-20'),
	(83, 90, '2021-11-03'),
	(1, 50, '2021-10-28'),
	(4, 80, '2021-12-26'),
	(65, 90, '2022-01-16'),
	(61, 90, '2022-02-09'),
	(36, 60, '2021-11-14'),
	(56, 50, '2021-11-13'),
	(57, 50, '2022-05-05'),
	(4, 60, '2021-11-17'),
	(43, 70, '2022-04-04'),
	(64, 50, '2022-04-01'),
	(33, 60, '2021-11-02');

INSERT INTO
	pedido (feito)
VALUES
	('2021-10-23'),
	('2021-10-23'),
	('2021-10-23'),
	('2021-10-24'),
	('2021-10-24'),
	('2021-10-24'),
	('2021-10-25'),
	('2021-10-25'),
	('2021-10-25'),
	('2021-10-26'),
	('2021-10-26'),
	('2021-10-26'),
	('2021-10-27'),
	('2021-10-27'),
	('2021-10-27'),
	('2021-10-28'),
	('2021-10-28'),
	('2021-10-28'),
	('2021-10-29'),
	('2021-10-29'),
	('2021-10-29'),
	('2021-10-30'),
	('2021-10-30'),
	('2021-10-30'),
	('2021-10-31'),
	('2021-10-31'),
	('2021-10-31'),
	('2021-11-01'),
	('2021-11-01'),
	('2021-11-01'),
	('2021-11-02'),
	('2021-11-02'),
	('2021-11-02'),
	('2021-11-03'),
	('2021-11-03'),
	('2021-11-03'),
	('2021-11-04'),
	('2021-11-04'),
	('2021-11-04'),
	('2021-11-05'),
	('2021-11-05'),
	('2021-11-05'),
	('2021-11-06'),
	('2021-11-06'),
	('2021-11-06'),
	('2021-11-07'),
	('2021-11-07'),
	('2021-11-07'),
	('2021-11-08'),
	('2021-11-08'),
	('2021-11-08'),
	('2021-11-09'),
	('2021-11-09'),
	('2021-11-09'),
	('2021-11-10'),
	('2021-11-10'),
	('2021-11-10'),
	('2021-11-11'),
	('2021-11-11'),
	('2021-11-11'),
	('2021-11-12'),
	('2021-11-12'),
	('2021-11-12'),
	('2021-11-13'),
	('2021-11-13'),
	('2021-11-13'),
	('2021-11-14'),
	('2021-11-14'),
	('2021-11-14'),
	('2021-11-15'),
	('2021-11-15'),
	('2021-11-15'),
	('2021-11-16'),
	('2021-11-16'),
	('2021-11-16'),
	('2021-11-17'),
	('2021-11-17'),
	('2021-11-17'),
	('2021-11-18'),
	('2021-11-23'),
	('2021-11-23'),
	('2021-11-23'),
	('2021-11-24'),
	('2021-11-24'),
	('2021-11-24'),
	('2021-11-25'),
	('2021-11-25'),
	('2021-11-25'),
	('2021-11-26'),
	('2021-11-26'),
	('2021-11-26'),
	('2021-11-27'),
	('2021-11-27'),
	('2021-11-27'),
	('2021-11-28'),
	('2021-11-28'),
	('2021-11-28'),
	('2021-11-29'),
	('2021-11-29'),
	('2021-11-29'),
	('2021-11-30'),
	('2021-11-30'),
	('2021-11-30'),
	('2021-12-01'),
	('2021-12-01'),
	('2021-12-01'),
	('2021-12-02'),
	('2021-12-02'),
	('2021-12-02'),
	('2021-12-03'),
	('2021-12-03'),
	('2021-12-03'),
	('2021-12-04'),
	('2021-12-04'),
	('2021-12-04'),
	('2021-12-05'),
	('2021-12-05'),
	('2021-12-05'),
	('2021-12-06'),
	('2021-12-06'),
	('2021-12-06'),
	('2021-12-07'),
	('2021-12-07'),
	('2021-12-07'),
	('2021-12-08'),
	('2021-12-08'),
	('2021-12-08'),
	('2021-12-09'),
	('2021-12-09'),
	('2021-12-09'),
	('2021-12-10'),
	('2021-12-10'),
	('2021-12-10'),
	('2021-12-11'),
	('2021-12-11'),
	('2021-12-11'),
	('2021-12-12'),
	('2021-12-12'),
	('2021-12-12'),
	('2021-12-13'),
	('2021-12-13'),
	('2021-12-13'),
	('2021-12-14'),
	('2021-12-14'),
	('2021-12-14'),
	('2021-12-15'),
	('2021-12-15'),
	('2021-12-15'),
	('2021-12-16'),
	('2021-12-16'),
	('2021-12-16'),
	('2021-12-17'),
	('2021-12-17'),
	('2021-12-17'),
	('2021-12-18'),
	('2021-12-18'),
	('2021-12-18'),
	('2021-12-19'),
	('2021-12-23'),
	('2021-12-23'),
	('2021-12-23'),
	('2021-12-24'),
	('2021-12-24'),
	('2021-12-24'),
	('2021-12-25'),
	('2021-12-25'),
	('2021-12-25'),
	('2021-12-26'),
	('2021-12-26'),
	('2021-12-26'),
	('2021-12-27'),
	('2021-12-27'),
	('2021-12-27'),
	('2021-12-28'),
	('2021-12-28'),
	('2021-12-28'),
	('2021-12-29'),
	('2021-12-29'),
	('2021-12-29'),
	('2021-12-30'),
	('2021-12-30'),
	('2021-12-30'),
	('2021-12-31'),
	('2021-12-31'),
	('2021-12-31'),
	('2022-01-01'),
	('2022-01-01'),
	('2022-01-01'),
	('2022-01-02'),
	('2022-01-02'),
	('2022-01-02'),
	('2022-01-03'),
	('2022-01-03'),
	('2022-01-03'),
	('2022-01-04'),
	('2022-01-04'),
	('2022-01-04'),
	('2022-01-05'),
	('2022-01-05'),
	('2022-01-05'),
	('2022-01-06'),
	('2022-01-06'),
	('2022-01-06'),
	('2022-01-07'),
	('2022-01-07'),
	('2022-01-07'),
	('2022-01-08'),
	('2022-01-08'),
	('2022-01-08'),
	('2022-01-09'),
	('2022-01-09'),
	('2022-01-09'),
	('2022-01-10'),
	('2022-01-10'),
	('2022-01-10'),
	('2022-01-11'),
	('2022-01-11'),
	('2022-01-11'),
	('2022-01-12'),
	('2022-01-12'),
	('2022-01-12'),
	('2022-01-13'),
	('2022-01-13'),
	('2022-01-13'),
	('2022-01-14'),
	('2022-01-14'),
	('2022-01-14'),
	('2022-01-15'),
	('2022-01-15'),
	('2022-01-15');

INSERT INTO
	item_pedido (idPedido, idProduto, qtd)
VALUES
	(1, 12, 32),
	(1, 2, 21),
	(1, 59, 41),
	(2, 62, 43),
	(2, 53, 33),
	(2, 44, 44),
	(3, 29, 22),
	(3, 56, 33),
	(3, 60, 41),
	(4, 17, 38),
	(4, 28, 38),
	(4, 75, 31),
	(5, 13, 47),
	(5, 78, 30),
	(5, 70, 25),
	(6, 48, 29),
	(6, 58, 33),
	(6, 78, 23),
	(7, 70, 20),
	(7, 38, 31),
	(7, 29, 39),
	(8, 58, 32),
	(8, 36, 30),
	(8, 34, 34),
	(9, 54, 20),
	(9, 47, 43),
	(9, 42, 46),
	(10, 77, 50),
	(10, 46, 45),
	(10, 31, 42),
	(11, 10, 50),
	(11, 20, 20),
	(11, 88, 48),
	(12, 46, 44),
	(12, 5, 50),
	(12, 47, 21),
	(13, 30, 47),
	(13, 34, 50),
	(13, 29, 41),
	(14, 15, 37),
	(14, 12, 43),
	(14, 44, 38),
	(15, 13, 30),
	(15, 48, 25),
	(15, 69, 31),
	(16, 55, 37),
	(16, 64, 20),
	(16, 48, 50),
	(17, 53, 26),
	(17, 79, 23),
	(17, 14, 27),
	(18, 87, 37),
	(18, 37, 46),
	(18, 45, 20),
	(19, 32, 41),
	(19, 33, 30),
	(19, 37, 28),
	(20, 84, 42),
	(20, 30, 30),
	(20, 90, 31),
	(21, 78, 48),
	(21, 34, 36),
	(21, 56, 44),
	(22, 7, 30),
	(22, 67, 32),
	(22, 87, 25),
	(23, 18, 41),
	(23, 37, 30),
	(23, 56, 27),
	(24, 7, 41),
	(24, 82, 20),
	(24, 51, 21),
	(25, 51, 37),
	(25, 11, 20),
	(25, 7, 31),
	(26, 55, 33),
	(26, 47, 38),
	(26, 26, 39),
	(27, 62, 25),
	(27, 22, 43),
	(27, 64, 21),
	(28, 20, 49),
	(28, 60, 38),
	(28, 11, 34),
	(29, 67, 21),
	(29, 79, 50),
	(29, 5, 39),
	(30, 65, 26),
	(30, 46, 34),
	(30, 40, 36),
	(31, 20, 20),
	(31, 47, 39),
	(31, 9, 30),
	(32, 88, 35),
	(32, 31, 42),
	(32, 7, 31),
	(33, 3, 39),
	(33, 31, 49),
	(33, 27, 37),
	(34, 31, 29),
	(34, 10, 36),
	(34, 9, 23),
	(35, 54, 21),
	(35, 77, 24),
	(35, 85, 49),
	(36, 36, 47),
	(36, 2, 24),
	(36, 70, 29),
	(37, 36, 24),
	(37, 36, 23),
	(37, 22, 46),
	(38, 71, 37),
	(38, 7, 22),
	(38, 83, 33),
	(39, 80, 45),
	(39, 86, 24),
	(39, 23, 49),
	(40, 25, 30),
	(40, 65, 47),
	(40, 46, 22),
	(41, 42, 31),
	(41, 33, 29),
	(41, 66, 46),
	(42, 9, 22),
	(42, 24, 39),
	(42, 56, 42),
	(43, 7, 29),
	(43, 77, 48),
	(43, 61, 41),
	(44, 33, 38),
	(44, 1, 30),
	(44, 17, 21),
	(45, 86, 23),
	(45, 38, 47),
	(45, 87, 48),
	(46, 87, 36),
	(46, 84, 47),
	(46, 4, 44),
	(47, 32, 36),
	(47, 46, 43),
	(47, 19, 30),
	(48, 72, 26),
	(48, 53, 38),
	(48, 48, 36),
	(49, 38, 41),
	(49, 81, 45),
	(49, 40, 46),
	(50, 23, 26),
	(50, 57, 40),
	(50, 16, 34),
	(51, 45, 28),
	(51, 79, 48),
	(51, 9, 24),
	(52, 7, 25),
	(52, 2, 24),
	(52, 19, 45),
	(53, 29, 30),
	(53, 69, 39),
	(53, 51, 27),
	(54, 35, 44),
	(54, 74, 47),
	(54, 49, 28),
	(55, 29, 47),
	(55, 3, 39),
	(55, 84, 44),
	(56, 2, 42),
	(56, 30, 45),
	(56, 72, 35),
	(57, 59, 39),
	(57, 24, 41),
	(57, 17, 33),
	(58, 79, 27),
	(58, 6, 45),
	(58, 61, 38),
	(59, 59, 32),
	(59, 11, 26),
	(59, 73, 24),
	(60, 70, 39),
	(60, 83, 35),
	(60, 61, 22),
	(61, 42, 39),
	(61, 83, 43),
	(61, 28, 23),
	(62, 13, 25),
	(62, 4, 46),
	(62, 66, 26),
	(63, 37, 28),
	(63, 72, 28),
	(63, 20, 34),
	(64, 81, 48),
	(64, 16, 41),
	(64, 28, 30),
	(65, 31, 28),
	(65, 38, 50),
	(65, 27, 21),
	(66, 33, 42),
	(66, 62, 46),
	(66, 14, 48),
	(67, 56, 44),
	(67, 7, 40),
	(67, 69, 28),
	(68, 12, 21),
	(68, 63, 45),
	(68, 15, 36),
	(69, 42, 49),
	(69, 1, 36),
	(69, 52, 26),
	(70, 77, 41),
	(70, 89, 30),
	(70, 55, 23),
	(71, 57, 49),
	(71, 41, 39),
	(71, 83, 30),
	(72, 64, 50),
	(72, 34, 28),
	(72, 27, 20),
	(73, 54, 22),
	(73, 16, 24),
	(73, 78, 21),
	(74, 44, 21),
	(74, 34, 22),
	(74, 81, 43),
	(75, 80, 25),
	(75, 7, 22),
	(75, 68, 42),
	(76, 57, 24),
	(76, 23, 21),
	(76, 67, 43),
	(77, 61, 27),
	(77, 14, 20),
	(77, 74, 35),
	(78, 50, 42),
	(78, 68, 21),
	(78, 33, 48),
	(79, 32, 44),
	(79, 35, 46),
	(79, 67, 38),
	(80, 79, 35),
	(80, 41, 31),
	(80, 8, 21),
	(81, 87, 28),
	(81, 70, 44),
	(81, 24, 44),
	(82, 33, 41),
	(82, 79, 31),
	(82, 22, 26),
	(83, 70, 43),
	(83, 31, 42),
	(83, 59, 44),
	(84, 71, 21),
	(84, 79, 27),
	(84, 55, 20),
	(85, 37, 29),
	(85, 7, 20),
	(85, 60, 21),
	(86, 87, 40),
	(86, 33, 48),
	(86, 88, 21),
	(87, 76, 30),
	(87, 9, 41),
	(87, 14, 36),
	(88, 65, 36),
	(88, 41, 45),
	(88, 33, 24),
	(89, 86, 21),
	(89, 51, 43),
	(89, 29, 28),
	(90, 83, 20),
	(90, 39, 22),
	(90, 84, 26),
	(91, 59, 37),
	(91, 68, 41),
	(91, 73, 45),
	(92, 13, 32),
	(92, 7, 45),
	(92, 23, 49),
	(93, 29, 37),
	(93, 35, 22),
	(93, 14, 37),
	(94, 27, 40),
	(94, 51, 26),
	(94, 57, 39),
	(95, 48, 47),
	(95, 9, 21),
	(95, 60, 23),
	(96, 40, 43),
	(96, 61, 45),
	(96, 10, 30),
	(97, 70, 34),
	(97, 22, 44),
	(97, 39, 46),
	(98, 58, 46),
	(98, 83, 23),
	(98, 67, 39),
	(99, 73, 40),
	(99, 60, 22),
	(99, 72, 43),
	(100, 1, 25),
	(100, 6, 37),
	(100, 52, 43),
	(101, 35, 34),
	(101, 2, 31),
	(101, 42, 49),
	(102, 44, 23),
	(102, 26, 49),
	(102, 48, 35),
	(103, 80, 38),
	(103, 14, 25),
	(103, 38, 44),
	(104, 56, 47),
	(104, 34, 24),
	(104, 61, 50),
	(105, 16, 25),
	(105, 77, 31),
	(105, 65, 36),
	(106, 79, 43),
	(106, 62, 45),
	(106, 81, 25),
	(107, 44, 22),
	(107, 23, 36),
	(107, 74, 36),
	(108, 67, 42),
	(108, 84, 44),
	(108, 34, 45),
	(109, 4, 34),
	(109, 56, 50),
	(109, 61, 47),
	(110, 9, 31),
	(110, 43, 40),
	(110, 69, 35),
	(111, 17, 29),
	(111, 78, 31),
	(111, 22, 46),
	(112, 51, 27),
	(112, 11, 30),
	(112, 87, 24),
	(113, 41, 20),
	(113, 61, 37),
	(113, 89, 39),
	(114, 83, 37),
	(114, 34, 36),
	(114, 59, 45),
	(115, 21, 39),
	(115, 54, 23),
	(115, 49, 29),
	(116, 51, 35),
	(116, 36, 41),
	(116, 69, 36),
	(117, 61, 34),
	(117, 42, 35),
	(117, 9, 33),
	(118, 62, 43),
	(118, 11, 32),
	(118, 6, 20),
	(119, 18, 31),
	(119, 36, 32),
	(119, 44, 21),
	(120, 24, 26),
	(120, 81, 45),
	(120, 64, 27),
	(121, 71, 43),
	(121, 38, 44),
	(121, 38, 47),
	(122, 75, 20),
	(122, 5, 22),
	(122, 31, 29),
	(123, 69, 28),
	(123, 35, 42),
	(123, 70, 42),
	(124, 2, 22),
	(124, 15, 41),
	(124, 25, 45),
	(125, 84, 34),
	(125, 49, 42),
	(125, 61, 34),
	(126, 19, 24),
	(126, 56, 38),
	(126, 8, 27),
	(127, 32, 36),
	(127, 20, 33),
	(127, 11, 24),
	(128, 71, 36),
	(128, 59, 31),
	(128, 57, 39),
	(129, 36, 25),
	(129, 14, 31),
	(129, 63, 43),
	(130, 3, 33),
	(130, 31, 24),
	(130, 4, 38),
	(131, 77, 47),
	(131, 8, 43),
	(131, 43, 44),
	(132, 64, 35),
	(132, 19, 42),
	(132, 70, 22),
	(133, 58, 30),
	(133, 3, 22),
	(133, 30, 34),
	(134, 31, 33),
	(134, 72, 20),
	(134, 63, 30),
	(135, 54, 46),
	(135, 75, 26),
	(135, 82, 46),
	(136, 80, 26),
	(136, 10, 22),
	(136, 81, 23),
	(137, 30, 27),
	(137, 44, 21),
	(137, 6, 20),
	(138, 12, 41),
	(138, 73, 32),
	(138, 49, 33),
	(139, 53, 22),
	(139, 55, 31),
	(139, 70, 40),
	(140, 21, 48),
	(140, 27, 36),
	(140, 44, 24),
	(141, 70, 49),
	(141, 55, 28),
	(141, 3, 37),
	(142, 56, 27),
	(142, 23, 31),
	(142, 31, 49),
	(143, 55, 46),
	(143, 34, 23),
	(143, 31, 41),
	(144, 75, 30),
	(144, 24, 33),
	(144, 90, 32),
	(145, 11, 29),
	(145, 64, 33),
	(145, 88, 49),
	(146, 27, 27),
	(146, 39, 47),
	(146, 84, 48),
	(147, 82, 44),
	(147, 58, 40),
	(147, 19, 40),
	(148, 54, 39),
	(148, 79, 43),
	(148, 37, 24),
	(149, 15, 45),
	(149, 31, 43),
	(149, 3, 49),
	(150, 2, 24),
	(150, 7, 44),
	(150, 76, 35),
	(151, 56, 29),
	(151, 28, 20),
	(151, 76, 40),
	(152, 85, 30),
	(152, 89, 32),
	(152, 68, 28),
	(153, 41, 20),
	(153, 56, 49),
	(153, 78, 32),
	(154, 44, 27),
	(154, 28, 20),
	(154, 45, 27),
	(155, 63, 33),
	(155, 4, 20),
	(155, 51, 49),
	(156, 69, 23),
	(156, 3, 42),
	(156, 25, 26),
	(157, 40, 29),
	(157, 6, 42),
	(157, 61, 26),
	(158, 56, 48),
	(158, 51, 48),
	(158, 76, 29),
	(159, 87, 30),
	(159, 15, 49),
	(159, 20, 22),
	(160, 66, 49),
	(160, 50, 26),
	(160, 15, 21),
	(161, 28, 50),
	(161, 9, 31),
	(161, 44, 41),
	(162, 75, 24),
	(162, 55, 20),
	(162, 62, 50),
	(163, 51, 35),
	(163, 19, 21),
	(163, 16, 41),
	(164, 82, 39),
	(164, 84, 29),
	(164, 14, 39),
	(165, 42, 34),
	(165, 29, 38),
	(165, 33, 36),
	(166, 90, 22),
	(166, 21, 48),
	(166, 17, 38),
	(167, 26, 22),
	(167, 25, 41),
	(167, 44, 21),
	(168, 86, 35),
	(168, 62, 25),
	(168, 59, 27),
	(169, 61, 49),
	(169, 14, 39),
	(169, 12, 36),
	(170, 3, 38),
	(170, 56, 28),
	(170, 84, 23),
	(171, 53, 36),
	(171, 67, 21),
	(171, 61, 33),
	(172, 42, 49),
	(172, 23, 35),
	(172, 63, 44),
	(173, 22, 41),
	(173, 90, 44),
	(173, 16, 27),
	(174, 29, 33),
	(174, 67, 46),
	(174, 23, 22),
	(175, 21, 22),
	(175, 52, 23),
	(175, 27, 35),
	(176, 47, 33),
	(176, 33, 35),
	(176, 74, 40),
	(177, 31, 21),
	(177, 60, 34),
	(177, 68, 45),
	(178, 55, 36),
	(178, 44, 45),
	(178, 41, 20),
	(179, 17, 40),
	(179, 74, 27),
	(179, 49, 38),
	(180, 16, 42),
	(180, 73, 37),
	(180, 35, 22),
	(181, 69, 36),
	(181, 18, 30),
	(181, 72, 22),
	(182, 76, 44),
	(182, 11, 28),
	(182, 45, 22),
	(183, 4, 48),
	(183, 35, 24),
	(183, 23, 36),
	(184, 69, 20),
	(184, 81, 34),
	(184, 51, 26),
	(185, 27, 43),
	(185, 6, 27),
	(185, 25, 34),
	(186, 62, 23),
	(186, 47, 49),
	(186, 32, 50),
	(187, 71, 22),
	(187, 66, 22),
	(187, 67, 42),
	(188, 83, 46),
	(188, 36, 48),
	(188, 73, 35),
	(189, 17, 33),
	(189, 55, 35),
	(189, 7, 46),
	(190, 55, 39),
	(190, 69, 21),
	(190, 84, 49),
	(191, 32, 30),
	(191, 55, 33),
	(191, 88, 27),
	(192, 82, 33),
	(192, 69, 43),
	(192, 52, 40),
	(193, 69, 36),
	(193, 8, 34),
	(193, 72, 28),
	(194, 66, 31),
	(194, 31, 29),
	(194, 44, 38),
	(195, 68, 32),
	(195, 74, 29),
	(195, 45, 27),
	(196, 38, 47),
	(196, 29, 22),
	(196, 6, 20),
	(197, 44, 28),
	(197, 31, 41),
	(197, 33, 20),
	(198, 64, 44),
	(198, 57, 22),
	(198, 31, 31),
	(199, 27, 37),
	(199, 52, 27),
	(199, 82, 33),
	(200, 87, 37),
	(200, 85, 31),
	(200, 49, 21),
	(201, 47, 30),
	(201, 15, 41),
	(201, 47, 42),
	(202, 16, 32),
	(202, 89, 23),
	(202, 47, 24),
	(203, 71, 43),
	(203, 14, 24),
	(203, 27, 26),
	(204, 5, 20),
	(204, 2, 34),
	(204, 30, 29),
	(205, 51, 27),
	(205, 38, 45),
	(205, 39, 23),
	(206, 39, 28),
	(206, 51, 24),
	(206, 57, 24),
	(207, 22, 24),
	(207, 1, 29),
	(207, 56, 41),
	(208, 8, 23),
	(208, 11, 29),
	(208, 3, 39),
	(209, 62, 41),
	(209, 42, 22),
	(209, 22, 48),
	(210, 49, 36),
	(210, 79, 50),
	(210, 39, 38),
	(211, 40, 48),
	(211, 82, 42),
	(211, 39, 42),
	(212, 65, 48),
	(212, 28, 25),
	(212, 65, 49),
	(213, 6, 30),
	(213, 84, 40),
	(213, 46, 42),
	(214, 72, 43),
	(214, 72, 23),
	(214, 22, 23),
	(215, 66, 33),
	(215, 72, 47),
	(215, 19, 50),
	(216, 59, 29),
	(216, 79, 50),
	(216, 80, 38),
	(217, 49, 37),
	(217, 81, 40),
	(217, 45, 34),
	(218, 20, 20),
	(218, 66, 49),
	(218, 21, 29),
	(219, 17, 24),
	(219, 61, 44),
	(219, 84, 45),
	(220, 35, 43),
	(220, 48, 25),
	(220, 86, 31),
	(221, 82, 45),
	(221, 2, 20),
	(221, 85, 34),
	(222, 76, 37),
	(222, 16, 20),
	(222, 74, 21),
	(223, 71, 40),
	(223, 89, 23),
	(223, 86, 40),
	(224, 35, 28),
	(224, 37, 20),
	(224, 4, 36),
	(225, 79, 28),
	(225, 51, 45),
	(225, 10, 21),
	(226, 3, 49),
	(226, 34, 35),
	(226, 82, 20),
	(227, 42, 22),
	(227, 50, 47),
	(227, 9, 50),
	(228, 26, 36),
	(228, 90, 32),
	(228, 76, 37),
	(229, 18, 25),
	(229, 44, 30),
	(229, 24, 31),
	(230, 60, 22),
	(230, 55, 40),
	(230, 10, 22);

INSERT INTO
	fornecedor (nome, contato, idProduto)
VALUES
	('Alfa Seven',              'alfa@contato',       1),
	('Altacoppo',               'alta@contato',       2),
	('Apti',                    'apti@contato',       3),
	('Aromax',                  'aromax@contato',     4),
	('Baptistella',             'baptis@contato',     5),
	('Basf',                    'basf@contato',       6),
	('Beraca',                  'baraca@contato',     7),
	('Bitcoin',                 'bitocoin@contato',   8),
	('Blue Ville',              'blue@contato',       9),
	('Broto Legal',             'broto@contato',     10),
	('Bunge Alimentos',         'bunge@contato',     11),
	('Cabot',                   'cabot@contato',     12),
	('Cachaça Estrada',         'cachaca@contato',   13),
	('Cerveja em Rodas',        'cerv@contato',      14),
	('Cereser',                 'cereser@contato',   15),
	('Chelkem',                 'chelkem@contato',   16),
	('Coana',                   'coana@contato',     17),
	('Condbras',                'condbras@contato',  18),
	('Contente',                'contente@contato',  19),
	('Corantec',                'corantec@contato',  20),
	('Cosmoquimica',            'cosmo@contato',     21),
	('Cp Kelco',                'cp@contato',        22),
	('Danubio',                 'danubio@contato',   23),
	('Doremus',                 'doremus@contato',   24),
	('Duas Rodas',              'duasrodas@contato', 25),
	('Dupont',                  'dupont@contato',    26),
	('Eco Life',                'eco@contato',       27),
	('Emulzint',                'emulzint@contato',  28),
	('Fego Alimentos',          'fego@contato',      29),
	('Fermentech',              'fermen@contato',    30),
	('Firace',                  'firece@contato',    31),
	('Gl Foods',                'gl@contato',        32),
	('Globalfood',              'global@contato',    33),
	('Granolab',                'grano@contato',     34),
	('Granotec',                'granotec@contato',  35),
	('Healthy Bread',           'healthy@contato',   36),
	('Hela',                    'hela@contato',      37),
	('Hexus Foods',             'hexus@contato',     38),
	('Huggies',                 'huggies@contato',   39),
	('Hvr',                     'hvr@contato',       40),
	('Hyg Flavors',             'hyg@contato',       41),
	('Icl Foods',               'icl@contato',       42),
	('Imcd Brasil',             'imcd@contato',      43),
	('Interfood',               'inter@contato',     44),
	('Kerry',                   'kerry@contato',     45),
	('Lariant',                 'lariant@contato',   46),
	('Leco',                    'leco@contato',      47),
	('Liotécnica',              'lio@contato',       48),
	('Luchebras',               'luchebras@contato', 49),
	('Líbano Brasileira',       'libano@contato',    50),
	('Mabel',                   'mabel@contato',     51),
	('Mapric',                  'mapric@contato',    52),
	('Mastersense',             'master@contato',    53),
	('Matprim',                 'matprim@contato',   54),
	('Mcassab',                 'mcassab@contato',   55),
	('Metachem',                'metachem@contato',  56),
	('Moinho do Mal',           'moinho@contato',    57),
	('N&b Ingredientes',        'nb@contato',        58),
	('Naturex',                 'naturex@contato',   59),
	('Nexo',                    'nexo@contato',      60),
	('Nilpan',                  'nilpan@contato',    61),
	('Nutramax',                'nutramax@contato',  62),
	('Nutrassim',               'nutrassim@contato', 63),
	('Nutrimilk',               'nutrimilk@contato', 64),
	('Pharmachemical',          'pharma@contato',    65),
	('Primavera',               'primavera@contato', 66),
	('Probiótica',              'probio@contato',    67),
	('Produquim',               'produquim@contato', 68),
	('Proteic',                 'proteic@contato',   69),
	('Prozyn',                  'prozyn@contato',    70),
	('Quantiq',                 'quantiq@contato',   71),
	('Quente Frio',             'qf@contato',        72),
	('Quiesper',                'quiesper@contato',  73),
	('Rjr',                     'rjr@contato',       74),
	('Royalpack',               'royal@contato',     75),
	('Ryu',                     'ryu@contato',       76),
	('Sabormax',                'sabormax@contato',  77),
	('Saporiti',                'sapo@contato',      78),
	('Satto',                   'satto@contato',     79),
	('Sensei',                  'sensei@contato',    80),
	('Sooro',                   'sooro@contato',     81),
	('Sublime',                 'sublime@contato',   82),
	('Sun Foods',               'sun@contato',       83),
	('Sunset',                  'sunset@contato',    84),
	('Sweetmix',                'sweet@contato',     85),
	('Tovani Benzaquen',        'tovani@contato',    86),
	('Trio Alimentos',          'trio@contato',      87),
	('Vigor',                   'vigor@contato',     88),
	('Vito Corleone',           'corleone@contato',  89),
	('Volta Cesta',             'volta@contato',     90);

INSERT INTO
	requisicao (idFornecedor, qtd, feito, previsto, entregue)
VALUES
	( 1, 60, '2021-10-28', '2021-11-09', '2021-11-01'),
	( 2, 70, '2021-11-02', '2021-12-02', '2021-11-25'),
	( 3, 80, '2021-10-26', '2021-11-19', '2021-11-18'),
	( 4, 80, '2021-12-04', '2021-12-21', '2021-12-13'),
	( 5, 50, '2021-10-29', '2021-11-27', '2021-10-31'),
	( 6, 80, '2021-10-25', '2021-11-05', '2021-11-03'),
	( 7, 90, '2021-12-16', '2021-12-20', '2022-01-09'),
	( 8, 80, '2021-11-14', '2021-11-15', '2021-11-18'),
	( 9, 70, '2021-11-25', '2021-12-05', '2021-12-19'),
	(10, 60, '2021-11-16', '2021-11-28', '2021-12-10'),
	(11, 60, '2021-12-05', '2021-12-26', '2021-12-28'),
	(12, 90, '2021-12-15', '2021-12-22', '2021-12-17'),
	(13, 90, '2021-10-26', '2021-11-21', '2021-11-24'),
	(14, 70, '2021-11-10', '2021-12-07', '2021-12-05'),
	(15, 80, '2021-11-29', '2021-12-20', '2021-12-21'),
	(16, 80, '2021-11-19', '2021-11-27', '2021-11-30'),
	(17, 70, '2021-12-05', '2021-12-13', '2022-01-01'),
	(18, 80, '2021-11-21', '2021-12-22', '2021-12-02'),
	(19, 80, '2021-11-08', '2021-11-21', '2021-11-10'),
	(20, 70, '2021-11-24', '2021-12-03', '2021-11-29'),
	(21, 50, '2021-12-10', '2022-01-04', '2022-01-03'),
	(22, 60, '2021-10-26', '2021-11-16', '2021-10-30'),
	(23, 60, '2021-10-27', '2021-11-06', '2021-11-17'),
	(24, 70, '2021-11-30', '2021-12-08', '2021-12-11'),
	(25, 90, '2021-12-08', '2021-12-29', '2021-12-12'),
	(26, 70, '2021-10-28', '2021-10-30', '2021-11-03'),
	(27, 80, '2021-11-20', '2021-12-19', '2021-12-21'),
	(28, 80, '2021-11-26', '2021-12-19', '2021-12-19'),
	(29, 60, '2021-12-09', '2021-12-17', '2022-01-04'),
	(30, 90, '2021-12-12', '2021-12-29', '2022-01-02'),
	(31, 80, '2021-11-17', '2021-12-09', '2021-12-10'),
	(32, 50, '2021-10-26', '2021-11-15', '2021-11-18'),
	(33, 60, '2021-11-25', '2021-12-21', '2021-11-29'),
	(34, 50, '2021-12-21', '2022-01-20', '2021-12-28'),
	(35, 80, '2021-12-10', '2021-12-28', '2021-12-20'),
	(36, 50, '2021-11-13', '2021-11-24', '2021-12-07'),
	(37, 60, '2021-10-30', '2021-11-28', '2021-11-28'),
	(38, 50, '2021-11-07', '2021-11-26', '2021-12-08'),
	(39, 60, '2021-12-09', '2021-12-17', '2021-12-17'),
	(40, 70, '2021-11-13', '2021-11-21', '2021-11-20'),
	(41, 60, '2021-12-09', '2022-01-04', '2022-01-07'),
	(42, 80, '2021-11-14', '2021-11-16', '2021-11-26'),
	(43, 70, '2021-12-22', '2021-12-29', '2022-01-19'),
	(44, 50, '2021-11-28', '2021-12-23', '2021-12-24'),
	(45, 60, '2021-12-16', '2021-12-24', '2021-12-25'),
	(46, 50, '2021-10-27', '2021-11-03', '2021-11-27'),
	(47, 50, '2021-12-22', '2022-01-12', '2021-12-23'),
	(48, 90, '2021-10-24', '2021-11-04', '2021-11-04'),
	(49, 50, '2021-12-12', '2021-12-27', '2022-01-09'),
	(50, 80, '2021-11-30', '2021-12-11', '2021-12-09'),
	(51, 50, '2021-11-04', '2021-11-10', '2021-12-02'),
	(52, 80, '2021-12-18', '2022-01-09', '2022-01-09'),
	(53, 90, '2021-12-22', '2022-01-09', '2021-12-27'),
	(54, 70, '2021-12-19', '2022-01-02', '2022-01-15'),
	(55, 90, '2021-11-01', '2021-11-14', '2021-11-09'),
	(56, 50, '2021-12-18', '2022-01-06', '2022-01-09'),
	(57, 70, '2021-12-15', '2021-12-29', '2021-12-21'),
	(58, 60, '2021-12-01', '2021-12-31', '2021-12-27'),
	(59, 50, '2021-12-13', '2021-12-17', '2021-12-14'),
	(60, 60, '2021-12-21', '2022-01-15', '2021-12-31'),
	(61, 90, '2021-10-30', '2021-10-31', '2021-11-29'),
	(62, 90, '2021-12-08', '2021-12-24', '2021-12-15'),
	(63, 80, '2021-11-17', '2021-12-02', '2021-11-25'),
	(64, 70, '2021-11-14', '2021-11-29', '2021-11-25'),
	(65, 70, '2021-11-21', '2021-12-04', '2021-11-26'),
	(66, 90, '2021-11-16', '2021-12-05', '2021-11-18'),
	(67, 90, '2021-11-12', '2021-11-14', '2021-12-07'),
	(68, 80, '2021-12-21', '2022-01-17', '2022-01-20'),
	(69, 70, '2021-11-20', '2021-11-25', '2021-12-13'),
	(70, 80, '2021-10-31', '2021-11-10', '2021-11-05'),
	(71, 80, '2021-11-18', '2021-12-04', '2021-12-19'),
	(72, 50, '2021-12-18', '2022-01-08', '2022-01-17'),
	(73, 90, '2021-11-20', '2021-12-05', '2021-12-17'),
	(74, 90, '2021-11-29', '2021-12-21', '2021-12-04'),
	(75, 50, '2021-11-26', '2021-12-09', '2021-12-19'),
	(76, 80, '2021-12-21', '2021-12-26', '2021-12-26'),
	(77, 90, '2021-10-31', '2021-11-10', '2021-11-10'),
	(78, 80, '2021-12-21', '2022-01-07', '2022-01-16'),
	(79, 60, '2021-11-29', '2021-12-10', '2021-12-08'),
	(80, 90, '2021-12-20', '2022-01-06', '2022-01-10'),
	(81, 50, '2021-12-12', '2022-01-05', '2022-01-03'),
	(82, 90, '2021-11-07', '2021-11-14', '2021-11-11'),
	(83, 90, '2021-11-05', '2021-12-03', '2021-12-06'),
	(84, 80, '2021-11-14', '2021-12-06', '2021-12-15'),
	(85, 70, '2021-12-01', '2021-12-28', '2021-12-22'),
	(86, 50, '2021-11-26', '2021-11-27', '2021-12-02'),
	(87, 80, '2021-11-11', '2021-12-09', '2021-11-20'),
	(88, 80, '2021-12-14', '2021-12-27', '2022-01-04'),
	(89, 50, '2021-11-29', '2021-12-04', '2021-12-04'),
	(90, 70, '2021-11-21', '2021-12-15', '2021-11-25'),
		( 1, 70, '2021-11-28', '2021-12-23', NULL),
	( 2, 80, '2021-11-18', '2021-11-30', NULL),
	( 3, 70, '2021-12-01', '2021-12-16', NULL),
	( 4, 80, '2021-11-30', '2021-12-22', NULL),
	( 5, 70, '2021-12-11', '2022-01-10', NULL),
	( 6, 90, '2021-11-01', '2021-11-09', NULL),
	( 7, 60, '2021-11-18', '2021-12-04', NULL),
	( 8, 70, '2021-10-27', '2021-11-03', NULL),
	( 9, 70, '2021-11-18', '2021-11-25', NULL),
	(10, 50, '2021-12-14', '2021-12-17', NULL),
	(11, 70, '2021-12-17', '2021-12-23', NULL),
	(12, 60, '2021-12-08', '2022-01-07', NULL),
	(13, 90, '2021-10-25', '2021-11-21', NULL),
	(14, 60, '2021-10-24', '2021-10-30', NULL),
	(15, 90, '2021-11-16', '2021-12-13', NULL),
	(16, 70, '2021-10-25', '2021-11-08', NULL),
	(17, 50, '2021-11-28', '2021-12-15', NULL),
	(18, 80, '2021-11-05', '2021-11-10', NULL),
	(19, 70, '2021-11-06', '2021-11-15', NULL),
	(20, 50, '2021-10-24', '2021-11-16', NULL),
	(21, 50, '2021-11-01', '2021-11-23', NULL),
	(22, 90, '2021-12-05', '2021-12-27', NULL),
	(23, 90, '2021-12-04', '2021-12-27', NULL),
	(24, 80, '2021-10-29', '2021-11-25', NULL),
	(25, 60, '2021-12-01', '2021-12-31', NULL),
	(26, 70, '2021-12-03', '2021-12-08', NULL),
	(27, 90, '2021-12-01', '2021-12-15', NULL),
	(28, 50, '2021-12-08', '2022-01-07', NULL),
	(29, 50, '2021-11-09', '2021-11-19', NULL),
	(30, 80, '2021-12-04', '2021-12-20', NULL),
	(31, 90, '2021-12-16', '2022-01-01', NULL),
	(32, 70, '2021-11-08', '2021-11-15', NULL),
	(33, 50, '2021-12-06', '2022-01-02', NULL),
	(34, 60, '2021-12-02', '2021-12-08', NULL),
	(35, 50, '2021-12-01', '2021-12-29', NULL),
	(36, 70, '2021-11-28', '2021-12-16', NULL),
	(37, 70, '2021-12-15', '2021-12-30', NULL),
	(38, 50, '2021-12-04', '2021-12-11', NULL),
	(39, 80, '2021-12-01', '2021-12-12', NULL),
	(40, 60, '2021-12-18', '2022-01-08', NULL),
	(41, 90, '2021-11-09', '2021-11-29', NULL),
	(42, 90, '2021-12-15', '2021-12-18', NULL),
	(43, 60, '2021-12-07', '2021-12-11', NULL),
	(44, 80, '2021-10-27', '2021-11-19', NULL),
	(45, 70, '2021-11-13', '2021-11-27', NULL),
	(46, 80, '2021-11-17', '2021-11-27', NULL),
	(47, 50, '2021-12-15', '2022-01-02', NULL),
	(48, 80, '2021-11-19', '2021-11-20', NULL),
	(49, 90, '2021-12-09', '2021-12-26', NULL),
	(50, 60, '2021-11-03', '2021-12-03', NULL),
	(51, 80, '2021-11-28', '2021-12-12', NULL),
	(52, 50, '2021-12-15', '2022-01-09', NULL),
	(53, 70, '2021-12-21', '2022-01-01', NULL),
	(54, 70, '2021-11-01', '2021-11-11', NULL),
	(55, 60, '2021-12-17', '2022-01-04', NULL),
	(56, 60, '2021-12-16', '2022-01-05', NULL),
	(57, 80, '2021-12-08', '2021-12-21', NULL),
	(58, 50, '2021-12-11', '2021-12-13', NULL),
	(59, 60, '2021-12-04', '2021-12-20', NULL),
	(60, 50, '2021-12-08', '2021-12-21', NULL),
	(61, 70, '2021-12-01', '2021-12-04', NULL),
	(62, 80, '2021-12-01', '2021-12-12', NULL),
	(63, 60, '2021-12-15', '2022-01-09', NULL),
	(64, 70, '2021-12-22', '2022-01-15', NULL),
	(65, 70, '2021-12-03', '2022-01-02', NULL),
	(66, 90, '2021-10-30', '2021-11-11', NULL),
	(67, 50, '2021-11-30', '2021-12-02', NULL),
	(68, 70, '2021-11-07', '2021-11-17', NULL),
	(69, 70, '2021-12-04', '2021-12-23', NULL),
	(70, 80, '2021-10-28', '2021-11-28', NULL),
	(71, 60, '2021-11-30', '2021-12-05', NULL),
	(72, 80, '2021-11-12', '2021-11-21', NULL),
	(73, 90, '2021-12-04', '2022-01-03', NULL),
	(74, 90, '2021-12-02', '2021-12-23', NULL),
	(75, 60, '2021-11-17', '2021-12-06', NULL),
	(76, 60, '2021-11-25', '2021-12-03', NULL),
	(77, 70, '2021-12-11', '2022-01-03', NULL),
	(78, 80, '2021-11-07', '2021-11-20', NULL),
	(79, 60, '2021-11-20', '2021-12-12', NULL),
	(80, 90, '2021-12-13', '2022-01-01', NULL),
	(81, 70, '2021-12-14', '2022-01-03', NULL),
	(82, 60, '2021-12-09', '2021-12-20', NULL),
	(83, 90, '2021-12-13', '2022-01-09', NULL),
	(84, 60, '2021-12-10', '2021-12-31', NULL),
	(85, 60, '2021-12-18', '2021-12-28', NULL),
	(86, 50, '2021-12-08', '2021-12-13', NULL),
	(87, 90, '2021-10-30', '2021-11-30', NULL),
	(88, 90, '2021-11-04', '2021-12-04', NULL),
	(89, 70, '2021-12-14', '2022-01-06', NULL),
	(90, 50, '2021-12-11', '2021-12-12', NULL);
