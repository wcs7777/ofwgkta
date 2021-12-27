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
