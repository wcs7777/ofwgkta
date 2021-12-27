#include "wrelatorio.h"
#include "ui_wrelatorio.h"
#include "westoqueabc.h"
#include "wstatusquantidade.h"
#include "wstatusvalidade.h"
#include "wvendaabc.h"

WRelatorio::WRelatorio(QStackedWidget *menu, QWidget *parent) :
	QWidget(parent),
	ui(new Ui::WRelatorio),
	m_menu(menu)
{
	ui->setupUi(this);
}

WRelatorio::~WRelatorio()
{
	delete ui;
}

void WRelatorio::statusQuantidade()
{
	m_menu->addWidget(new WStatusQuantidade(m_menu, this));
}

void WRelatorio::statusValidade()
{
	m_menu->addWidget(new WStatusValidade(m_menu, this));
}

void WRelatorio::estoqueAbc()
{
	m_menu->addWidget(new WEstoqueAbc(m_menu, this));
}

void WRelatorio::vendaAbc()
{
	m_menu->addWidget(new WVendaAbc(m_menu, this));
}

void WRelatorio::proximaTela()
{
	m_menu->setCurrentIndex(m_menu->currentIndex() + 1);
}
