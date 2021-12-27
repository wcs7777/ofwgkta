#ifndef VALIDACAO_H
#define VALIDACAO_H

#include <QObject>
#include <QHash>

class Validacao : public QObject
{
	Q_OBJECT
public:
	Validacao(int totalCampos, QObject *parent = nullptr);
	const QString& ultimoErro() const { return err; }

signals:
	void validar(bool);

protected:
	void atualizar(int campo, bool estado);

	QString err;

private:
	QHash<int, bool> campoEstado;
	int  m_camposValidos;
	const int m_totalCampos;
};

#endif // VALIDACAO_H
