#include "completer.h"
#include <QAbstractItemView>

Completer::Completer(const QStringList &palavras, QLineEdit *lineEdit) :
	QCompleter(palavras, lineEdit)
{
	setCompletionMode(QCompleter::UnfilteredPopupCompletion);
	setCaseSensitivity(Qt::CaseInsensitive);
	setModelSorting(QCompleter::CaseInsensitivelySortedModel);
	popup()->setStyleSheet(
		"background-color: #0D0D0B;"
		"border: none;"
		"color: #FFFAFA;"
		"font-family: \"Lato\";"
		"font-size: 12pt;"
		"selection-background-color: #FFFAFA;"
		"selection-color: #131411;"
	);
}
