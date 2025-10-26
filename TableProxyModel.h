#ifndef TABLEPROXYMODEL_H
#define TABLEPROXYMODEL_H

#include <QSortFilterProxyModel>
#include <QObject>

class TableProxyModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString sortRole READ sortRole WRITE setSortRole NOTIFY sortRoleChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)

public:
    explicit TableProxyModel(QObject *parent = nullptr);

    // Sorting
    Q_INVOKABLE void sortByRole(const QString &roleName, Qt::SortOrder order = Qt::AscendingOrder);
    Q_INVOKABLE void toggleSort(const QString &roleName);

    // Filtering
    Q_INVOKABLE void setFilterText(const QString &text);
    Q_INVOKABLE void clearFilters();

    // Item management
    Q_INVOKABLE void removeRow(int row);
    Q_INVOKABLE void moveRow(int from, int to);

    // Getters e Setters
    QString sortRole() const;
    void setSortRole(const QString &role);

    QString filterText() const;

signals:
    void sortRoleChanged();
    void filterTextChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    QString m_sortRole;
    QString m_filterText;
};

#endif // TABLEPROXYMODEL_H
