#include "wstatusquantidade.h"
#include "ui_wstatusquantidade.h"
#include "conectarbancodados.h"
#include "modeloproxy.h"
#include "parametros.h"

WStatusQuantidade::WStatusQuantidade(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WStatusQuantidade),
	m_menu(menu)
{
	ui->setupUi(this);

	const QVariant esquerda(Qt::AlignLeft | Qt::AlignVCenter);
	const QVariant direita(Qt::AlignRight | Qt::AlignVCenter);
	QHash<QString, QVariant> condicaoCor;
	condicaoCor.insert("Seguro", QVariant(parametros::primeiraCor));
	condicaoCor.insert("Baixo", QVariant(parametros::segundaCor));
	condicaoCor.insert("Alerta", QVariant(parametros::terceiraCor));

	ui->tabela->setModel(
		new ModeloProxy(
			new ModeloCustomizavel(
				QSqlQuery(
					QString("CALL RelatorioQuantidade(%1)").arg(parametros::periodo),
					conectarBancoDados()
				),
				this,
				QList<QVariant>()
					<< esquerda
					<< direita
					<< direita
					<< direita
					<< direita,
				CampoCondicaoCor(4, condicaoCor)
			),
			this
		)
	);
	tamanhoColunasTabela();
}

WStatusQuantidade::~WStatusQuantidade()
{
	delete ui;
}

void WStatusQuantidade::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WStatusQuantidade::showEvent(QShowEvent*)
{
	ui->tabela->model()->sort(4); // Ordenar pelo Status
}

void WStatusQuantidade::tamanhoColunasTabela()
{
	ui->tabela->setColumnWidth(0, 370);
	ui->tabela->setColumnWidth(1, 95);
	ui->tabela->setColumnWidth(2, 95);
	ui->tabela->setColumnWidth(3, 95);
	ui->tabela->setColumnWidth(4, 70);
}
