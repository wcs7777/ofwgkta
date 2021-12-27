#ifndef WVENDA_H
#define WVENDA_H

#include <QWidget>
#include <QButtonGroup>
#include <QList>
#include <QSqlRecord>
#include "itempedido.h"

namespace Ui {
class WVenda;
}

class WVenda : public QWidget
{
	Q_OBJECT

public:
	explicit WVenda(QWidget *parent = nullptr);
	~WVenda();

private slots:
	void adicionarItem();
	void removerItem(int row, bool checar = true);
	void finalizar();
	void esvaziar();

private:
	void atualizarUltimo();
	void atualizarTotal();
	void tamanhoColunasTabela();

	Ui::WVenda *ui;
	QButtonGroup *buttonGroup;
	QList<QSqlRecord> registros;
	QList<ItemPedido*> pedido;
};

#endif // WVENDA_H
