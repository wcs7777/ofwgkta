#include "wfornecedor.h"
#include "ui_wfornecedor.h"
#include "conectarbancodados.h"
#include "produto.h"
#include "requisicao.h"
#include "wfornecedornovo.h"
#include "wfornecedorrequisitar.h"

WFornecedor::WFornecedor(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WFornecedor),
	m_menu(menu)
{
	ui->setupUi(this);

	const QVariant esquerda(Qt::AlignLeft | Qt::AlignVCenter);
	const QVariant direita(Qt::AlignRight | Qt::AlignVCenter);

	modelo = new ModeloProxy(
		new ModeloCustomizavel(
			QSqlQuery("CALL Fornecedores", conectarBancoDados()),
			this,
			QList<QVariant>() << direita << esquerda << esquerda << esquerda
		),
		3,   // Filtrar pelo produto
		this
	);
	ui->tabela->setModel(modelo);
	ui->tabela->setColumnHidden(0, true);
	connect(
		ui->inPesquisa,
		SIGNAL(textChanged(QString)),
		modelo,
		SLOT(setFilterFixedString(QString))
	);
	tamanhoColunasTabela();
}

WFornecedor::~WFornecedor()
{
	delete ui;
}

void WFornecedor::requisitar()
{
	int i = ui->tabela->currentIndex().row();

	if (i >= 0)
	{
		if (produtos.isEmpty()) produtos = Produto::nomeIdProdutos();
		m_menu->addWidget(
			new WFornecedorRequisitar(
				new Requisicao(
					new Fornecedor(
						produtos,
						modelo->valor(i, 0).toInt(),    // id fornecedor
						modelo->valor(i, 1).toString(), // nome fornecedor
						modelo->valor(i, 2).toString(), // contato fornecedor
						modelo->valor(i, 3).toString()  // nome produto
					)
				),
				m_menu,
				this
			)
		);
	}
}

void WFornecedor::novo()
{
	if (produtos.isEmpty()) produtos = Produto::nomeIdProdutos();
	m_menu->addWidget(new WFornecedorNovo(produtos, m_menu, this));
}

void WFornecedor::editar()
{
	int i = ui->tabela->currentIndex().row();

	if (i >= 0)
	{
		if (produtos.isEmpty()) produtos = Produto::nomeIdProdutos();
		m_menu->addWidget(
			new WFornecedorNovo(
				new Fornecedor(
					produtos,
					modelo->valor(i, 0).toInt(),    // id fornecedor
					modelo->valor(i, 1).toString(), // nome fornecedor
					modelo->valor(i, 2).toString(), // contato fornecedor
					modelo->valor(i, 3).toString()  // nome produto
				),
				m_menu,
				this
			)
		);
	}
}

void WFornecedor::proximaTela()
{
	m_menu->setCurrentIndex(m_menu->currentIndex() + 1);
}

void WFornecedor::showEvent(QShowEvent*)
{
	modelo->source()->atualizar();
	ui->tabela->model()->sort(1); // ordenar pelo nome
	ui->tabela->setColumnHidden(0, true);
}

void WFornecedor::tamanhoColunasTabela()
{
	ui->tabela->setColumnWidth(1, 215);
	ui->tabela->setColumnWidth(2, 215);
	ui->tabela->setColumnWidth(3, 160);
}
