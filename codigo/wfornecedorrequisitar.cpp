#include "wfornecedorrequisitar.h"
#include "ui_wfornecedorrequisitar.h"
#include "conectarbancodados.h"
#include <QSqlQuery>

WFornecedorRequisitar::WFornecedorRequisitar(
	Requisicao *requisicao,
	QStackedWidget *menu,
	QWidget *parent
) :
	QWidget(parent),
	ui(new Ui::WFornecedorRequisitar),
	m_requisicao(requisicao),
	m_menu(menu)
{
	ui->setupUi(this);
	uiInicial();
	connect(
		m_requisicao,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
}

WFornecedorRequisitar::~WFornecedorRequisitar()
{
	delete m_requisicao;
	delete ui;
}

void WFornecedorRequisitar::adicionar()
{
	QSqlQuery(
		QString("CALL AdicionarRequisicao(%1, %2, '%3')")
			.arg(m_requisicao->fornecedor()->id())
			.arg(m_requisicao->quantidade())
			.arg(m_requisicao->previsto().toString("yyyy-M-d")),
		conectarBancoDados()
	);
}

void WFornecedorRequisitar::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WFornecedorRequisitar::checarQuantidade()
{
	int quantidade = ui->inQuantidade->value();

	if (quantidade != m_requisicao->quantidade())
	{
		if (m_requisicao->quantidadeValida(quantidade))
		{
			ui->errQuantidade->clear();
			ui->inQuantidade->nextInFocusChain()->setFocus();
		}
		else
			ui->errQuantidade->setText(m_requisicao->ultimoErro());
	}
}

void WFornecedorRequisitar::checarPrevisao()
{
	QDate previsto = ui->inPrevisao->date();

	if (previsto != m_requisicao->previsto())
	{
		if (m_requisicao->previsaoValida(previsto))
		{
			ui->errPrevisao->clear();
			ui->inPrevisao->nextInFocusChain()->setFocus();
		}
		else
			ui->errPrevisao->setText(m_requisicao->ultimoErro());
	}
}

void WFornecedorRequisitar::uiInicial()
{
	ui->outFornecedor->setText(m_requisicao->fornecedor()->nome());
	ui->outFornecedor->setEnabled(false);
	ui->outProduto->setText(m_requisicao->fornecedor()->nomeProduto());
	ui->outProduto->setEnabled(false);
	ui->errQuantidade->clear();
	ui->errPrevisao->clear();
	ui->pbConfirmar->setEnabled(false);
	ui->inPrevisao->setMinimumDate(QDate::currentDate().addDays(-1));
	ui->inPrevisao->setDate(ui->inPrevisao->minimumDate());
}
