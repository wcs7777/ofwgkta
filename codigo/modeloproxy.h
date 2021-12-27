#ifndef MODELOPROXY_H
#define MODELOPROXY_H

#include <QSortFilterProxyModel>
#include "modelocustomizavel.h"

class ModeloProxy : public QSortFilterProxyModel
{
public:
	ModeloProxy(ModeloCustomizavel *model, QObject *parent);
	ModeloProxy(
		ModeloCustomizavel *modelo,
		int colunaFiltrada,
		QObject *parent
	);
	ModeloCustomizavel* source() const { return m_modelo; }
	QVariant valor(const QModelIndex &index) const;
	QVariant valor(int linha, int coluna) const;

private:
	ModeloCustomizavel *m_modelo;
};

#endif // MODELOPROXY_H
