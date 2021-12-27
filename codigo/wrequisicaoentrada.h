#ifndef WREQUISICAOENTRADA_H
#define WREQUISICAOENTRADA_H

#include <QWidget>
#include <QHash>
#include <QStackedWidget>
#include "lote.h"

namespace Ui {
class WRequisicaoEntrada;
}

class WRequisicaoEntrada : public QWidget
{
	Q_OBJECT

public:
	WRequisicaoEntrada(
		const QHash<QString, int> &produtos,
		QStackedWidget *menu,
		QWidget *parent = nullptr
	);
	WRequisicaoEntrada(
		Lote *lote,
		QStackedWidget *menu,
		QWidget *parent = nullptr
	);
	~WRequisicaoEntrada();

private slots:
	void adicionarLote();
	void requisicao();
	void avulso();
	void voltar();
	void limparEntradas();
	void checarProduto(QString produto = QString());
	void checarQuantidade();
	void checarValidade();

private:
	void uiInicial();
	void uiInicial(const QString &produto, int quantidade);
	void connectionsRequisicao();
	void connectionsAvulso();

	Ui::WRequisicaoEntrada *ui;
	QHash<QString, int> m_produtos;
	Lote *m_lote;
	QStackedWidget *m_menu;
};

#endif // WREQUISICAOENTRADA_H
