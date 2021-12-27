#include "wstatusvalidade.h"
#include "ui_wstatusvalidade.h"
#include "conectarbancodados.h"
#include "modeloproxy.h"
#include "parametros.h"

WStatusValidade::WStatusValidade(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WStatusValidade),
	m_menu(menu)
{
	ui->setupUi(this);

	const QVariant esquerda(Qt::AlignLeft | Qt::AlignVCenter);
	const QVariant direita(Qt::AlignRight | Qt::AlignVCenter);
	QHash<QString, QVariant> condicaoCor;
	condicaoCor.insert("Normal", QVariant(parametros::primeiraCor));
	condicaoCor.insert("Perto", QVariant(parametros::segundaCor));
	condicaoCor.insert("Vencido", QVariant(parametros::terceiraCor));

	ui->tabela->setModel(
		new ModeloProxy(
			new ModeloCustomizavel(
				QSqlQuery(
					QString("CALL RelatorioValidade(%1)").arg(parametros::tolerancia),
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

WStatusValidade::~WStatusValidade()
{
	delete ui;
}

void WStatusValidade::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WStatusValidade::showEvent(QShowEvent*)
{
	ui->tabela->model()->sort(4, Qt::DescendingOrder); // Ordenar pelo Status
}

void WStatusValidade::tamanhoColunasTabela()
{
	ui->tabela->setColumnWidth(0, 370);
	ui->tabela->setColumnWidth(1, 95);
	ui->tabela->setColumnWidth(2, 95);
	ui->tabela->setColumnWidth(3, 95);
	ui->tabela->setColumnWidth(4, 70);
}
