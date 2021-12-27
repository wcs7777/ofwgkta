#ifndef WPRINCIPAL_H
#define WPRINCIPAL_H

#include <QWidget>

namespace Ui {
class WPrincipal;
}

class WPrincipal : public QWidget
{
	Q_OBJECT

public:
	explicit WPrincipal(QWidget *parent = nullptr);
	~WPrincipal();

private slots:
	void estoque();
	void venda();
	void fornecedor();
	void relatorio();
	void limparMenu();

private:
	Ui::WPrincipal *ui;
};

#endif // WPRINCIPAL_H
