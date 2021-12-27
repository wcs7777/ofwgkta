#include "wrequisicaoentrada.h"
#include "ui_wrequisicaoentrada.h"
#include "completer.h"
#include "conectarbancodados.h"
#include "produto.h"
#include <QSqlQuery>

WRequisicaoEntrada::WRequisicaoEntrada(
	const QHash<QString, int> &produtos,
	QStackedWidget *menu,
	QWidget *parent
) :
	QWidget(parent),
	ui(new Ui::WRequisicaoEntrada),
	m_produtos(produtos),
	m_lote(new Lote(m_produtos)),
	m_menu(menu)
{
	ui->setupUi(this);
	ui->inProduto->setCompleter(
		new Completer(Produto::nomeProdutos(), ui->inProduto)
	);
	ui->inValidade->setMinimumDate(QDate::currentDate());
	uiInicial();
	connectionsAvulso();
}

WRequisicaoEntrada::WRequisicaoEntrada(
	Lote *lote,
	QStackedWidget *menu,
	QWidget *parent
) :
	QWidget(parent),
	ui(new Ui::WRequisicaoEntrada),
	m_lote(lote),
	m_menu(menu)
{
	ui->setupUi(this);
	uiInicial(m_lote->nomeProduto(), m_lote->quantidade());
	connectionsRequisicao();
}

WRequisicaoEntrada::~WRequisicaoEntrada()
{
	delete m_lote;
	delete ui;
}

void WRequisicaoEntrada::adicionarLote()
{
	QSqlQuery(
		QString("CALL AdicionarLote(%1, %2, '%3')")
			.arg(m_lote->idProduto())
			.arg(m_lote->quantidade())
			.arg(m_lote->validade().toString("yyyy-M-d")),
		conectarBancoDados()
	);
}

void WRequisicaoEntrada::requisicao()
{
	QSqlQuery(
		QString("CALL ReceberRequisicao(%1)").arg(m_lote->requisicao()),
		conectarBancoDados()
	);
}

void WRequisicaoEntrada::avulso()
{
	delete m_lote;
	m_lote = new Lote(m_produtos);
	connect(
		m_lote,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
}

void WRequisicaoEntrada::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WRequisicaoEntrada::limparEntradas()
{
	ui->inProduto->clear();
	ui->inQuantidade->setValue(0);
	ui->inValidade->setMinimumDate(QDate::currentDate());
	ui->inValidade->setDate(ui->inValidade->minimumDate());
	uiInicial();
	ui->inProduto->setFocus();
}

void WRequisicaoEntrada::checarProduto(QString produto)
{
	if (!produto.isEmpty())
		ui->inProduto->setText(produto);
	else
		produto = ui->inProduto->text();

	if (produto != m_lote->nomeProduto())
	{
		if (m_lote->produtoValido(produto))
		{
			ui->errProduto->clear();
			ui->inProduto->nextInFocusChain()->setFocus();
		}
		else
			ui->errProduto->setText(m_lote->ultimoErro());
	}
}

void WRequisicaoEntrada::checarQuantidade()
{
	int quantidade = ui->inQuantidade->value();

	if (quantidade != m_lote->quantidade())
	{
		if (m_lote->quantidadeValida(quantidade))
		{
			ui->errQuantidade->clear();
			ui->inQuantidade->nextInFocusChain()->setFocus();
		}
		else
			ui->errQuantidade->setText(m_lote->ultimoErro());
	}
}

void WRequisicaoEntrada::checarValidade()
{
	QDate validade = ui->inValidade->date();

	if (validade != m_lote->validade())
	{
		if (m_lote->validadeValida(validade))
		{
			ui->errValidade->clear();
			ui->inValidade->nextInFocusChain()->setFocus();
		}
		else
			ui->errValidade->setText(m_lote->ultimoErro());
	}
}

void WRequisicaoEntrada::uiInicial()
{
	ui->errProduto->clear();
	ui->errQuantidade->clear();
	ui->errValidade->clear();
	ui->pbConfirmar->setEnabled(false);
	ui->inValidade->setMinimumDate(QDate::currentDate());
	ui->inValidade->setDate(ui->inValidade->minimumDate());
}

void WRequisicaoEntrada::uiInicial(const QString &produto, int quantidade)
{
	uiInicial();
	ui->inProduto->setText(produto);
	ui->inQuantidade->setValue(quantidade);
	ui->inProduto->setEnabled(false);
	ui->inQuantidade->setEnabled(false);
}

void WRequisicaoEntrada::connectionsRequisicao()
{
	connect(
		m_lote,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(requisicao()));
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(voltar()));
	connect(ui->pbCancelar, SIGNAL(clicked()), this, SLOT(voltar()));
}

void WRequisicaoEntrada::connectionsAvulso()
{
	connect(
		m_lote,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
	connect(
		ui->inProduto->completer(),
		SIGNAL(activated(QString)),
		this,
		SLOT(checarProduto(QString))
	);
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(avulso()));
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(limparEntradas()));
	connect(ui->pbCancelar, SIGNAL(clicked()), this, SLOT(limparEntradas()));
}
