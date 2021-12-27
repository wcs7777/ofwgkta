#include "conectarbancodados.h"
#include <QSqlError>
#include <stdexcept>

QSqlDatabase& conectarBancoDados()
{
	static QSqlDatabase db = QSqlDatabase::addDatabase("QMYSQL");

	if (!db.isOpen())
	{
		db.setHostName("localhost");
		db.setUserName("usuario_ofwgkta");
		db.setPassword("oddfuture");
		db.setDatabaseName("ofwgkta");

		if (!db.open())
			throw std::runtime_error(db.lastError().text().toStdString());
	}

	return db;
}
