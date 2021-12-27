#include "itempedido.h"
#include "completer.h"
#include "conectarbancodados.h"
#include <QSqlQuery>
#include <QVariant>

ItemPedido::ItemPedido(
	QTableWidget *tabela,
	const QMap<QString, int> &produtos_nomeId,
	const QMap<int, int> &produtos_idQuantidade
) :
	QObject(tabela),
	iconeAdicionar(":/icones/adicionar.png"),
	iconeRemover(":/icones/remover.png"),
	m_produtos_nomeId(produtos_nomeId),
	m_produtos_idQuantidade(produtos_idQuantidade),
	inProduto(new QLineEdit(tabela)),
	outPreco(new QDoubleSpinBox(tabela)),
	inQuantidade(new QSpinBox(tabela)),
	outTotal(new QDoubleSpinBox(tabela)),
	pbCarrinho(new QPushButton(tabela))
{
	inserirLinha(tabela);
	alinhamentos();
	inProduto->setCompleter(new Completer(m_produtos_nomeId.keys(), inProduto));
	pbCarrinho->setCursor(QCursor(Qt::PointingHandCursor));
	pbCarrinho->setIcon(iconeAdicionar);
	pbCarrinho->setAutoDefault(true);
	uiInicial();
	connections();
}

void ItemPedido::adicionarProdutos(int quantidade)
{
	if (0 < quantidade && quantidade <= quantidade + inQuantidade->maximum())
		inQuantidade->setValue(ItemPedido::quantidade() + quantidade);
}

void ItemPedido::checarProduto(QString produto)
{
	if (!produto.isEmpty())
		inProduto->setText(produto);

	int id = idProduto();

	if (id != 0)
	{
		QSqlQuery q(
			QString("CALL PrecoProduto(%1)").arg(id),
			conectarBancoDados()
		);
		q.next();
		outPreco->setValue(q.value(0).toDouble());
		outTotal->setValue(outPreco->value());
		inQuantidade->setMinimum(1);
		inQuantidade->setMaximum(m_produtos_idQuantidade[id]);
		inQuantidade->setEnabled(true);
		inQuantidade->setFocus();
	}
	else
		uiInicial();
}

void ItemPedido::atualizarTotal(int quantidade)
{
	outTotal->setValue(outPreco->value() * quantidade);
}

void ItemPedido::desativar()
{
	inProduto->setEnabled(false);
	inQuantidade->setEnabled(false);
	pbCarrinho->setIcon(iconeRemover);
}

void ItemPedido::alinhamentos()
{
	outPreco->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
	outTotal->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
	inQuantidade->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
}

void ItemPedido::inserirLinha(QTableWidget *tabela)
{
	int row = tabela->rowCount();
	tabela->insertRow(row);
	tabela->setCellWidget(row, 0, inProduto);
	tabela->setCellWidget(row, 1, outPreco);
	tabela->setCellWidget(row, 2, inQuantidade);
	tabela->setCellWidget(row, 3, outTotal);
	tabela->setCellWidget(row, 4, pbCarrinho);
}

void ItemPedido::uiInicial()
{
	inQuantidade->setMaximum(0);
	inQuantidade->setEnabled(false);
	outPreco->setEnabled(false);
	outPreco->setMaximum(9999999.99);
	outTotal->setEnabled(false);
	outTotal->setMaximum(99999999999999.99);
	inProduto->setFocus();
}

void ItemPedido::connections()
{
	connect(
		inProduto,
		SIGNAL(editingFinished()),
		this,
		SLOT(checarProduto())
	);
	connect(
		inProduto->completer(),
		SIGNAL(activated(QString)),
		this,
		SLOT(checarProduto(QString))
	);
	connect(
		inQuantidade,
		SIGNAL(valueChanged(int)),
		this,
		SLOT(atualizarTotal(int))
	);
	connect(
		inQuantidade,
		SIGNAL(editingFinished()),
		pbCarrinho,
		SLOT(setFocus())
	);
	connect(pbCarrinho, SIGNAL(clicked()), this, SLOT(desativar()));
}
