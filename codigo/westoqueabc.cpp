#include "westoqueabc.h"
#include "ui_westoqueabc.h"
#include "conectarbancodados.h"
#include "modeloproxy.h"
#include "parametros.h"

WEstoqueAbc::WEstoqueAbc(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WEstoqueAbc),
	m_menu(menu)
{
	ui->setupUi(this);

	const QVariant esquerda(Qt::AlignLeft | Qt::AlignVCenter);
	const QVariant direita(Qt::AlignRight | Qt::AlignVCenter);
	QHash<QString, QVariant> condicaoCor;
	condicaoCor.insert("A", QVariant(parametros::primeiraCor));
	condicaoCor.insert("B", QVariant(parametros::segundaCor));
	condicaoCor.insert("C", QVariant(parametros::terceiraCor));

	ui->tabela->setModel(
		new ModeloProxy(
			new ModeloCustomizavel(
				QSqlQuery("CALL EstoqueAbc", conectarBancoDados()),
				this,
				QList<QVariant>() << esquerda << direita << direita << direita,
				CampoCondicaoCor(3, condicaoCor)
			),
			this
		)
	);
	tamanhoColunasTabela();
}

WEstoqueAbc::~WEstoqueAbc()
{
	delete ui;
}

void WEstoqueAbc::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WEstoqueAbc::showEvent(QShowEvent*)
{
	ui->tabela->model()->sort(3); // Ordenar pela Categoria
}

void WEstoqueAbc::tamanhoColunasTabela()
{
	ui->tabela->setColumnWidth(0, 430);
	ui->tabela->setColumnWidth(1, 105);
	ui->tabela->setColumnWidth(2, 95);
	ui->tabela->setColumnWidth(3, 95);
}
