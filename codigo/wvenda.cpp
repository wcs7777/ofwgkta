#include "wvenda.h"
#include "ui_wvenda.h"
#include "conectarbancodados.h"
#include "folhaestilo.h"
#include <QSqlQuery>
#include <QVariant>

WVenda::WVenda(QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WVenda)
{
	ui->setupUi(this);
	ui->tabela->setStyleSheet(folhaEstiloVenda());
	buttonGroup = new QButtonGroup(this);
	connect(
		buttonGroup,
		SIGNAL(buttonClicked(int)),
		this,
		SLOT(removerItem(int))
	);
	esvaziar();
	tamanhoColunasTabela();
}

WVenda::~WVenda()
{
	delete ui;
}

void WVenda::adicionarItem()
{
	atualizarUltimo();
	atualizarTotal();

	QMap<QString, int> nomeId;
	QMap<int, int> idQuantidade;

	for (int i = 0; i < registros.size(); i++)
	{
		int quantiaDisponivel = registros[i].value(2).toInt();
		int idAtual = registros[i].value(1).toInt();
		bool possui = false;

		for (int j = 0; !possui && j < pedido.size(); j++)
		{
			if (pedido[j]->idProduto() == idAtual)
			{
				quantiaDisponivel -= pedido[j]->quantidade();
				possui = true;
			}
		}

		if (quantiaDisponivel > 0)
		{
			nomeId.insert(registros[i].value(0).toString(), idAtual);
			idQuantidade.insert(idAtual, quantiaDisponivel);
		}
	}

	pedido.append(new ItemPedido(ui->tabela, nomeId, idQuantidade));
	connect(
		pedido.last()->carrinho(),
		SIGNAL(clicked()),
		this,
		SLOT(adicionarItem())
	);
	int atual = (pedido.size() - 2 >= 0)? pedido.size() - 2 : 0;
	ui->tabela->setCurrentCell(atual, 0);
}

void WVenda::removerItem(int row, bool checar)
{
	int atual = ui->tabela->currentRow();
	bool remover = (checar)? row != atual : true;

	if (remover)
	{
		buttonGroup->removeButton(pedido[row]->carrinho());

		for (int i = row + 1; i < ui->tabela->rowCount(); i++)
		{
			buttonGroup->removeButton(pedido[i]->carrinho());
			buttonGroup->addButton(pedido[i]->carrinho(), i - 1);
		}

		ui->tabela->removeRow(row);
		pedido.removeAt(row);

		if (pedido.size() - 1 >= 0 && !pedido.last()->valido())
		{
			ui->tabela->removeRow(pedido.size() - 1);
			pedido.removeLast();
			adicionarItem();
		}
	}

	int ultimo = (pedido.size() - 1 >= 0)? pedido.size() - 1 : 0;
	if (atual != ultimo) ui->tabela->setCurrentCell(ultimo, 0);
}

void WVenda::finalizar()
{
	if (pedido.size() > 0 && pedido.first()->valido())
	{
		QSqlQuery q("CALL AdicionarPedido", conectarBancoDados());
		q.next();
		int idPedido = q.value(0).toInt();

		for (int i = 0; i < pedido.size(); i++)
		{
			q.clear();
			q.exec(
				QString("CALL AdicionarProdutosAoPedido(%1, %2, %3)")
					.arg(idPedido)
					.arg(pedido[i]->idProduto())
					.arg(pedido[i]->quantidade())
			);
		}
	}
}

void WVenda::esvaziar()
{
	pedido.clear();
	registros.clear();
	while (ui->tabela->rowCount() > 0) ui->tabela->removeRow(0);

	QSqlQuery q("CALL ProdutosParaVenda", conectarBancoDados());
	q.setForwardOnly(true);
	while (q.next()) registros.append(q.record());
	adicionarItem();
}

void WVenda::atualizarUltimo()
{
	int ultimo = pedido.size() - 1;

	if (ultimo >= 0)
	{
		disconnect(
			pedido.last()->carrinho(),
			SIGNAL(clicked()),
			this,
			SLOT(adicionarItem())
		);
		buttonGroup->addButton(pedido.last()->carrinho(), ultimo);
		bool repetido = false;

		if (pedido.last()->valido())
			for (int i = 0; !repetido && i < ultimo; i++)
				if (pedido[i]->idProduto() == pedido.last()->idProduto())
				{
					pedido[i]->adicionarProdutos(pedido.last()->quantidade());
					repetido = true;
				}

		if (repetido || !pedido.last()->valido()) removerItem(ultimo, false);
	}
}

void WVenda::atualizarTotal()
{
	double total = 0.0;
	for (int i = 0; i < pedido.size(); i++) total += pedido[i]->precoTotal();
	ui->outTotal->setValue(total);
}

void WVenda::tamanhoColunasTabela()
{
	ui->tabela->setColumnWidth(0, 308);
	ui->tabela->setColumnWidth(1, 105);
	ui->tabela->setColumnWidth(2, 95);
	ui->tabela->setColumnWidth(3, 125);
	ui->tabela->setColumnWidth(4, 100);
}
