#include "westoquenovo.h"
#include "ui_westoquenovo.h"
#include "conectarbancodados.h"
#include <QSqlQuery>

WEstoqueNovo::WEstoqueNovo(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WEstoqueNovo),
	m_produto(new Produto),
	m_menu(menu)
{
	ui->setupUi(this);
	uiInicial();
	connectionsAdicionar();
}

WEstoqueNovo::WEstoqueNovo(
	Produto *produto,
	QStackedWidget *menu,
	QWidget *parent
) :
	QWidget(parent),
	ui(new Ui::WEstoqueNovo),
	m_produto(produto),
	m_menu(menu)
{
	ui->setupUi(this);
	uiInicial(m_produto->nome(), m_produto->preco());
	connectionsEditar();
}

WEstoqueNovo::~WEstoqueNovo()
{
	delete m_produto;
	delete ui;
}


void WEstoqueNovo::adicionar()
{
	QSqlQuery(
		QString("CALL AdicionarProduto('%1', %2)")
			.arg(m_produto->nome())
			.arg(m_produto->preco()),
		conectarBancoDados()
	);
	delete m_produto;
	m_produto = new Produto();
	connect(
		m_produto,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
}

void WEstoqueNovo::editar()
{
	QSqlQuery(
		QString("CALL EditarProduto(%1, '%2', %3)")
			.arg(m_produto->id())
			.arg(m_produto->nome())
			.arg(m_produto->preco()),
		conectarBancoDados()
	);
}

void WEstoqueNovo::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WEstoqueNovo::limparEntradas()
{
	ui->inProduto->clear();
	ui->inPreco->setValue(0.0);
	uiInicial();
	ui->inProduto->setFocus();
}

void WEstoqueNovo::checarNome()
{
	QString nome = ui->inProduto->text();

	if (nome != m_produto->nome())
	{
		if (m_produto->nomeValido(nome))
		{
			ui->errProduto->clear();
			ui->inProduto->nextInFocusChain()->setFocus();
		}
		else
			ui->errProduto->setText(m_produto->ultimoErro());
	}
}

void WEstoqueNovo::checarPreco()
{
	double preco = ui->inPreco->value();

	if (preco != m_produto->preco())
	{
		if (m_produto->precoValido(preco))
		{
			ui->errPreco->clear();
			ui->inPreco->nextInFocusChain()->setFocus();
		}
		else
			ui->errPreco->setText(m_produto->ultimoErro());
	}
}

void WEstoqueNovo::uiInicial()
{
	ui->errProduto->clear();
	ui->errPreco->clear();
	ui->pbConfirmar->setEnabled(false);
}

void WEstoqueNovo::uiInicial(const QString &nome, double preco)
{
	uiInicial();
	ui->inProduto->setText(nome);
	ui->inPreco->setValue(preco);
	ui->pbConfirmar->setEnabled(true);
	ui->outTitulo->setText("Editar Produto");
}

void WEstoqueNovo::connectionsAdicionar()
{
	connect(
		m_produto,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(adicionar()));
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(limparEntradas()));
	connect(ui->pbCancelar, SIGNAL(clicked()), this, SLOT(limparEntradas()));
}

void WEstoqueNovo::connectionsEditar()
{
	connect(
		m_produto,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(editar()));
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(voltar()));
	connect(ui->pbCancelar, SIGNAL(clicked()), this, SLOT(voltar()));
}
