#ifndef MODELOCUSTOMIZAVEL_H
#define MODELOCUSTOMIZAVEL_H

#include <QAbstractTableModel>
#include <QHash>
#include <QList>
#include <QPair>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QVariant>

typedef QPair<int, QHash<QString, QVariant>> CampoCondicaoCor;

class ModeloCustomizavel : public QAbstractTableModel
{
public:
	ModeloCustomizavel(
		const QSqlQuery &query,
		QObject *parent = nullptr,
		const QList<QVariant> &alinhamentos = QList<QVariant>(),
		const CampoCondicaoCor &cores = CampoCondicaoCor(
			-1, QHash<QString, QVariant>()
		)
	);
	QVariant data(
		const QModelIndex &index,
		int role = Qt::DisplayRole
	) const override;
	QVariant headerData(
		int section,
		Qt::Orientation orientation,
		int role = Qt::DisplayRole
	) const override;
	int rowCount(const QModelIndex& = QModelIndex()) const override;
	int columnCount(const QModelIndex& = QModelIndex()) const override;
	QVariant valor(const QModelIndex &index) const;
	QVariant valor(int row, int column) const;
	void atualizar();
	int indiceCampo(const QString &campo) const;

private:
	void popular();

	QSqlQuery m_query;
	QList<QVariant> m_alinhamentos;
	CampoCondicaoCor m_cores;
	QList<QSqlRecord> registros;
};

#endif // MODELOCUSTOMIZAVEL_H
