#include "wfornecedornovo.h"
#include "ui_wfornecedornovo.h"
#include "completer.h"
#include "conectarbancodados.h"
#include "produto.h"
#include <QSqlQuery>

WFornecedorNovo::WFornecedorNovo(
	const QHash<QString, int> &produtos,
	QStackedWidget *menu,
	QWidget *parent
) :
	QWidget(parent),
	ui(new Ui::WFornecedorNovo),
	m_menu(menu),
	m_produtos(produtos),
	m_fornecedor(new Fornecedor(m_produtos))
{
	ui->setupUi(this);
	ui->inProduto->setCompleter(
		new Completer(Produto::nomeProdutos(), ui->inProduto)
	);
	connectionsAdicionar();
	uiInicial();
}

WFornecedorNovo::WFornecedorNovo(
	Fornecedor *fornecedor,
	QStackedWidget *menu,
	QWidget *parent
) :
	QWidget(parent),
	ui(new Ui::WFornecedorNovo),
	m_menu(menu),
	m_fornecedor(fornecedor)
{
	ui->setupUi(this);
	ui->inProduto->setCompleter(
		new Completer(Produto::nomeProdutos(), ui->inProduto)
	);
	connectionsEditar();
	uiInicial(
		m_fornecedor->nome(),
		m_fornecedor->contato(),
		m_fornecedor->nomeProduto()
	);
}

WFornecedorNovo::~WFornecedorNovo()
{
	delete m_fornecedor;
	delete ui;
}

void WFornecedorNovo::adicionar()
{
	QSqlQuery(
		QString("CALL AdicionarFornecedor('%1', '%2', %3)")
			.arg(m_fornecedor->nome())
			.arg(m_fornecedor->contato())
			.arg(m_fornecedor->idProduto()),
		conectarBancoDados()
	);delete m_fornecedor;
	m_fornecedor = new Fornecedor(m_produtos);
	connect(
		m_fornecedor,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
}

void WFornecedorNovo::editar()
{
	QSqlQuery(
		QString("CALL EditarFornecedor(%1, '%2', '%3', %4)")
			.arg(m_fornecedor->id())
			.arg(m_fornecedor->nome())
			.arg(m_fornecedor->contato())
			.arg(m_fornecedor->idProduto()),
		conectarBancoDados()
	);
}

void WFornecedorNovo::voltar()
{
	m_menu->removeWidget(this);
	deleteLater();
}

void WFornecedorNovo::limparEntradas()
{
	ui->inFornecedor->clear();
	ui->inContato->clear();
	ui->inProduto->clear();
	uiInicial();
	ui->inFornecedor->setFocus();
}

void WFornecedorNovo::checarNome()
{
	QString nome = ui->inFornecedor->text();

	if (nome != m_fornecedor->nome())
	{
		if (m_fornecedor->nomeValido(nome))
		{
			ui->errFornecedor->clear();
			ui->inFornecedor->nextInFocusChain()->setFocus();
		}
		else
			ui->errFornecedor->setText(m_fornecedor->ultimoErro());
	}
}

void WFornecedorNovo::checarContato()
{
	QString contato = ui->inContato->text();

	if (contato != m_fornecedor->contato())
	{
		if (m_fornecedor->contatoValido(contato))
		{
			ui->errContato->clear();
			ui->inContato->nextInFocusChain()->setFocus();
		}
		else
			ui->errContato->setText(m_fornecedor->ultimoErro());
	}
}

void WFornecedorNovo::checarProduto(QString produto)
{
	if (!produto.isEmpty())
		ui->inProduto->setText(produto);
	else
		produto = ui->inProduto->text();

	if (produto != m_fornecedor->nomeProduto())
	{
		if (m_fornecedor->produtoValido(produto))
		{
			ui->errProduto->clear();
			ui->inProduto->nextInFocusChain()->setFocus();
		}
		else
			ui->errProduto->setText(m_fornecedor->ultimoErro());
	}
}

void WFornecedorNovo::uiInicial()
{
	ui->errFornecedor->clear();
	ui->errContato->clear();
	ui->errProduto->clear();
	ui->pbConfirmar->setEnabled(false);
}

void WFornecedorNovo::uiInicial(
	const QString &fornecedor,
	const QString &contato,
	const QString &produto
)
{
	uiInicial();
	ui->pbConfirmar->setEnabled(true);
	ui->inFornecedor->setText(fornecedor);
	ui->inContato->setText(contato);
	ui->inProduto->setText(produto);
	ui->outTitulo->setText("Editar Fornecedor");
}

void WFornecedorNovo::connectionsAdicionar()
{
	connect(
		m_fornecedor,
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
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(adicionar()));
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(limparEntradas()));
	connect(ui->pbCancelar, SIGNAL(clicked()), this, SLOT(limparEntradas()));
}

void WFornecedorNovo::connectionsEditar()
{
	connect(
		m_fornecedor,
		SIGNAL(validar(bool)),
		ui->pbConfirmar,
		SLOT(setEnabled(bool))
	);
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(editar()));
	connect(ui->pbConfirmar, SIGNAL(clicked()), this, SLOT(voltar()));
	connect(ui->pbCancelar, SIGNAL(clicked()), this, SLOT(voltar()));
}
