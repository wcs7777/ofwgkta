#include "westoque.h"
#include "ui_westoque.h"
#include "conectarbancodados.h"
#include "produto.h"
#include "westoquenovo.h"
#include "wrequisicao.h"
#include "wrequisicaoentrada.h"

WEstoque::WEstoque(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WEstoque),
	m_menu(menu)
{
	ui->setupUi(this);

	const QVariant esquerda(Qt::AlignLeft | Qt::AlignVCenter);
	const QVariant direita(Qt::AlignRight | Qt::AlignVCenter);

	modelo = new ModeloProxy(
		new ModeloCustomizavel(
			QSqlQuery("CALL Produtos", conectarBancoDados()),
			this,
			QList<QVariant>() << direita << esquerda << direita << direita
		),
		1,    // Filtrar pelo nome do produto
		this
	);
	ui->tabela->setModel(modelo);
	connect(
		ui->inPesquisa,
		SIGNAL(textChanged(QString)),
		modelo,
		SLOT(setFilterFixedString(QString))
	);
	tamanhoColunasTabela();
}

WEstoque::~WEstoque()
{
	delete ui;
}

void WEstoque::entrada()
{
	m_menu->addWidget(new WRequisicao(m_menu, this));
}

void WEstoque::novo()
{
	m_menu->addWidget(new WEstoqueNovo(m_menu, this));
}

void WEstoque::editar()
{
	int i = ui->tabela->currentIndex().row();

	if (i >= 0)
	{
		m_menu->addWidget(
			new WEstoqueNovo(
				new Produto(
					modelo->valor(i, 0).toInt(),    // id
					modelo->valor(i, 1).toString(), // nome
					modelo->valor(i, 3)             // preço
						.toString()
						.replace(',', '.')
						.toDouble()
				),
				m_menu,
				this
			)
		);
	}
}

void WEstoque::proximaTela()
{
	m_menu->setCurrentIndex(m_menu->currentIndex() + 1);
}

void WEstoque::showEvent(QShowEvent*)
{
	modelo->source()->atualizar();
	ui->tabela->model()->sort(1); // ordenar pelo nome
	ui->tabela->setColumnHidden(0, true);
}

void WEstoque::tamanhoColunasTabela()
{
	ui->tabela->setColumnWidth(1, 390);
	ui->tabela->setColumnWidth(2, 95);
	ui->tabela->setColumnWidth(3, 105);

}
