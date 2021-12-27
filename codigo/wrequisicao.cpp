#include "wrequisicao.h"
#include "ui_wrequisicao.h"
#include "conectarbancodados.h"
#include "lote.h"
#include "produto.h"
#include "wrequisicaoentrada.h"

WRequisicao::WRequisicao(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WRequisicao),
	m_menu(menu)
{
	ui->setupUi(this);

	const QVariant esquerda(Qt::AlignLeft | Qt::AlignVCenter);
	const QVariant direita(Qt::AlignRight | Qt::AlignVCenter);

	modelo = new ModeloProxy(
		new ModeloCustomizavel(
			QSqlQuery("CALL Requisicoes", conectarBancoDados()),
			this,
			QList<QVariant>() << esquerda << esquerda << direita << direita
		),
		1,   // Filtrar pelo nome do produto
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

WRequisicao::~WRequisicao()
{
	delete ui;
}

void WRequisicao::requisicao()
{
	int i = ui->tabela->currentIndex().row();

	if (i >= 0)
	{
		if (produtos.isEmpty()) produtos = Produto::nomeIdProdutos();
		m_menu->addWidget(
			new WRequisicaoEntrada(
				new Lote(
					produtos,
					modelo->valor(i, 0).toInt(),    // id requisição
					modelo->valor(i, 1).toString(), // nome produto
					modelo->valor(i, 2).toInt()     // quantidade
				),
				m_menu,
				this
			)
		);
	}
}

void WRequisicao::avulso()
{
	if (produtos.isEmpty()) produtos = Produto::nomeIdProdutos();
	m_menu->addWidget(new WRequisicaoEntrada(produtos, m_menu, this));
}

void WRequisicao::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WRequisicao::proximaTela()
{
	m_menu->setCurrentIndex(m_menu->currentIndex() + 1);
}

void WRequisicao::showEvent(QShowEvent*)
{
	modelo->source()->atualizar();
	ui->tabela->model()->sort(3); // ordenar pela previsão
}

void WRequisicao::tamanhoColunasTabela()
{
	ui->tabela->setColumnWidth(0, 95);
	ui->tabela->setColumnWidth(1, 310);
	ui->tabela->setColumnWidth(2, 95);
	ui->tabela->setColumnWidth(3, 90);
}
