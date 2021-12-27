#include "minusculosemacento.h"

QString minusculoSemAcento(const QString &str)
{
	QString res = str.normalized(QString::NormalizationForm_D);
	int tamanho = res.size();
	for (int i = 0; i < tamanho; i++) if (res[i].isMark()) res.remove(i, 1);

	return res.toLower().trimmed();
}
