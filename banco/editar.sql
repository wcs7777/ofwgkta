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
