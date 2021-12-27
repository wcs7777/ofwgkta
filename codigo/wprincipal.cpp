#include "wprincipal.h"
#include "ui_wprincipal.h"
#include "conectarbancodados.h"
#include "westoque.h"
#include "wfornecedor.h"
#include "wrelatorio.h"
#include "wvenda.h"

WPrincipal::WPrincipal(QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WPrincipal)
{
	ui->setupUi(this);
	conectarBancoDados();
	estoque();
}

WPrincipal::~WPrincipal()
{
	delete ui;
}

void WPrincipal::estoque()
{
	ui->menu->addWidget(new WEstoque(ui->menu, this));
}

void WPrincipal::venda()
{
	ui->menu->addWidget(new WVenda(this));
}

void WPrincipal::fornecedor()
{
	ui->menu->addWidget(new WFornecedor(ui->menu, this));
}

void WPrincipal::relatorio()
{
	ui->menu->addWidget(new WRelatorio(ui->menu, this));
}

void WPrincipal::limparMenu()
{
	while (ui->menu->count() > 0)
	{
		QWidget *w = ui->menu->widget(0);
		ui->menu->removeWidget(w);
		w->deleteLater();
	}
}
