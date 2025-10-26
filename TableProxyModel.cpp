#include "TableProxyModel.h"
#include <QDebug>

TableProxyModel::TableProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_sortRole("name")
{
    setDynamicSortFilter(true);
}

void TableProxyModel::sortByRole(const QString &roleName, Qt::SortOrder order)
{
    if (m_sortRole != roleName) {
        m_sortRole = roleName;
        emit sortRoleChanged();
    }

    QSortFilterProxyModel::sort(0, order);
}

void TableProxyModel::toggleSort(const QString &roleName)
{
    if (m_sortRole == roleName) {
        // Se já está a ordenar por esta coluna, alterna a ordem
        Qt::SortOrder newOrder = (sortOrder() == Qt::AscendingOrder) ?
                                     Qt::DescendingOrder : Qt::AscendingOrder;
        sortByRole(roleName, newOrder);
    } else {
        // Nova coluna, ordena ascendente por padrão
        sortByRole(roleName, Qt::AscendingOrder);
    }
}

void TableProxyModel::setFilterText(const QString &text)
{
    if (m_filterText != text) {
        m_filterText = text;
        emit filterTextChanged();
        invalidateFilter();
    }
}

void TableProxyModel::clearFilters()
{
    setFilterText("");
}

void TableProxyModel::removeRow(int row)
{
    if (row >= 0 && row < rowCount()) {
        // Mapear para o source model e remover lá
        QModelIndex proxyIndex = index(row, 0);
        QModelIndex sourceIndex = mapToSource(proxyIndex);

        if (sourceIndex.isValid()) {
            sourceModel()->removeRows(sourceIndex.row(), 1);
        }
    }
}

void TableProxyModel::moveRow(int from, int to)
{
    if (from >= 0 && from < rowCount() && to >= 0 && to < rowCount() && from != to) {
        // Para mover linhas, o source model precisa implementar moveRows()
        // Por enquanto apenas log
        qDebug() << "Move row from" << from << "to" << to;

        // Se o teu source model suportar moveRows, podes usar:
        // beginMoveRows(QModelIndex(), from, from, QModelIndex(), to > from ? to + 1 : to);
        // ... lógica de move ...
        // endMoveRows();
    }
}

QString TableProxyModel::sortRole() const
{
    return m_sortRole;
}

void TableProxyModel::setSortRole(const QString &role)
{
    if (m_sortRole != role) {
        m_sortRole = role;
        emit sortRoleChanged();
        invalidate();
    }
}

QString TableProxyModel::filterText() const
{
    return m_filterText;
}

bool TableProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    if (m_filterText.isEmpty()) {
        return true;
    }

    QAbstractItemModel *source = sourceModel();
    if (!source) return true;

    // Verificar todas as colunas para o filtro
    for (int col = 0; col < source->columnCount(); ++col) {
        QModelIndex index = source->index(sourceRow, col, sourceParent);
        QString data = source->data(index).toString();
        if (data.contains(m_filterText, Qt::CaseInsensitive)) {
            return true;
        }
    }

    return false;
}

bool TableProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    if (m_sortRole.isEmpty()) {
        return QSortFilterProxyModel::lessThan(left, right);
    }

    QHash<int, QByteArray> roles = roleNames();
    int role = roles.key(m_sortRole.toUtf8(), -1);
    if (role == -1) {
        return QSortFilterProxyModel::lessThan(left, right);
    }

    QVariant leftData = sourceModel()->data(left, role);
    QVariant rightData = sourceModel()->data(right, role);

    if (!leftData.isValid() || !rightData.isValid()) {
        return QSortFilterProxyModel::lessThan(left, right);
    }

    // Comparação baseada no tipo de dados
    switch (leftData.typeId()) {
    case QMetaType::Int:
        return leftData.toInt() < rightData.toInt();
    case QMetaType::Double:
        return leftData.toDouble() < rightData.toDouble();
    case QMetaType::Bool:
        return leftData.toBool() < rightData.toBool();
    default:
        return leftData.toString().compare(rightData.toString(), Qt::CaseInsensitive) < 0;
    }
}
