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
