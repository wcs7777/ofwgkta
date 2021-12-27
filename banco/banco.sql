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
