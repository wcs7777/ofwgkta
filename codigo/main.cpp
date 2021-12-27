#include "folhaestilo.h"
#include "wprincipal.h"
#include <QApplication>
#include <QMessageBox>
#include <stdexcept>

int main(int argc, char *argv[])
{
	QApplication app(argc, argv);
	app.setStyleSheet(folhaEstilo());

	try
	{
		WPrincipal w;
		w.show();

		return app.exec();
	}
	catch (std::runtime_error &e)
	{
		QMessageBox::information(nullptr, "", e.what());
	}
	catch (...)
	{
		QMessageBox::information(nullptr, "", "Erro!");
	}

	return 1;
}
